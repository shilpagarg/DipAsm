INPUT_DIR=$1
REF=$2
BAM=$3
OUTPUT_DIR=${1}/dvcalls
BIN_VERSION="0.8.0"
SCAFF=$4
echo BAM: ${INPUT_DIR}/$BAM
echo REF: ${INPUT_DIR}/$REF
echo REGION: $SCAFF
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}:/output" \
  gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=/input/$REF \
  --reads=/input/$BAM \
  --output_vcf=/output/${BAM}.vcf.gz \
  --regions "${SCAFF}" \
  --num_shards=32
