mkdir -p hi-c; cp tests/hic_* hi-c/
mkdir -p pacbioccs; cp tests/hifi.fastq pacbioccs/
conda activate whdenovo
python pipeline.py --hic-path hi-c --pb-path pacbioccs --sample test --prefix out
