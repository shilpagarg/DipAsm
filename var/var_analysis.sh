DIPASMPATH=$(readlink -f $1)
TAGPATH=$(readlink -f $2)
SNVGTPATH=$(readlink -f $3)
SVGTPATH=$(readlink -f $4)
SVBEDPATH=$(readlink -f $5)
ASM=$(readlink -f $6)
REF=$(readlink -f $7)
SAMPLE=$8
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
SCAFFOLDS=`cut -d$'\t' -f1 ${ASM}.fai`

OUT=$SAMPLE'_var'

[ -d $OUT ] || mkdir -p $OUT
cd $OUT

[ -d ref ] || mkdir -p ref
parallel 'samtools faidx $REF {} > ref/{}.fasta' ::: `cut -d$'\t' -f1 ${REF}.fai`
parallel 'samtools faidx ref/{}.fasta' ::: `cut -d$'\t' -f1 ${REF}.fai`

#TODO having issue in finding the concordance in dipasm scaffolds and reference chr
for i in $SCAFFOLDS; do $SCRIPTPATH/tagReadsToRef.perchr.sh $TAGPATH/*${i}*.bam ref/chr${i}.fasta chr${i} taggedRead_sniffles PGP1 hapcut2Only/hic.pb.chr${i}.phased.vcf a a; done


#TODO also
for i in $SCAFFOLDS; do $SCRIPTPATH/asmToRef.sh $DIPASM $REF $SAMPLE $i ${SNVGTPATH}/${i}.vcf ${SVGTPATH}/${i}.vcf ${SVBEDPATH}/${i}.bed; done


