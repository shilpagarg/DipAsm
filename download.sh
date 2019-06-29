mkdir PGP1_data
cd PGP1_data
# For PGP1 Peregrine assembly
mkdir peregrine
cd peregrine
aws s3 cp s3://pgp1/jason/pgp-1-asm-r3-pg0.1.5.0/4-cns/cns-merge/p_ctg_cns.fa ./
cd ../

# For PGP1 PacBioCCS data
mkdir pacbioccs
cd pacbioccs
aws s3 sync s3://pgp1/pacbiocss/ ./
# source was from 
# ftp://pgp1:djkfLsjr876f@ftp2.pacificbiosciences.com/PGP1_fastq.tar.gz
# ftp://pgp1:djkfLsjr876f@ftp2.pacificbiosciences.com/PGP1_2_fastq.tar.gz
cd ../

# For PGP1 Hi-C data
mkdir hic
cd hic
for i in {52..69}; do aws s3 cp s3://pgp1/hic/SRR83100${i}_1.fastq ./ ; aws s3 cp s3://pgp1/hic/SRR83100${i}_2.fastq ./ ; done
cd ../
# The source was from NCBI GEO database, accesion id: GSE123552
cd ../

mkdir na12878_data
cd na12878_data

# For NA12878 Peregrine assembly
mkdir peregrine
cd peregrine
wget https://dl.dnanex.us/F/D/8ZgJgJp87p3bb3Vy3fjk5yVgzv9Fg9f8VYp7b4fG/p_ctg_cns_NA12878-r3-pg0.1.5.0.fa
cd ../

# For NA12878 PacBioCCS data
mkdir pacbioccs
cd pacbioccs
ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/NA12878/PacBio_SequelII_CCS_11kb/HG001.SequelII.pbmm2.hs37d5.whatshap.haplotag.RTG.trio.bam
samtools fastq -@32 HG001.SequelII.pbmm2.hs37d5.whatshap.haplotag.RTG.trio.bam > na12878.pacbioccs.fastq
cd ../

# For NA12878 Hi-C data
mkdir hic
cd hic
fastq-dump --split-files SRR6675327
cd ../

cd ../

# GRCh38 Reference
mkdir ref
cd ref
wget http://hgdownload.soe.ucsc.edu/goldenPath/hg38/bigZips/hg38.fa.gz > dl.hg38.fa.gz.log 2>&1
bgzip -cd hg38.fa.gz > hg38.fa
for i in {1..22} X Y ; do samtools faidx hg38.fa chr$i >> grch38.fa ; done
cd ../

