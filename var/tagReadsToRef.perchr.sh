TAG=$(readlink -f $1)
REF=$(readlink -f $2)
CHR=$3
SAMPLE=$4
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
PREFIX=$SAMPLE'.'$CHR

OUT=${SAMPLE}_sniffles
[ -d $OUT ] || mkdir -p $OUT

samtools view -@36 -h $TAG | grep -E '^@|HP:i:1' | samtools view -Sb -@36 - | samtools fastq -@36 - > $OUT/${PREFIX}.H1.fastq
samtools view -@36 -h $TAG | grep -E '^@|HP:i:2' | samtools view -Sb -@36 - | samtools fastq -@36 - > $OUT/${PREFIX}.H2.fastq
samtools view -@36 -h $TAG | grep -v 'HP:i:' | samtools view -@36 -Sb - > $OUT/${PREFIX}.notag.bam
samtools fastq -@72 $OUT/${PREFIX}.notag.bam >> $OUT/${PREFIX}.H1.fastq &
samtools fastq -@72 $OUT/${PREFIX}.notag.bam >> $OUT/${PREFIX}.H2.fastq ; wait

minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t72 -R "@RG\tID:$SAMPLE\tSM:$SAMPLE" $REF $OUT/${PREFIX}.H1.fastq 2>> $OUT/minimap2.log | samtools sort -@72 -m2g -O BAM -o $OUT/${PREFIX}.H1.ref.bam
minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t72 -R "@RG\tID:$SAMPLE\tSM:$SAMPLE" $REF $OUT/${PREFIX}.H2.fastq 2>> $OUT/minimap2.log | samtools sort -@72 -m2g -O BAM -o $OUT/${PREFIX}.H2.ref.bam
samtools index -@72 $OUT/${PREFIX}.H1.ref.bam &
samtools index -@72 $OUT/${PREFIX}.H2.ref.bam ; wait

samtools calmd -@72 -b $OUT/${PREFIX}.H1.ref.bam $REF > $OUT/${PREFIX}.H1.ref.calmd.bam
samtools calmd -@72 -b $OUT/${PREFIX}.H2.ref.bam $REF > $OUT/${PREFIX}.H2.ref.calmd.bam

[ -d $OUT/sniffles_vcf ] || mkdir -p $OUT/sniffles_vcf

sniffles -m $OUT/${PREFIX}.H1.ref.calmd.bam  -t 72 -v $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf --genotype -s 3 --skip_parameter_estimation -n -1 > $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.log 2>&1
sniffles -m $OUT/${PREFIX}.H2.ref.calmd.bam  -t 72 -v $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf --genotype -s 3 --skip_parameter_estimation -n -1 > $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.log 2>&1

cat <(cat $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf  | grep "^#") <(cat $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf  | grep -vE "^#" | grep 'DUP\|INS\|DEL' | sed 's/DUP/INS/g' | sort -k1,1 -k2,2g) | bgzip -c > $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz
cat <(cat $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf  | grep "^#") <(cat $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf  | grep -vE "^#" | grep 'DUP\|INS\|DEL' | sed 's/DUP/INS/g' | sort -k1,1 -k2,2g) | bgzip -c > $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz

tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz
tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz

bcftools merge --force-samples -m none -0 $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz > $OUT/sniffles_vcf/${PREFIX}.sniffles.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/sniffles_vcf/${PREFIX}.sniffles.merged.vcf $SAMPLE > $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf
bgzip -c $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf > $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf.gz
tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf.gz

