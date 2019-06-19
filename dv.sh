INPUT_DIR="/home/ec2-user/na12878"
OUTPUT_DIR="/home/ec2-user/na12878/alignment/pacbioccs/vcf"
BIN_VERSION="0.8.0"
SCAFF=$1
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
