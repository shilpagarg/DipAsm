For running the var analysis, there are basically two modes, mainly reference-based or pure denovo, depending on the reference sequence used for the pipeline

For customized assembly based
```
./var_analysis DIPASM_PATH REF SAMPLE_NAME
```
For reference (such as GRCh37 or GRCh38) based
```
./var_analysis DIPASM_PATH TAGGED_READS_PATH REF SAMPLE_NAME
```
After it is done, the script will show the path for the variants it calls


For the evaluation on the variants called above
For customized assembly based, only evaluate the dipcall result
```
./var_eval DIPASM_PATH REF SNV_GroundTruth SV_GroundTruth SV_BED PREFIX
```
For reference based, evaluate results from dipcall, sniffles, and whatshap phasing \(rtg\)
```
./var_analysis DIPASM_PATH SNIFFLES WHATSHAP_PATH REF SNV_GroundTruth SV_GroundTruth SV_BED PREFIX
```

Ground truths are single files for whole genome. For example, the ones we used for HG002 are:
SNV:
ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/release/AshkenazimTrio/HG002_NA24385_son/latest/GRCh37/HG002_GRCh37_GIAB_highconf_CG-IllFB-IllGATKHC-Ion-10X-SOLID_CHROM1-22_v.3.3.2_highconf_triophased.vcf.gz
SV:
ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/AshkenazimTrio/analysis/NIST_SVs_Integration_v0.6/HG002_SVs_Tier1_v0.6.vcf.gz
BED:
ftp://ftp-trace.ncbi.nlm.nih.gov/giab/ftp/data/AshkenazimTrio/analysis/NIST_SVs_Integration_v0.6/HG002_SVs_Tier1_v0.6.bed
