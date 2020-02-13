#!/bin/sh

HICPATH=$(readlink -f $1)
PBPATH=$(readlink -f $2)
SAMPLE=$3
FEMALE=$4
PREF=$5

SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

echo Using PacBioCCS data saved at: $PBPATH "All .fastq files here will be used"
echo Using Hi-C data saved at: $HICPATH "All *1.fastq and *2.fastq files here will be used"
echo Sample name: $SAMPLE
echo Output will be in ${SAMPLE}_output/$PREF

[ -d ${SAMPLE}_output ] || mkdir -p ${SAMPLE}_output
cd ${SAMPLE}_output
[ -d $PREF ] || mkdir -p $PREF
cd $PREF

[ -d alignment ] || mkdir -p alignment
cd alignment
[ -d hic ] || mkdir -p hic
[ -d pacbioccs ] || mkdir -p pacbioccs
cd ../
[ -d hapcut2 ] || mkdir -p hapcut2
[ -d whatshap ] || mkdir -p whatshap
[ -d haplotag ] || mkdir -p haplotag


[ -d peregrine ] || mkdir -p peregrine


cd peregrine
find $PBPATH/ -name "*.fastq" | sort > ${SAMPLE}.lst
conda activate peregrine
pg_run.py asm ${SAMPLE}.lst 24 24 24 24 24 24 24 24 24 --with-consensus --shimmer-r 3 --best_n_ovlp 8 
     --output ${SAMPLE}_all_asm-r3-pg0.1.5.3

cd ..
conda deactivate

exit
\time -v bwa index -a bwtsw $REF 2> bwa.index.log &
$SCRIPTPATH/pacbioccs.sh $PBPATH $REF $SAMPLE
wait

$SCRIPTPATH/hic.sh $HICPATH $REF $SAMPLE

$SCRIPTPATH/phase.sh $REF $SAMPLE &
$SCRIPTPATH/phase.hic_longread.sh $REF $SAMPLE
wait

SCAFFOLDS=`cut -d$'\t' -f1 ${REF}.fai`

parallel 'whatshap compare --only-snvs --tsv-pairwise compare/compare.{}.tsv --longest-block-tsv compare/compare.{}.block.tsv hapcut2Only/hic.pb.{}.phased.vcf whatshap/pacbioccs.hic.{}.whatshap.phased.vcf > compare/compare.{}.log 2>&1' ::: $SCAFFOLDS
