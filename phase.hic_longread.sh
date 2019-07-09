HIC=alignment/hic/split
PB=alignment/pacbioccs/split
VCF=alignment/pacbioccs/vcf
SAMPLE=$1
#SCAFFOLDS="{1..22}"
export HIC
export PB
export VCF
export SAMPLE


\time -v parallel 'extractHAIRS --bam $HIC/hic.{}.bam --hic 1 --VCF $VCF/pacbioccs.{}.filtered.vcf --out hapcut2Only/hic.{}.frag 2> hapcut2Only/extractHAIRS.{}.hic.log' ::: {1..22} 2> hapcut2Only/extractHAIRS.hic.log

\time -v parallel 'extractHAIRS --pacbio 1 --ref ref/{}.fasta --new_format 1 --bam $PB/pacbioccs.{}.bam --VCF $VCF/pacbioccs.{}.filtered.vcf --out hapcut2Only/pacbioccs.{}.frag 2> hapcut2Only/extractHAIRS.{}.pb.log' ::: {1..22} 2> hapcut2Only/extractHAIRS.pb.log

parallel 'cat hapcut2Only/hic.{}.frag hapcut2Only/pacbioccs.{}.frag > hapcut2Only/hic_pacbioccs.{}.frag' ::: {1..22}

\time -v parallel 'HAPCUT2 --fragments hapcut2Only/hic_pacbioccs.{}.frag --VCF $VCF/pacbioccs.{}.filtered.vcf --output hapcut2Only/hic_pacbioccs.{}.hap --hic 1 2> hapcut2Only/HAPCUT2.{}.log' ::: {1..22}  2> HAPCUT2.log

parallel "cut -d$'\t' -f1-11 hapcut2Only/hic_pacbioccs.{}.hap > hapcut2Only/hic_pacbioccs.{}.hap.cut" ::: {1..22}
parallel 'whatshap hapcut2vcf $VCF/pacbioccs.{}.filtered.vcf hapcut2Only/hic_pacbioccs.{}.hap.cut -o hapcut2Only/hic.pb.{}.phased.vcf' ::: {1..22}
parallel 'whatshap stats hapcut2Only/hic.pb.{}.phased.vcf > stats.{}.log 2>&1' ::: {1..22}
mkdir hapcut2Only/compare
parallel 'whatshap compare --only-snvs --tsv-pairwise hapcut2Only/compare/compare.{}.tsv --longest-block-tsv hapcut2Only/compare/compare.{}.block.tsv hapcut2Only/hic.pb.{}.phased.vcf truth/na12878.{}.phased.vcf > hapcut2Only/compare/compare.{}.log 2>&1' ::: {1..22}

