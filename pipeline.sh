#!/bin/bash
set -ex
#. /opt/conda/bin/activate
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
[ -d assemble] || mkdir -p assemble


cd peregrine
find $PBPATH/ -name "*.fastq" | sort > ${SAMPLE}.lst
eval "$(conda shell.bash hook)"
conda activate peregrine #Do manually if didn't work
echo pg_run.py asm ${SAMPLE}.lst 24 24 24 24 24 24 24 24 24 --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output asm-r3-pg0.1.5.3 1> pere.log
echo yes | pg_run.py asm ${SAMPLE}.lst 24 24 24 24 24 24 24 24 24 --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output asm-r3-pg0.1.5.3 1> pere.log

# Say yes here to license
cd ..
conda deactivate

echo peregrine assembly done
REF="$PWD/peregrine/asm-r3-pg0.1.5.3/p_ctg_cns.fa"
ls -l $REF
conda activate whdenovo
/usr/bin/time -v bwa index -a bwtsw $PWD/peregrine/asm-r3-pg0.1.5.3/p_ctg_cns.fa 2> bwa.index.log &
pwd
echo Run pacbioccs.sh: "$SCRIPTPATH/pacbioccs.sh $PBPATH $REF $SAMPLE" 
$SCRIPTPATH/pacbioccs.sh $PBPATH $REF $SAMPLE  #> ccs.log 2>&1
wait
$SCRIPTPATH/hic.sh $HICPATH $REF $SAMPLE > hic.log 2>&1
wait
$SCRIPTPATH/phase.sh $REF $SAMPLE & 2> phase.log
wait

cp $PWD/haplotag/*.fasta $PBPATH/

SCAFFOLDS=`cut -d$'\t' -f1 $REF.fai`

cd assemble
parallel "find $PBPATH/ -name "{}-SCAFF-H1.fasta" > {}-SCAFF-H1.lst" ::: $SCAFFOLDS
parallel "find $PBPATH/ -name "{}-SCAFF-untagged.fasta" >> {}-SCAFF-H1.lst" ::: $SCAFFOLDS

eval "$(conda shell.bash hook)"
conda activate peregrine
parallel 'echo yes | pg_run.py asm {}-SCAFF-H1.lst 24 24 24 24 24 24 24 24 24 --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output {}-SCAFF-H1-asm-r3-pg0.1.5.3 1> pere.log' ::: $SCAFFOLDS



parallel "find $PBPATH/ -name "{}-SCAFF-H2.fasta" > {}-SCAFF-H2.lst" ::: $SCAFFOLDS
parallel "find $PBPATH/ -name "{}-SCAFF-untagged.fasta" >> {}-SCAFF-H2.lst" ::: $SCAFFOLDS


parallel 'echo yes | pg_run.py asm {}-SCAFF-H2.lst 24 24 24 24 24 24 24 24 24 --with-consensus --shimmer-r 3 --best_n_ovlp 8 --output {}-SCAFF-H2-asm-r3-pg0.1.5.3 1> pere.log' ::: $SCAFFOLDS
