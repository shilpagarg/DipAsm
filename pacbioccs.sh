PBPATH=$1
REF=$2
SAMPLE=$3
SCRIPTPATH=$(readlink -f $0)
SCRIPTPATH=${SCRIPTPATH%/*}
PWD=`pwd`
#source activate pipeline
export SCRIPTPATH
export PWD

samtools faidx $REF

echo Minimap2

\time -v minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k -t 72 -R "@RG\tSM:$SAMPLE\tID:$SAMPLE" --eqx --secondary=no $REF $PBPATH/*.f*q 2> minimap2.pacbioccs.log | samtools sort -@72 --output-fmt BAM -o alignment/pacbioccs/pacbioccs.bam
samtools index -@72 alignment/pacbioccs/pacbioccs.bam

[ -d alignment/pacbioccs/split ] || mkdir -p alignment/pacbioccs/split

echo Splitting PacBioCCS alignment
cut -d$'\t' -f1 ${REF}.fai | parallel -j4 'samtools view -@16 -b alignment/pacbioccs/pacbioccs.bam {} > alignment/pacbioccs/split/pacbioccs.{}.bam'
cut -d$'\t' -f1 ${REF}.fai | parallel -j4 'samtools index -@16 alignment/pacbioccs/split/pacbioccs.{}.bam'

[ -d alignment/pacbioccs/vcf ] || mkdir -p alignment/pacbioccs/vcf

echo DeepVariant.....
cut -d$'\t' -f1 ${REF}.fai | parallel -j5 '$SCRIPTPATH/dv.sh $PWD {}'

ls alignment/pacbioccs/vcf/*gz | parallel 'bgzip -cd {} > {.}'
ls alignment/pacbioccs/vcf/*vcf | parallel "grep -E '^#|0/0|1/1|0/1|1/0|0/2|2/0' {} > {.}.filtered.vcf"
