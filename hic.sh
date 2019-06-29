HICPATH=$1
RAGOO=$2
SAMPLE=$3
SCRIPTPATH=${0%/*}
FILTER=$SCRIPTPATH/mapping_pipeline/filter_five_end.pl
COMBINER=$SCRIPTPATH/mapping_pipeline/two_read_bam_combiner.pl
source activate pipeline
export RAGOO
export SAMPLE
export FILTER
export COMBINER

echo BWA indexing
#\time -v bwa index -a bwtsw $RAGOO 2> bwa.index.log

echo Hi-C data aligning.....
ls $HICPATH/*.f*q | \time -v parallel -j2 "bwa mem -t 40 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' $RAGOO {} | perl $FILTER | samtools view -@12 -Sb - > alignment/hic/{/.}.filtered.bam" 2> hic.bwa.mem.log

echo Post-processing
ls alignment/hic/*_1.filtered.bam | sed 's/_1.filtered.bam//g' | time -v parallel -j2 'perl $COMBINER {}_1.filtered.bam {}_2.filtered.bam samtools 10 | samtools view -@ 40 -bS -t ${RAGOO}.fai - | samtools sort -@ 40 -m3g -n - > {.}.combined.bam' 2> hic.combine.log

ls alignment/hic/*combined.bam | \time -v parallel -j2 'samtools fixmate -@40 {} - | samtools sort -@40 -m3g - > {.}.fixed.bam' 2> hic.fixmate.log

ONE=`ls alignment/hic/{/.}.filtered.bam | head -1`
samtools view -H $ONE | grep -v '^@PG' > alignment/hic/header
ls alignment/hic/*fixed.bam | parallel 'samtools reheader -P alignment/hic/header {} > {.}.RG.bam'

input=''
for i in alignment/hic/*RG.bam; do input=$input' INPUT='$i ; done
\time -v java -Xmx256G -jar tools/picard.jar MergeSamFiles $input OUTPUT=alignment/hic/hic.ragoo.bam USE_THREADING=TRUE ASSUME_SORTED=TRUE VALIDATION_STRINGENCY=LENIENT 2> merge.hic2ragoo.log

# In case data size is too large, check --hash-table-size and --sort-buffer-size
\time -v sambamba markdup -r -t 72 alignment/hic/hic.ragoo.bam alignment/hic/hic.ragoo.md.bam 2> hic.markdup.log

echo Splitting Hi-C processed alignments
[ -d split ] || mkdir -p split
parallel -j6 'samtools view -b -@12 alignment/hic/hic.ragoo.md.bam {} > alignment/hic/split/hic.ragoo.{}.bam' ::: `cut -d$'\t' -f1 ${RAGOO}.fai`

