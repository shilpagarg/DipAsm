CHR=$1
HIC=$2
PB=$3
VCF=$4
SCAFF=$5
REF=$6
ASM=$7
MAXIS=$8
GT=$9
SAMPLE=$10
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

OUT=check/${CHR}/maxIS$MAXIS
mkdir check
mkdir check/$CHR
mkdir $OUT
t=$'\t'

echo HapCUT2 phasing
\time -v extractHAIRS --bam $HIC --hic 1 --VCF $VCF --out $OUT/hic.${CHR}.frag --maxIS $MAXIS 2> $OUT/extractHAIRS.${CHR}.log
\time -v HAPCUT2 --fragments $OUT/hic.${CHR}.frag --VCF $VCF --output $OUT/hic.${CHR}.hap --hic 1 2> $OUT/HAPCUT2.${CHR}.log
cut -d$'\t' -f1-11 $OUT/hic.${CHR}.hap > $OUT/hic.${CHR}.hap.cut
whatshap hapcut2vcf $VCF $OUT/hic.${CHR}.hap.cut -o $OUT/hic.${CHR}.phased.vcf

whatshap phase --reference $ASM $VCF $OUT/hic.${CHR}.phased.vcf $PB -o $OUT/hic.${CHR}.wh.phased.vcf 2> $OUT/whatshap.${CHR}.log

#PHASE=whatshap/pacbioccs.hic.${CHR}.whatshap.phased.vcf 
PHASE=$OUT/hic.${CHR}.wh.phased.vcf 

PS=`grep -v '^#' $PHASE | grep 'PS' | cut -d':' -f13 | sort | uniq -cd | sort -k1nr | head -1 | awk '{print $2}'`
grep -E "^#|$PS$" $PHASE > $OUT/hic.${CHR}.phased.largestBlock.vcf
bgzip -c $OUT/hic.${CHR}.phased.largestBlock.vcf > $OUT/hic.${CHR}.phased.largestBlock.vcf.gz
tabix -p vcf $OUT/hic.${CHR}.phased.largestBlock.vcf.gz
bcftools consensus -f ref/${CHR}.fasta -H 1 $OUT/hic.${CHR}.phased.largestBlock.vcf.gz  > $OUT/${CHR}.H1.fasta
bcftools consensus -f ref/${CHR}.fasta -H 2 $OUT/hic.${CHR}.phased.largestBlock.vcf.gz  > $OUT/${CHR}.H2.fasta

minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $OUT/${CHR}.H1.fasta > $OUT/${CHR}.H1.sam
minimap2 --paf-no-hit -axasm5 --cs -r2k -t32 $REF $OUT/${CHR}.H2.fasta > $OUT/${CHR}.H2.sam

$SCRIPTPATH/sam-flt.js $OUT/${CHR}.H1.sam | samtools sort -m4G -@4 -O BAM -o $OUT/${CHR}.H1.flt.sort.bam -
$SCRIPTPATH/sam-flt.js $OUT/${CHR}.H2.sam | samtools sort -m4G -@4 -O BAM -o $OUT/${CHR}.H2.flt.sort.bam -

htsbox pileup -q5 -evcf $REF $OUT/${CHR}.H1.flt.sort.bam | htsbox bgzip > $OUT/${CHR}.H1.vcf.gz
htsbox pileup -q5 -evcf $REF $OUT/${CHR}.H2.flt.sort.bam | htsbox bgzip > $OUT/${CHR}.H2.vcf.gz

tabix -p vcf $OUT/${CHR}.H1.vcf.gz
tabix -p vcf $OUT/${CHR}.H2.vcf.gz

bcftools merge --force-samples -m none $OUT/${CHR}.H1.vcf.gz $OUT/${CHR}.H2.vcf.gz > $OUT/${CHR}.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUT/${CHR}.merged.vcf $SAMPLE > $OUT/${CHR}.phased.vcf
whatshap compare --tsv-pairwise $OUT/compare.${CHR}.pw.tsv --longest-block-tsv $OUT/compare.${CHR}.block.tsv --only-snvs $OUT/${CHR}.phased.vcf $GT > $OUT/compare.${CHR}.log 2>&1
