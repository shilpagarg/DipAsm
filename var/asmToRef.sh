if [ $# != 3 ] ; then
echo "USAGE: $0 DIPASMPATH REF SAMPLE"
exit 1;
fi

DIPASM=$(readlink -f $1)
REF=$(readlink -f $2)
SAMPLE=$3
OUTDIR=${SAMPLE}_output
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

export OUTDIR
export DIPASM

mkdir $OUTDIR

#TODO: maybe don't consider scaffolds, but chr ones only 
#echo Concatenating...
#for i in $DIPASM/*H1.fa; do sed -e "s/>/>$(basename $i .fa)\./g" $i >> $OUTDIR/H1.fa; done
#for i in $DIPASM/*H2.fa; do sed -e "s/>/>$(basename $i .fa)\./g" $i >> $OUTDIR/H2.fa; done

#echo mapping H1.fa/H2.fa to $REF
#TODO correct the dipasm file name; take care of reference chromosome name and the expression in grep
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t20 ref/chr${CHR}.fasta $DIPASM/${CHR}.H1.fasta | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/chr${CHR}.fasta - | grep -E "^#|^chr$CHR$t" | htsbox bgzip > $OUT/chr${CHR}.H1.vcf.gz
minimap2 --paf-no-hit -cxasm5 --cs -r2k -t20 ref/chr${CHR}.fasta $DIPASM/${CHR}.H2.fasta | sort -k6,6 -k8,8n | ~/tools/paftools.js call -f ref/chr${CHR}.fasta - | grep -E "^#|^chr$CHR$t" | htsbox bgzip > $OUT/chr${CHR}.H2.vcf.gz
tabix -p vcf $OUT/chr${CHR}.H1.vcf.gz
tabix -p vcf $OUT/chr${CHR}.H2.vcf.gz
#minimap2 --paf-no-hit -axasm5 --cs -r2k -t16 $REF $OUTDIR/H1.fa 2> $OUTDIR/H1.paf.log > $OUTDIR/H1.sam.gz &
#minimap2 --paf-no-hit -axasm5 --cs -r2k -t16 $REF $OUTDIR/H2.fa 2> $OUTDIR/H2.paf.log > $OUTDIR/H2.sam.gz ; wait

# sort SAM
#echo sorting SAM
#k8 $SCRIPTPATH/sam-flt.js $OUTDIR/H1.sam.gz | samtools sort -m4G -@4 -o $OUTDIR/H1.bam - &
#k8 $SCRIPTPATH/sam-flt.js $OUTDIR/H2.sam.gz | samtools sort -m4G -@4 -o $OUTDIR/H2.bam - ; wait

# "call" variants with naive mpileup
#echo mpileup variant calling...
#htsbox pileup -q5 -evcf $REF $OUTDIR/H1.bam $OUTDIR/H2.bam > $OUTDIR/asmToRef.merged.vcf

# generate phased VCF
echo Phasing...
bcftools merge --force-samples $OUT/chr${CHR}.H1.vcf.gz  $OUT/chr${CHR}.H2.vcf.gz | sed 's/\.\/\./0\/0/g'>  $OUT/chr${CHR}.merged.vcf
python $SCRIPTPATH/vcf-pair.py $OUTDIR/chr${CHR}.merged.vcf > $OUTDIR/chr${CHR}.phased.vcf

