#!/bin/sh

HICPATH=$(readlink -f $1)
PBPATH=$(readlink -f $2)
ASM=$(readlink -f $3)
RAGOO=$4
REF=$5
SAMPLE=$6
FEMALE=$7
PREF=$8

SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}

echo Using reference: $REF
# echo Using assembly: $ASM
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
[ -d hapcut2Only ] || mkdir -p hapcut2Only
[ -d haplotag ] || mkdir -p haplotag
[ -d compare ] || mkdir -p compare
[ -d ref ] || mkdir -p ref

echo RAGOO $RAGOO
if [ $RAGOO != 'FALSE' ] ; then
    echo DOING RAGOO
    for i in $PBPATH/*f*q
    do
      seqtk seq -A $i >> alignment/pacbioccs/pacbioccs.fasta;
    done
    echo Running RaGOO
    mkdir -p ragoo
    cd ragoo
    ln -s $SCRIPTPATH/$REF
    ln -s $SCRIPTPATH/$RAGOO
    echo "python $SCRIPTPATH/tools/RaGOO/ragoo.py -t 96 -s -C -T corr -R ../alignment/pacbioccs/pacbioccs.fasta ${RAGOO##*/} ${REF##*/} 1> ragoo1.log 2> ragoo2.log"
    time python $SCRIPTPATH/tools/RaGOO/ragoo.py -t 96 -s -C -T corr -R ../alignment/pacbioccs/pacbioccs.fasta ${RAGOO##*/} ${REF##*/} 1> ragoo1.log 2> ragoo2.log
    cd ../
    mv ragoo/ragoo_output/ragoo.fasta ref/
    REF=ref/ragoo.fasta
else
    echo NOT DOING RAGOO
    cd ref
    # ln -s $ASM
    cd ../
    REF=ref/${ASM##*/}
fi

# TODO change the assembly sequence name

\time -v bwa index -a bwtsw $REF 2> bwa.index.log &
$SCRIPTPATH/pacbioccs.sh $PBPATH $REF $SAMPLE
wait

$SCRIPTPATH/hic.sh $HICPATH $REF $SAMPLE

$SCRIPTPATH/phase.sh $REF $SAMPLE &
$SCRIPTPATH/phase.hic_longread.sh $REF $SAMPLE
wait

SCAFFOLDS=`cut -d$'\t' -f1 ${REF}.fai`

parallel 'whatshap compare --only-snvs --tsv-pairwise compare/compare.{}.tsv --longest-block-tsv compare/compare.{}.block.tsv hapcut2Only/hic.pb.{}.phased.vcf whatshap/pacbioccs.hic.{}.whatshap.phased.vcf > compare/compare.{}.log 2>&1' ::: $SCAFFOLDS
