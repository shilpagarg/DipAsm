HIC=alignment/hic/split
VCF=alignment/pacbioccs/vcf
SAMPLE=$1
SCAFFOLDS=`cut -d$'\t' -f1 ragoo/ragoo_output/ragoo.fasta.fai`
source activate pipeline
export HIC
export VCF
export SAMPLE

echo HapCUT2 phasing

\time -v parallel 'extractHAIRS --bam $HIC/hic.ragoo.{}.bam --hic 1 --VCF $VCF/pacbioccs.ragoo.{}.filtered.vcf --out hapcut2/hic.{}.frag --maxIS 10000000 2> hapcut2/extractHAIRS.{}.log' ::: $SCAFFOLDS 2> extractHAIRS.log
\time -v parallel 'HAPCUT2 --fragments hapcut2/hic.{}.frag --VCF $VCF/pacbioccs.ragoo.{}.filtered.vcf --output hapcut2/hic.{}.hap --hic 1 2> hapcut2/HAPCUT2.{}.log' ::: $SCAFFOLDS  2> HAPCUT2.log
parallel "cut -d$'\t' -f1-11 hapcut2/hic.{}.hap > hapcut2/hic.{}.hap.cut" ::: $SCAFFOLDS 
parallel 'whatshap hapcut2vcf $VCF/pacbioccs.ragoo.{}.filtered.vcf hapcut2/hic.{}.hap.cut -o hapcut2/hic.{}.phased.vcf' ::: $SCAFFOLDS 

echo WhatsHap phasing

\time -v parallel 'whatshap phase --reference ragoo/ragoo_output/ragoo.fasta $VCF/pacbioccs.ragoo.{}.filtered.vcf hapcut2/hic.{}.phased.vcf alignment/pacbioccs/split/pacbioccs.ragoo.{}.bam -o whatshap/pacbioccs.hic.{}.whatshap.phased.vcf 2> whatshap/whatshap.{}.log' ::: $SCAFFOLDS  2> whatshap.phase.log
parallel 'bgzip -c whatshap/pacbioccs.hic.{}.whatshap.phased.vcf > whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz' ::: $SCAFFOLDS 
parallel 'tabix -p vcf whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz' ::: $SCAFFOLDS 
echo Haplotagging

\time -v parallel 'whatshap haplotag --reference ragoo/ragoo_output/ragoo.fasta whatshap/pacbioccs.hic.{}.whatshap.phased.vcf.gz alignment/pacbioccs/split/pacbioccs.ragoo.{}.bam -o haplotag/$SAMPLE.pacbioccs.hic.{}.haplotag.bam 2> haplotag/haplotag.{}.log' ::: $SCAFFOLDS  2> haplotag.log
