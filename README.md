# WHdenovo
A fast and accurate diploid assembly pipeline for human genomes.

### Environment Setup
```
./INSTALLATION.sh
```

### Run
```
usage: pipeline.py [-h] --hic-path PATH --pb-path PATH --sample NAME [--female]
                   --prefix STR

optional arguments:
  -h, --help         show this help message and exit
  --hic-path PATH    Use Hi-C data from this path. Should be named by *1.fastq
                     and *2.fastq.
  --pb-path PATH     Use PacBioCCS data from this path. All fastq will be
                     used.
  --sample NAME      Sample name to put for Read Group of BAM and Sample of
                     VCF.
  --prefix STR       Prefix name for the experiment, for example "refBased",
                     "ragooBased".

Example:

python pipeline.py --hic-path data/hic --pb-path data/pacbiocss --sample PGP1 --prefix asm
```
