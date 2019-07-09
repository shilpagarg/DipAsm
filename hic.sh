HICPATH=$1
RAGOO=$2
SAMPLE=$3
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
FILTER=$SCRIPTPATH/mapping_pipeline/filter_five_end.pl
COMBINER=$SCRIPTPATH/mapping_pipeline/two_read_bam_combiner.pl
source activate pipeline
export RAGOO
export SAMPLE
export FILTER
export COMBINER

echo BWA indexing
\time -v bwa index -a bwtsw $RAGOO 2> bwa.index.log

echo Hi-C data aligning..... 
# assume hic data is in one file with XX_R1.fastq and XX_R2.fastq
[ -d $HICPATH/split1 ] || mkdir -p $HICPATH/split1
[ -d $HICPATH/split2 ] || mkdir -p $HICPATH/split2
[ -d alignment/hic/chunks1 ] || mkdir -p alignment/hic/chunks1
[ -d alignment/hic/chunks2 ] || mkdir -p alignment/hic/chunks2
[ -d alignment/hic/repaired ] || mkdir -p alignment/hic/repaired
\time split -l 8000000 $HICPATH/*_R1.f*q $HICPATH/split1/ > $HICPATH/split1.log 2>&1 &
\time split -l 8000000 $HICPATH/*_R2.f*q $HICPATH/split2/ > $HICPATH/split2.log 2>&1; wait

\time ls $HICPATH/split1/ | parallel -j18 "bwa mem -t 40 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' -B 8 -M $RAGOO {} | samtools sort -@4 -m2g -O BAM -n > alignment/hic/chunks1/{/.}.nsort.bam" 2> hic.bwa.mem.1.log
\time ls $HICPATH/split2/ | parallel -j18 "bwa mem -t 40 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' -B 8 -M $RAGOO {} | samtools sort -@4 -m2g -O BAM -n > alignment/hic/chunks2/{/.}.nsort.bam" 2> hic.bwa.mem.2.log

ls alignment/hic/chunks1/*.nsort.bam | sed 's/alignment\/hic\/chunks1\///g' | parallel 'python ~/tools/HapCUT2/utilities/HiC_repair.py  -b1 alignment/hic/chunks1/{} -b2 alignment/hic/chunks2/{} -o alignment/hic/repaired/{.}.repaired.bam'
samtools merge -@72 alignment/hic/hic.repaired.bam alignment/hic/repaired/*

samtools fixmate -@ 72 alignment/hic/hic.repaired.bam - | samtools sort -@ 72 -m 2g - > alignment/hic/hic.fix.sort.bam
samtools index -@ 72 alignment/hic/hic.fix.sort.bam 
\time ~/tools/biobambam2/2.0.87-release-20180301132713/x86_64-etch-linux-gnu/bin/bammarkduplicates2 I=alignment/hic/hic.fix.sort.bam  O=alignment/hic/hic.fix.sort.md.bam  M=markdup.metrics markthreads=72 rmdup=1 index=1 2> hic.markdup.log

[ -d alignment/hic/split ] || mkdir -p alignment/hic/split

parallel -j6 'samtools view -@12 -b alignment/hic/hic.fix.sort.md.bam {} > alignment/hic/split/hic.{}.bam' ::: `cut -d$'\t' -f1 ${RAGOO}.fai`



