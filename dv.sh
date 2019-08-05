INPUT_DIR="$1"
OUTPUT_DIR="$1/alignment/pacbioccs/vcf"
BIN_VERSION="0.8.0"
SCAFF=$2
REF=${3##*/}
PAT=`echo $SCAFF | sed 's/\([^\\]\);/\1\\\\;/g' | sed 's/\([^\\]\)=/\1\\\\=/g'`
#short=`echo $SCAFF | cut -d';' -f1 | cut -d'.' -f2`
#echo $short
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}:/output" \
  gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=/input/ref/$REF \
  --reads=/input/alignment/pacbioccs/split/"pacbioccs.${PAT}.bam" \
  --output_vcf=/output/"pacbioccs.${SCAFF}.vcf.gz" \
  --regions "${PAT}" \
  --num_shards=16
