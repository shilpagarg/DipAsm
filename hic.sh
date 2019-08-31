HICPATH=$1
REF=$2
SAMPLE=$3
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
source activate pipeline
export REF
export SAMPLE

#echo BWA indexing
#\time -v bwa index -a bwtsw $REF 2> bwa.index.log

echo Hi-C data aligning.....
[ -d ~/split/split1 ] || mkdir -p ~/split/split1
[ -d ~/split/split2 ] || mkdir -p ~/split/split2
[ -d alignment/hic/chunks1 ] || mkdir -p alignment/hic/chunks1
[ -d alignment/hic/chunks2 ] || mkdir -p alignment/hic/chunks2
[ -d alignment/hic/repaired ] || mkdir -p alignment/hic/repaired
[ -d alignment/hic/split ] || mkdir -p alignment/hic/split

ls $HICPATH/*_1.f*q | parallel 'split -l 8000000 {} ~/split/split1/{/.}_ > ~/split/split1.log 2>&1'
ls $HICPATH/*_2.f*q | parallel 'split -l 8000000 {} ~/split/split2/{/.}_ > ~/split/split2.log 2>&1'

\time ls ~/split/split1/ | parallel -j12 "bwa mem -t 6 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' -B 8 -M $REF ~/split/split1/{} | samtools sort -@4 -m2g -O BAM -n > alignment/hic/chunks1/{/.}.nsort.bam" 2> hic.bwa.mem.1.log
\time ls ~/split/split2/ | parallel -j12 "bwa mem -t 6 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' -B 8 -M $REF ~/split/split2/{} | samtools sort -@4 -m2g -O BAM -n > alignment/hic/chunks2/{/.}.nsort.bam" 2> hic.bwa.mem.2.log
# For HiC_repair.py, manually change line:229, output str to 'wb', for compressed BAM output.
my_func() {   echo python ~/tools/HapCUT2/utilities/HiC_repair.py  -b1 $1 -b2 $2 -o alignment/hic/repaired/${1##*/}.repaired.bam; }
export -f my_func
parallel --xapply my_func ::: alignment/hic/chunks1/*.nsort.bam ::: alignment/hic/chunks2/*.nsort.bam | parallel
samtools merge -@72 alignment/hic/hic.repaired.bam alignment/hic/repaired/*

samtools fixmate -@ 72 alignment/hic/hic.repaired.bam - | samtools sort -@ 72 -m 2G - > alignment/hic/hic.fix.sort.bam
samtools index -@ 72 alignment/hic/hic.fix.sort.bam
\time ~/tools/biobambam2/2.0.87-release-20180301132713/x86_64-etch-linux-gnu/bin/bammarkduplicates2 I=alignment/hic/hic.fix.sort.bam  O=alignment/hic/hic.fix.sort.md.bam  M=markdup.metrics markthreads=72 rmdup=1 index=1 2> hic.markdup.log

parallel -j7 'samtools view -b -@10 alignment/hic/hic.fix.sort.md.bam {} > alignment/hic/split/hic.{}.bam' ::: `cut -d$'\t' -f1 ${REF}.fai`
