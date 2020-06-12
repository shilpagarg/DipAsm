# DipAsm: Efficient chromosome-scale haplotype-resolved assembly of human genomes

Haplotype-resolved or phased sequence assembly provides a complete picture of genomes and complex genetic variations. However, current phased assembly algorithms either fail to generate chromosome-scale phasing or require pedigree information, which limits their application. We present a method that leverages long accurate reads and long-range conformation data for single individuals to generate chromosome-scale phased assembly within a day. Applied to three public human genomes, PGP1, HG002, and NA12878, our method produced haplotype-resolved assemblies with contig NG50 up to 25 Mb and phased ∼99.5% of heterozygous sites to 98–99% accuracy, outperforming trio-based approach in terms of both contiguity and phasing completeness. We demonstrate the importance of chromosome-scale phased assemblies to discover structural variants, including thousands of new transposon insertions, and of highly polymorphic and medically important regions such as HLA and KIR. Our improved method will enable high-quality precision medicine and facilitate new studies of individual haplotype variation and population diversity.

See our preprint here: [https://doi.org/10.1101/810341](https://doi.org/10.1101/810341).

## Installation

DipAsm requires [docker][dc] as [DeepVariant][dv] uses it. Users need to make
sure docker is installed and the docker service is started.

```sh
mkdir -p dipasm
cd dipasm
git clone https://github.com/shilpagarg/DipAsm.git
cd DipAsm/docker
docker build -t dipasm .
cd ../../..
docker run -it --rm -v $PWD/dipasm/DipAsm:/wd/dipasm/DipAsm/ -e HOSTWD=$PWD/dipasm/DipAsm -v /var/run/docker.sock:/var/run/docker.sock dipasm:latest /bin/bash
```

The `docker run -it` will start an interactive docker container session. You will be in
the virtual container envrionment which have the preinstall DipAsm and testing data. 


## Test example with docker

You can run the test for DipAsm within the docker container environment by:

```sh
cd /wd/dipasm/DipAsm
bash test.sh | bash
ls test_output/out/assemble/*-SCAFF-H?*/*.fa  # final assembly
```

### Run

Here is a brief description of the `pipeline.py` command:

```
Usage: pipeline.py [-h] --hic-path PATH --pb-path PATH --sample NAME [--female]
                   --prefix STR

Optional arguments:
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

This pipeline produces phased assemblies in the folder
`sample_output/prefix/assemble/` where `*-SCAFF-H1*/*.fa` gives contigs on the
first haplotype and `*-SCAFF-H2*/*.fa` gives the second haplotype.

## Acknowledgements

DipAsm depends on [Peregrine][pg], [3d-dna][3ddna], [minimap2][mm2],
[DeepVariant][dv], [whatshap][wh] and [hapcut2][hc].

[pg]: https://github.com/cschin/Peregrine
[mm2]: https://github.com/lh3/minimap2
[3ddna]: https://github.com/theaidenlab/3d-dna
[dv]: https://github.com/google/deepvariant
[wh]: https://bitbucket.org/whatshap/whatshap/src/master/
[hc]: https://github.com/vibansal/HapCUT2
[dc]: https://www.docker.com/
