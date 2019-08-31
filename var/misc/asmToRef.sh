DIPASM=$(readlink -f $1)
REF=$(readlink -f $2)
SAMPLE=$3
CHR=$4
OUT=${SAMPLE}_output
SNVGT=$5
SVGT=$6
SVBED=$7
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

export OUT
export DIPASM

[ -d $OUT ] || mkdir -p $OUT
t=$'\t'
minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $DIPASM/${CHR}-p_ctg_cns-H1.fa > $OUT/${CHR}.H1.sam
minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $DIPASM/${CHR}-p_ctg_cns-H2.fa > $OUT/${CHR}.H2.sam

$SCRIPTPATH/sam-flt.js $OUT/${CHR}.H1.sam | samtools sort -m4G -@4 -O BAM -o $OUT/${CHR}.H1.flt.sort.bam - 
$SCRIPTPATH/sam-flt.js $OUT/${CHR}.H2.sam | samtools sort -m4G -@4 -O BAM -o $OUT/${CHR}.H2.flt.sort.bam - 

htsbox pileup -q5 -evcf $REF $OUT/${CHR}.H1.flt.sort.bam | htsbox bgzip > $OUT/${CHR}.H1.vcf.gz
htsbox pileup -q5 -evcf $REF $OUT/${CHR}.H2.flt.sort.bam | htsbox bgzip > $OUT/${CHR}.H2.vcf.gz
tabix -p vcf $OUT/${CHR}.H1.vcf.gz
tabix -p vcf $OUT/${CHR}.H2.vcf.gz
bcftools merge --force-samples -m none $OUT/${CHR}.H1.vcf.gz $OUT/${CHR}.H2.vcf.gz > $OUT/${CHR}.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/${CHR}.merged.vcf $SAMPLE > $OUT/${CHR}.phased.vcf
mkdir [ -d $OUT/compare ] || mkdir -p $OUT/compare
whatshap compare --tsv-pairwise $OUT/compare/compare.${CHR}.pw.tsv --longest-block-tsv $OUT/compare/compare.${CHR}.block.tsv --only-snvs $OUT/${CHR}.phased.vcf $SNVGT > $OUT/compare/compare.${CHR}.log 2>&1

python $SCRIPTPATH/svVCF.py $OUT/${CHR}.phased.vcf > $OUT/${CHR}.phased.sv.vcf
bgzip -c $OUT/${CHR}.phased.sv.vcf > $OUT/${CHR}.phased.sv.vcf.gz
tabix -p vcf $OUT/${CHR}.phased.sv.vcf.gz
~/tools/truvari/truvari/truvari -f $REF -b $SVGT --includebed $SVBED -o $OUT/truvari_${CHR} --giabreport --passonly -r 1000 -p 0.00 -c $OUT/${CHR}.phased.sv.vcf.gz
