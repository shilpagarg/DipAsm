cd ~/pgp1

mkdir peregrine
cd peregrine
aws s3 cp s3://pgp1/jason/pgp-1-asm-r3-pg0.1.5.0/4-cns/cns-merge/p_ctg_cns.fa ./

cd ../
mkdir pacbioccs
cd pacbioccs
aws s3 sync s3://pgp1/pacbiocss/ ./

cd ~/storage
for i in {52..69}; do aws s3 cp s3://pgp1/hic/SRR83100${i}_1.fastq ./ ; aws s3 cp s3://pgp1/hic/SRR83100${i}_2.fastq ./ ; done

