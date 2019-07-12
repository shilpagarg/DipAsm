if [ $# != 8 ] ; then
echo "USAGE: $0 TAGBAM REF CHR OUTPATH SAMPLE snvTruth svTruthVCF svTruthBED"
exit 1;
fi

TAG=$(readlink -f $1)
REF=$(readlink -f $2)
CHR=$3
OUT=$(readlink -f $4)
SAMPLE=$5
SNV=$(readlink -f $6)
SV=$(readlink -f $7)
BED=$(readlink -f $8)
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
PREFIX=$SAMPLE'.'$CHR

echo Input tagged bam: $TAG
echo Reference sequence: $REF
echo All output will be at $OUT

mkdir $OUT
mkdir $OUT

echo Extracting reads. will be stored at $OUT/${PREFIX}.H1.fastq, $OUT/${PREFIX}.H2.fastq
samtools view -@16 -h $TAG | grep -E '^@|HP:i:1' | samtools view -Sb -@32 - | samtools fastq -@16 - > $OUT/${PREFIX}.H1.fastq
samtools view -@16 -h $TAG | grep -E '^@|HP:i:2' | samtools view -Sb -@32 - | samtools fastq -@16 - > $OUT/${PREFIX}.H2.fastq
samtools view -@16 -h $TAG | grep -v 'HP:i:' | samtools view -@16 -Sb - > $OUT/${PREFIX}.notag.bam
samtools fastq -@16 $OUT/${PREFIX}.notag.bam >> $OUT/${PREFIX}.H1.fastq &
samtools fastq -@16 $OUT/${PREFIX}.notag.bam >> $OUT/${PREFIX}.H2.fastq ; wait

mkdir $OUT/ref
minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t32 -R "@RG\tID:$SAMPLE\tSM:$SAMPLE" $REF $OUT/${PREFIX}.H1.fastq 2>> $OUT/minimap2.log | samtools sort -@32 -m2g -O BAM -o $OUT/${PREFIX}.H1.ref.bam
minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k --eqx --secondary=no -t32 -R "@RG\tID:$SAMPLE\tSM:$SAMPLE" $REF $OUT/${PREFIX}.H2.fastq 2>> $OUT/minimap2.log| samtools sort -@32 -m2g -O BAM -o $OUT/${PREFIX}.H2.ref.bam
samtools index -@16 $OUT/${PREFIX}.H1.ref.bam &
samtools index -@16 $OUT/${PREFIX}.H2.ref.bam ; wait

# Small variant calling
mkdir $OUT/dvcalls
cp $REF $OUT/ref/
samtools faidx $OUT/ref/${REF##*/}
$SCRIPTPATH/dv.H1.sh $OUT ref/${REF##*/} ${PREFIX}.H1.ref.bam $CHR 2>> $OUT/dvcalls/dv.log
$SCRIPTPATH/dv.H1.sh $OUT ref/${REF##*/} ${PREFIX}.H2.ref.bam $CHR 2>> $OUT/dvcalls/dv.log
bcftools merge --force-samples --apply-filters PASS $OUT/dvcalls/${PREFIX}.H1.ref.bam.vcf.gz $OUT/dvcalls/${PREFIX}.H2.ref.bam.vcf.gz > $OUT/dvcalls/${PREFIX}.dv.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/dvcalls/${PREFIX}.dv.merged.vcf $SAMPLE > $OUT/dvcalls/${PREFIX}.dv.phased.vcf
mkdir $OUT/dvcalls/compare
whatshap compare --only-snvs --tsv-pairwise $OUT/dvcalls/compare/compare.${CHR}.pw.tsv --longest-block-tsv $OUT/dvcalls/compare/compare.${CHR}.block.tsv $OUT/dvcalls/${PREFIX}.dv.phased.vcf $SNV > $OUT/dvcalls/compare/compare.${CHR}.log 2>&1

# Structural variant calling
samtools calmd -@32 -b $OUT/${PREFIX}.H1.ref.bam $OUT/ref/${REF##*/} > $OUT/${PREFIX}.H1.ref.calmd.bam 
samtools calmd -@32 -b $OUT/${PREFIX}.H2.ref.bam $OUT/ref/${REF##*/} > $OUT/${PREFIX}.H2.ref.calmd.bam 
mkdir $OUT/sniffles_vcf

sniffles -m $OUT/${PREFIX}.H1.ref.calmd.bam  -t 32 -v $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf --genotype -s 3 --skip_parameter_estimation -n -1 > $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.log 2>&1
sniffles -m $OUT/${PREFIX}.H2.ref.calmd.bam  -t 32 -v $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf --genotype -s 3 --skip_parameter_estimation -n -1 > $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.log 2>&1

cat <(cat $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf  | grep "^#") <(cat $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf  | grep -vE "^#" | grep 'DUP\|INS\|DEL' | sed 's/DUP/INS/g' | sort -k1,1 -k2,2g) | bgzip -c > $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz
cat <(cat $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf  | grep "^#") <(cat $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf  | grep -vE "^#" | grep 'DUP\|INS\|DEL' | sed 's/DUP/INS/g' | sort -k1,1 -k2,2g) | bgzip -c > $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz
tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz 
tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz 
bcftools merge --force-samples -m id -0 $OUT/sniffles_vcf/${PREFIX}.H1.sniffles.vcf.gz $OUT/sniffles_vcf/${PREFIX}.H2.sniffles.vcf.gz > $OUT/sniffles_vcf/${PREFIX}.sniffles.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/sniffles_vcf/${PREFIX}.sniffles.merged.vcf $SAMPLE > $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf
bgzip -c $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf > $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf.gz
tabix -p vcf $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf.gz
~/tools/truvari/truvari/truvari -f $OUT/ref/${REF##*/} -b $SV --includebed $BED -o $OUT/sniffles_vcf/truvari_${CHR} --giabreport --passonly -r 1000 -p 0.00 -P 0.1 -c $OUT/sniffles_vcf/${PREFIX}.sniffles.phased.vcf.gz
