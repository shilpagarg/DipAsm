HIC=alignment/hic/split
VCF=alignment/pacbioccs/vcf
REF=$1
SAMPLE=$2
SCAFFOLDS=`cut -d$'\t' -f1 ${REF}.fai`
export HIC
export VCF
export SAMPLE
export REF

echo HapCUT2 phasing


\time -v parallel 'extractHAIRS --bam $HIC/hic.{}.bam --hic 1 --VCF $VCF/pacbioccs.{}.filtered.vcf --out hapcut2/hic.{}.frag --maxIS 30000000 2> hapcut2/extractHAIRS.{}.log' ::: $SCAFFOLDS 2> extractHAIRS.log
\time -v parallel 'HAPCUT2 --fragments hapcut2/hic.{}.frag --VCF $VCF/pacbioccs.{}.filtered.vcf --output hapcut2/hic.{}.hap --hic 1 2> hapcut2/HAPCUT2.{}.log' ::: $SCAFFOLDS  2> HAPCUT2.log
parallel "cut -d$'\t' -f1-11 hapcut2/hic.{}.hap > hapcut2/hic.{}.hap.cut" ::: $SCAFFOLDS
parallel 'whatshap hapcut2vcf $VCF/pacbioccs.{}.filtered.vcf hapcut2/hic.{}.hap.cut -o hapcut2/hic.{}.phased.vcf' ::: $SCAFFOLDS

echo WhatsHap phasing

\time -v parallel 'whatshap phase --reference $REF $VCF/pacbioccs.{}.filtered.vcf hapcut2/hic.{}.phased.vcf alignment/pacbioccs/split/pacbioccs.{}.bam -o whatshap/pacbioccs.hic.{}.whatshap.phased.vcf 2> whatshap/whatshap.{}.log' ::: $SCAFFOLDS  2> whatshap.phase.log

parallel 'bgzip -c whatshap/pacbioccs.hic.{}.whatshap.phased.vcf > whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz' ::: $SCAFFOLDS
parallel 'tabix -p vcf whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz' ::: $SCAFFOLDS

parallel 'whatshap haplotag --reference $REF whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz alignment/pacbioccs/split/pacbioccs.{}.bam -o haplotag/$SAMPLE.pacbioccs.hic.{}.haplotag.bam 2> haplotag/haplotag.{}.log' ::: $SCAFFOLDS  2> haplotag.log

exit
[ -d largestBlock_vcf ] || mkdir -p largestBlock_vcf
[ -d largestBlock_haplotagBAM ] || mkdir -p largestBlock_haplotagBAM

for CHR in $SCAFFOLDS; do 
  PS=`grep -v '^#' whatshap/pacbioccs.hic.${CHR}.whatshap.phased.vcf | grep 'PS' | cut -d':' -f13 | sort | uniq -cd | sort -k1nr | head -1 | awk '{print $2}'`
  grep -E "^#|$PS$" whatshap/pacbioccs.hic.${CHR}.whatshap.phased.vcf > largestBlock_vcf/pacbioccs.hic.${CHR}.phased.largestBlock.vcf
done

parallel 'bgzip -c largestBlock_vcf/pacbioccs.hic.{}.phased.largestBlock.vcf > largestBlock_vcf/pacbioccs.hic.{}.phased.largestBlock.vcf.gz' ::: $SCAFFOLDS
parallel 'tabix -p vcf largestBlock_vcf/pacbioccs.hic.{}.phased.largestBlock.vcf.gz' ::: $SCAFFOLDS
parallel 'whatshap haplotag --reference $REF largestBlock_vcf/pacbioccs.hic.{}.phased.largestBlock.vcf.gz alignment/pacbioccs/split/pacbioccs.{}.bam -o largestBlock_haplotagBAM/${SAMPLE}.pacbioccs.hic.{}.largestBlock.haplotag.bam 2> largestBlock_haplotagBAM/haplotag.{}.log' ::: $SCAFFOLDS  2> haplotag.largestBlock.log
