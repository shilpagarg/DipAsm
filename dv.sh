INPUT_DIR="$1"
OUTPUT_DIR="$1/alignment/pacbioccs/vcf"
BIN_VERSION="0.8.0"
SCAFF=$2
sudo docker run \
  -v "${INPUT_DIR}":"/input" \
  -v "${OUTPUT_DIR}:/output" \
  gcr.io/deepvariant-docker/deepvariant:"${BIN_VERSION}" \
  /opt/deepvariant/bin/run_deepvariant \
  --model_type=PACBIO \
  --ref=/input/ragoo/ragoo_output/ragoo.fasta \
  --reads=/input/alignment/pacbioccs/split/pacbioccs.ragoo.${SCAFF}.bam \
  --output_vcf=/output/pacbioccs.ragoo.${SCAFF}.vcf.gz \
  --regions "${SCAFF}" \
  --num_shards=16
