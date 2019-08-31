H1=$(readlink -f $1)
H2=$(readlink -f $2)
REF=$(readlink -f $3)
SAMPLE=$4
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

OUT=${SAMPLE}_dipcall
[ -d $OUT ] || mkdir -p $OUT

echo Starting to run dipcall analysis for dipasm

minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $H1 > $OUT/H1.sam
minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $H2 > $OUT/H2.sam

$SCRIPTPATH/sam-flt.js $OUT/H1.sam | samtools sort -m4G -@4 -O BAM -o $OUT/H1.flt.sort.bam -
$SCRIPTPATH/sam-flt.js $OUT/H2.sam | samtools sort -m4G -@4 -O BAM -o $OUT/H2.flt.sort.bam -

htsbox pileup -q5 -evcf $REF $OUT/H1.flt.sort.bam | htsbox bgzip > $OUT/H1.vcf.gz
htsbox pileup -q5 -evcf $REF $OUT/H2.flt.sort.bam | htsbox bgzip > $OUT/H2.vcf.gz

tabix -p vcf $OUT/H1.vcf.gz
tabix -p vcf $OUT/H2.vcf.gz

bcftools merge --force-samples -m none $OUT/H1.vcf.gz $OUT/H2.vcf.gz > $OUT/merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/merged.vcf $SAMPLE > $OUT/phased.vcf

echo DONE! Final dipcall variants are in $OUT/phased.vcf
