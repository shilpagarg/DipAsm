# WHdenovo
A fast and accurate diploid assembly pipeline for human genomes.

### Environment Setup
```
./INSTALLATION.sh
```

### Run
```
./pipeline.sh REF ASM PACBIOCCSPATH HICPATH SAMPLE

REF            -- Reference genome for assembly scaffolding
ASM            -- Raw consensus assembly FASTA file
PACBIOCCSPATH  -- A PATH that have all the PacBioCCS data stored
HICPATH        -- A PATH that have all the Hi-C data stored. Pair-ended file name should be in XX_1.fastq/XX_2.fastq style
SAMPLE         -- The identifier for the individual. This would be included in BAM file read group and VCF sample name and final haplotagged BAM file name prefix.
```
