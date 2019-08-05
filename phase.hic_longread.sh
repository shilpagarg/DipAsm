HIC=alignment/hic/split
PB=alignment/pacbioccs/split
VCF=alignment/pacbioccs/vcf
REF=$1
SAMPLE=$2
SCAFFOLDS=`cut -d$'\t' -f1 ${REF}.fai`
export HIC
export PB
export VCF
export SAMPLE
export REF
mkdir hapcut2Only/
parallel 'samtools faidx $REF {} > ref/{}.fasta' ::: $SCAFFOLDS
parallel 'samtools faidx ref/{}.fasta' ::: $SCAFFOLDS
\time -v parallel 'extractHAIRS --bam $HIC/hic.{}.bam --hic 1 --VCF $VCF/pacbioccs.{}.filtered.vcf --out hapcut2Only/hic.{}.frag 2> hapcut2Only/extractHAIRS.{}.hic.log' ::: $SCAFFOLDS 2> hapcut2Only/extractHAIRS.hic.log

\time -v parallel 'extractHAIRS --pacbio 1 --ref ragoo/{}.fasta --new_format 1 --bam $PB/pacbioccs.{}.bam --VCF $VCF/pacbioccs.{}.filtered.vcf --out hapcut2Only/pacbioccs.{}.frag 2> hapcut2Only/extractHAIRS.{}.pb.log' ::: $SCAFFOLDS  2> hapcut2Only/extractHAIRS.pb.log

parallel 'cat hapcut2Only/hic.{}.frag hapcut2Only/pacbioccs.{}.frag > hapcut2Only/hic_pacbioccs.{}.frag' ::: $SCAFFOLDS

\time -v parallel 'HAPCUT2 --fragments hapcut2Only/hic_pacbioccs.{}.frag --VCF $VCF/pacbioccs.{}.filtered.vcf --output hapcut2Only/hic_pacbioccs.{}.hap --hic 1 2> hapcut2Only/HAPCUT2.{}.log' ::: $SCAFFOLDS   2> HAPCUT2.log

parallel "cut -d$'\t' -f1-11 hapcut2Only/hic_pacbioccs.{}.hap > hapcut2Only/hic_pacbioccs.{}.hap.cut" ::: $SCAFFOLDS
parallel 'whatshap hapcut2vcf $VCF/pacbioccs.{}.filtered.vcf hapcut2Only/hic_pacbioccs.{}.hap.cut -o hapcut2Only/hic.pb.{}.phased.vcf' ::: $SCAFFOLDS
#parallel 'whatshap compare --only-snvs --tsv-pairwise compare/compare.{}.tsv --longest-block-tsv compare/compare.{}.block.tsv hapcut2Only/hic.pb.{}.phased.vcf whatshap/pacbioccs.hic.{}.whatshap.phased.vcf > compare/compare.{}.log 2>&1' ::: $SCAFFOLDS
