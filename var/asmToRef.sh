if [ $# != 3 ] ; then
echo "USAGE: $0 CHR  REF SAMPLE"
exit 1;
fi

CHR=$1
REF=$(readlink -f $2)
SAMPLE=$3
OUTDIR=${SAMPLE}_output
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
t=$'\t'
export OUTDIR
export DIPASM

mkdir $OUTDIR

#echo mapping H1.fa/H2.fa to $REF
#TODO correct the dipasm file name; take care of reference chromosome name and the expression in grep
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t36 ref/${CHR}.fasta dipasm/chr${CHR}_RaGOO-p_ctg_cns-H1.fa | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/${CHR}.fasta - | grep -E "^#|^$CHR$t" | htsbox bgzip > $OUTDIR/${CHR}.H1.vcf.gz
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t36 ref/${CHR}.fasta dipasm/chr${CHR}_RaGOO-p_ctg_cns-H2.fa | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/${CHR}.fasta - | grep -E "^#|^$CHR$t" | htsbox bgzip > $OUTDIR/${CHR}.H2.vcf.gz
tabix -p vcf $OUTDIR/${CHR}.H1.vcf.gz
tabix -p vcf $OUTDIR/${CHR}.H2.vcf.gz

echo Phasing...
bcftools merge --force-samples -m none -0 $OUTDIR/${CHR}.H1.vcf.gz  $OUTDIR/${CHR}.H2.vcf.gz > $OUTDIR/${CHR}.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUTDIR/${CHR}.merged.vcf $SAMPLE > $OUTDIR/${CHR}.phased.vcf 

mkdir $OUTDIR/compare
echo comparing...
whatshap compare --only-snvs --tsv-pairwise $OUTDIR/compare/compare.${CHR}.pw.tsv --longest-block-tsv $OUTDIR/compare/compare.${CHR}.block.tsv snvTruth/${CHR}.vcf $OUTDIR/${CHR}.phased.vcf > $OUTDIR/compare/compare.${CHR}.log 2>&1

echo truevari
bgzip -c $OUTDIR/${CHR}.phased.vcf > $OUTDIR/${CHR}.phased.vcf.gz
tabix -p vcf $OUTDIR/${CHR}.phased.vcf.gz
~/tools/truvari/truvari/truvari -f ref/${CHR}.fasta  -b svTruth/${CHR}.vcf --includebed svTruth/${CHR}.bed -o $OUTDIR/truvari_${CHR} --giabreport --passonly -r 1000 -p 0.00 -c $OUTDIR/${CHR}.phased.vcf.gz
