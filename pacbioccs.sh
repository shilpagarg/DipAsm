PBPATH=$1
RAGOO=$2
SAMPLE=$3
SCRIPTPATH=${0%/*}
source activate pipeline
export SCRIPTPATH

samtools faidx $RAGOO

echo Minimap2

\time -v minimap2 -a -k 19 -O 5,56 -E 4,1 -B 5 -z 400,50 -r 2k -t 84 -R '@RG\tSM:$SAMPLE\tID:$SAMPLE' --eqx --secondary=no $RAGOO $PBPATH/*.f*q 2> minimap2.pacbioccs.ragoo.log | samtools sort -@96 -m3g --output-fmt BAM -o alignment/pacbioccs/pacbioccs.ragoo.bam
samtools index -@96 alignment/pacbioccs/pacbioccs.ragoo.bam

[ -d split ] || mkdir -p split

echo Splitting PacBioCCS alignment
cut -d$'\t' -f1 ${RAGOO}.fai | parallel -j4 'samtools view -@16 -b pacbioccs.ragoo.bam {} > alignment/pacbioccs/split/pacbioccs.ragoo.{}.bam'
cut -d$'\t' -f1 ${RAGOO}.fai | parallel -j4 'samtools index -@16 alignment/pacbioccs/split/pacbioccs.ragoo.{}.bam'

[ -d vcf ] || mkdir -p vcf

echo DeepVariant.....

cut -d$'\t' -f1 ${RAGOO}.fai | parallel -j5 './dv.sh {}'

ls alignment/pacbioccs/vcf/*gz | parallel 'bgzip -cd {} > {.}'
ls alignment/pacbioccs/vcf/*vcf | parallel "grep -E '^#|0/0|1/1|0/1|1/0|0/2|2/0' {} > {.}.filtered.vcf"
