CHR=$1
PS=`grep -v '^#' phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.vcf  | grep 'PS' | cut -d':' -f13 | sort | uniq -cd | sort -k1nr | head -1 | awk '{print $2}'`
grep -E "^#|$PS$" phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.vcf   > phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.largestBlock.vcf 
bgzip -c phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.largestBlock.vcf > phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.largestBlock.vcf.gz
tabix -p vcf phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.largestBlock.vcf.gz
mkdir taggedBAM
whatshap haplotag --reference phasedVCF/GRCh37.fasta phasedVCF/pacbioccs.hic.${CHR}.whatshap.phased.largestBlock.vcf.gz pacbioccs/pacbioccs.${CHR}.bam -o taggedBAM/na12878.pacbioccs.${CHR}.largestBlock.tagged.bam

