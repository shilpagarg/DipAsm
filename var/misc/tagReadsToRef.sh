if [ $# != 3 ] ; then
echo "USAGE: $0 HAPLOTAGPATH REF OUTPATH"
exit 1;
fi

TAG=$(readlink -f $1)
REF=$(readlink -f $2)
OUT=$(readlink -f $3)
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

export OUT
export REF
export SCRIPTPATH

mkdir $OUT

parallel "samtools view -h {} | grep -E '^@|HP:i:1' | samtools view -Sb - | samtools fastq - > $OUT/{/.}.H1.fastq" ::: $TAG/*.bam &
parallel "samtools view -h {} | grep -E '^@|HP:i:2' | samtools view -Sb - | samtools fastq - > $OUT/{/.}.H2.fastq" ::: $TAG/*.bam ; wait
parallel "samtools view -h {} | grep -v 'HP:i:' | samtools view -Sb - > $OUT/{/.}.notag.bam" ::: $TAG/*.bam

parallel 'samtools fastq -@5 $OUT/{/.}.notag.bam >> $OUT/{/.}.H1.fastq' ::: $TAG/*.bam &
parallel 'samtools fastq -@5 $OUT/{/.}.notag.bam >> $OUT/{/.}.H2.fastq' ::: $TAG/*.bam

mkdir $OUT/ref
parallel 'samtools faidx $REF chr{} > $OUT/ref/chr{}.fasta' ::: {1..22}
parallel -j16 "minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t2 -R '@RG\tID:hg002\tSM:hg002' $OUT/ref/chr{}.fasta $OUT/hg002.pacbioccs.chr{}_RaGOO.tagged.H1.fastq | samtools sort -@2 -m2g -O BAM -o $OUT/hg002.pacbioccs.chr{}_RaGOO.tagged.H1.ref.bam" ::: {1..22}
parallel -j16 "minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t2 -R '@RG\tID:hg002\tSM:hg002' $OUT/ref/chr{}.fasta $OUT/hg002.pacbioccs.chr{}_RaGOO.tagged.H2.fastq | samtools sort -@2 -m2g -O BAM -o $OUT/hg002.pacbioccs.chr{}_RaGOO.tagged.H2.ref.bam" ::: {1..22}

#ls $OUT/hg002.pacbioccs.chr*_RaGOO.tagged.H2.ref.bam | parallel 'java -jar ~/tools/picard.jar AddOrReplaceReadGroups I={} O={.}.RG.bam LB=unknown PL=pacbio PU=unknown SM=na12878'
#ls $OUT/pacbioccs.ragoo.chr*_RaGOO.haplotag.H1.ref.bam | parallel 'java -jar ~/tools/picard.jar AddOrReplaceReadGroups I={} O={.}.RG.bam LB=unknown PL=pacbio PU=unknown SM=na12878'
ls $OUT/*ref.bam | parallel 'samtools index {}'

cd $OUT
mkdir dv_calls
cd ../

parallel -j2 '$SCRIPTPATH/dv.H1.sh $OUT ref/chr{}.fasta chr{}' ::: {1..22}
parallel -j2 '$SCRIPTPATH/dv.H2.sh $OUT ref/chr{}.fasta chr{}' ::: {1..22}
exit
parallel -j15 'samtools calmd -@2 -b $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H1.ref.bam $OUT/ref/chr{}.fasta > $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H1.ref.calmd.bam' ::: {1..22} X Y
parallel -j15 'samtools calmd -@2 -b $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H2.ref.bam $OUT/ref/chr{}.fasta > $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H2.ref.calmd.bam' ::: {1..22} X Y

parallel -j15 'sniffles -m $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H1.ref.calmd.bam -t 2 -v $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H1.sniffle.vcf --genotype --report_seq -s 3  --skip_parameter_estimation -n -1 > sniffle_chr{}_RaGOO.H1.log 2>&1' ::: {1..22} X Y
parallel -j15 'sniffles -m $OUT/pacbioccs.ragoo.chr{}_RaGOO.haplotag.H2.ref.calmd.bam -t 2 -v $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H2.sniffle.vcf --genotype --report_seq -s 3  --skip_parameter_estimation -n -1 > sniffle_chr{}_RaGOO.H2.log 2>&1' ::: {1..22} X Y

parallel 'bgzip -c $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H1.sniffle.vcf > $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H1.sniffle.vcf.gz' ::: {1..22}
parallel 'bgzip -c $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H2.sniffle.vcf > $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H2.sniffle.vcf.gz' ::: {1..22}
parallel 'tabix -p vcf $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H1.sniffle.vcf.gz' ::: {1..22}
parallel 'tabix -p vcf $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H2.sniffle.vcf.gz' ::: {1..22}
parallel "bcftools merge --force-samples $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H1.sniffle.vcf.gz $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.H2.sniffle.vcf.gz | sed 's/\.\/\./0\/0/g' > $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.sniffle.merged.vcf" ::: {1..22}
parallel 'python $SCRIPTPATH/vcf-pair.py $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.sniffle.merged.vcf > $OUT/sniffles_vcf/pacbioccs.chr{}_RaGOO.sniffle.phased.vcf' ::: {1..22}

# https://github.com/PacificBiosciences/sv-benchmark
