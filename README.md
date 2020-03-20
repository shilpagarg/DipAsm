# DipAsm: Efficient chromosome-scale haplotype-resolved assembly of human genomes

Haplotype-resolved or phased sequence assembly provides a complete picture of genomes and complex genetic variations. However, current phased assembly algorithms either fail to generate chromosome-scale phasing or require pedigree information, which limits their application. We present a method that leverages long accurate reads and long-range conformation data for single individuals to generate chromosome-scale phased assembly within a day. Applied to three public human genomes, PGP1, HG002, and NA12878, our method produced haplotype-resolved assemblies with contig NG50 up to 25 Mb and phased ∼99.5% of heterozygous sites to 98–99% accuracy, outperforming trio-based approach in terms of both contiguity and phasing completeness. We demonstrate the importance of chromosome-scale phased assemblies to discover structural variants, including thousands of new transposon insertions, and of highly polymorphic and medically important regions such as HLA and KIR. Our improved method will enable high-quality precision medicine and facilitate new studies of individual haplotype variation and population diversity.

See our preprint here: [https://doi.org/10.1101/810341](https://doi.org/10.1101/810341).

## Installation
```
mkdir -p /wd/dipasm/
cd /wd/dipasm/
git clone https://github.com/shilpagarg/DipAsm.git
# swith to a proper brach in nessary
cd /wd/dipasm/DipAsm/docker
docker build -t dipasm .
cd /wd/dipasm/DipAsm
docker run -it --rm -v  /wd/dipasm/DipAsm:/wd/dipasm/DipAsm/ -v /var/run/docker.sock:/var/run/docker.sock dipasm:latest /bin/bash
```

## Test example with docker
```
cd /wd/dipasm/DipAsm
bash test.sh | bash
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
## Results
This pipeline produces phased reads in the folder `sample_output/prefix/haplotag/`. On these phased reads, Peregrine should be run to produce phased contigs.


