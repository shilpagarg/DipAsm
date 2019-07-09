# Usage: ./check.forOne.sh CHR maxIS
CHR=$1
HIC=alignment/hic/split/hic.ragoo.chr${CHR}_RaGOO.bam 
#HIC=hic.ragoo.chr${CHR}_RaGOO.RG.bam
#VCF=pacbioccs.ragoo.chr${CHR}_RaGOO.filtered.2.vcf
VCF=alignment/pacbioccs/vcf/pacbioccs.ragoo.chr${CHR}_RaGOO.filtered.vcf
REF=ragoo/ragoo.fasta
MAXIS=$2
OUT=chr${CHR}/maxIS$MAXIS
PB=alignment/pacbioccs/split/pacbioccs.ragoo.chr${CHR}_RaGOO.bam
#SCAFFOLDS=`cut -d$'\t' -f1 ragoo/ragoo_output/ragoo.fasta.fai`
#source activate pipeline
export HIC
export VCF
export SAMPLE
export REF
mkdir chr$CHR
mkdir $OUT
t=$'\t'

echo HapCUT2 phasing
\time -v extractHAIRS --bam $HIC --hic 1 --VCF $VCF --out $OUT/hic.${CHR}.frag --maxIS $MAXIS 2> $OUT/extractHAIRS.${CHR}.log
\time -v HAPCUT2 --fragments $OUT/hic.${CHR}.frag --VCF $VCF --output $OUT/hic.${CHR}.hap --hic 1 2> $OUT/HAPCUT2.${CHR}.log
cut -d$'\t' -f1-11 $OUT/hic.${CHR}.hap > $OUT/hic.${CHR}.hap.cut
whatshap hapcut2vcf $VCF $OUT/hic.${CHR}.hap.cut -o $OUT/hic.${CHR}.phased.vcf

whatshap phase --reference $REF $VCF $OUT/hic.${CHR}.phased.vcf $PB -o $OUT/hic.${CHR}.wh.phased.vcf 2> $OUT/whatshap.${CHR}.log

PS=`grep -v '^#' $OUT/hic.${CHR}.wh.phased.vcf | grep 'PS' | cut -d':' -f13 | sort | uniq -cd | sort -k1nr | head -1 | awk '{print $2}'`
grep -E "^#|$PS$" $OUT/hic.${CHR}.wh.phased.vcf > $OUT/hic.${CHR}.phased.largestBlock.vcf
bgzip -c $OUT/hic.${CHR}.phased.largestBlock.vcf > $OUT/hic.${CHR}.phased.largestBlock.vcf.gz
tabix -p vcf $OUT/hic.${CHR}.phased.largestBlock.vcf.gz
bcftools  consensus -f ragoo/chr${CHR}_RaGOO.fasta -H 1 $OUT/hic.${CHR}.phased.largestBlock.vcf.gz  > $OUT/chr${CHR}_RaGOO.H1.fasta
bcftools  consensus -f ragoo/chr${CHR}_RaGOO.fasta -H 2 $OUT/hic.${CHR}.phased.largestBlock.vcf.gz  > $OUT/chr${CHR}_RaGOO.H2.fasta
# TODO remember to change things in the -E expression
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t20 ref/${CHR}.fasta  $OUT/chr${CHR}_RaGOO.H1.fasta | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/${CHR}.fasta - | grep -E "^#|^$CHR$t" | htsbox bgzip > $OUT/chr${CHR}.H1.vcf.gz
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t20 ref/${CHR}.fasta  $OUT/chr${CHR}_RaGOO.H2.fasta | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/${CHR}.fasta - | grep -E "^#|^$CHR$t" | htsbox bgzip > $OUT/chr${CHR}.H2.vcf.gz

tabix -p vcf $OUT/chr${CHR}.H1.vcf.gz
tabix -p vcf $OUT/chr${CHR}.H2.vcf.gz

bcftools merge --force-samples $OUT/chr${CHR}.H1.vcf.gz  $OUT/chr${CHR}.H2.vcf.gz | sed 's/\.\/\./0\/0/g'>  $OUT/chr${CHR}.merged.vcf
python vcf-pair.py $OUT/chr${CHR}.merged.vcf  > $OUT/chr${CHR}.phased.vcf

whatshap compare --only-snvs $OUT/chr${CHR}.phased.vcf truth/na12878.${CHR}.phased.vcf > $OUT/compare.log 2>&1
