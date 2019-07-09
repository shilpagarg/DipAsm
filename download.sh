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

# Ground Truth for ragoo-based
tagged bams: ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/NA12878/PacBio_SequelII_CCS_11kb/HG001_GRCh38/HG001_GRCh38.haplotag.RTG.trio.bam

#ref-based is on hg19
hg19: ftp://ftp-trace.ncbi.nih.gov/1000genomes/ftp/technical/reference/human_g1k_v37.fasta.gz
phased calls: wget -O {output} ftp://platgene_ro:""@ussd-ftp.illumina.com/2016-1.0/hg19/small_variants/NA12878/NA12878.vcf.gz

# variants calls comparison from ragoo-based assemblies on grch38
phased calls: ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/NA12878_HG001/latest/GRCh38/HG001_GRCh38_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-X_v.3.3.2_highconf_PGandRTGphasetransfer.vcf.gz
EEE calls: http://ftp.1000genomes.ebi.ac.uk/vol1/ftp/data_collections/hgsv_sv_discovery/working/20181025_EEE_SV-Pop_1/VariantCalls_EEE_SV-Pop_1/EEE_SV-Pop_1.ALL.sites.20181204.vcf.gz

# Input data for hg002
PacBio CCS: ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/AshkenazimTrio/HG002_NA24385_son/PacBio_CCS_15kb/alignment/
HiC : from arima genomics, pgp1/arimagenomics/GM24385.AJ.*.fastq.gz
grch38 for ragoo: hg38.fa as above
peregrine contigs: hg002/analysis_withoutsalsa/peregrine/p_ctg_cns_p1.fa, hg002/analysis_withoutsalsa/peregrine/p_ctg_cns_p2.fa
grch38 for ref-based: ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/000/001/405/GCA_000001405.15_GRCh38/seqs_for_alignment_pipelines.ucsc_ids/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna.gz

Ground Truth comparison:
phased vcf: ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio/HG002_NA24385_son/latest/GRCh38/HG002_GRCh38_GIAB_highconf_CG-Illfb-IllsentieonHC-Ion-10XsentieonHC-SOLIDgatkHC_CHROM1-22_v.3.3.2_highconf_triophased.vcf.gz
haplotgged bams: partitioned from Jason and Chai, peregrine + trio

