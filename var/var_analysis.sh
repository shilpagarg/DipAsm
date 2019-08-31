if [ $# -eq 3 ]; then
   echo Dipcall only mode;
   MODE='ASM'
elif [ $# -eq 4 ]; then
   echo Dipcall, taggedReads sniffles;
   MODE='REF'
else
   echo Usage:
   echo For customized assembly based
   echo ./var_analysis DIPASM_PATH REF SAMPLE_NAME
   echo For reference based
   echo ./var_analysis DIPASM_PATH TAGGED_READS_PATH REF SAMPLE_NAME
   exit
fi

[ -d ${SAMPLE}_output ] || mkdir -p ${SAMPLE}_output 
cd ${SAMPLE}_output 

if [ $MODE == 'ASM' ]; then
   DIPASMPATH=$(readlink -f $1)
   REF=$(readlink -f $2)
   SAMPLE=$3
elif [ $MODE == 'REF' ]; then
   DIPASMPATH=$(readlink -f $1)
   TAGPATH=$(readlink -f $2)
   REF=$(readlink -f $3)
   SAMPLE=$4
fi

cat $DIPASM/*H1.f*a > $DIPASM/H1.fa
cat $DIPASM/*H2.f*a > $DIPASM/H2.fa
$SCRIPTPATH/dipcall_wholeGenome.sh $DIPASM/H1.fa $DIPASM/H2.fa $REF $SAMPLE

if [ $MODE == 'REF' ]; then
   [ -d ref ] || mkdir -p ref
   samtools faidx $REF
   SCAFFOLDS=`cut -d$'\t' -f1 ${REF}.fai`
   parallel 'samtools faidx $REF {} > ref/{}.fasta' ::: $SAFFOLDS
   parallel 'samtools faidx ref/{}.fasta' ::: $SCAFFOLDS
   for i in $SCAFFOLDS; do $SCRIPTPATH/tagReadsToRef.perchr.sh $TAGPATH/*${i}*.bam ref/${i}.fasta $i $SAMPLE; done
   bcftools concat ${SAMPLE}_sniffles/sniffles_vcf/*.sniffles.phased.vcf.gz > ${SAMPLE}_sniffles/sniffles_vcf/${SAMPLE}.sniffles.merged.phased.vcf
   echo Final output for tagged reads based analysis is in ${SAMPLE}_sniffles/sniffles_vcf/${SAMPLE}.sniffles.merged.phased.vcf
fi

