#!/bin/sh
# installation of tools not on conda


[ -d tools ] || mkdir -p tools
cd tools

git clone https://github.com/cschin/Peregrine.git
cd Peregrine
bash install_with_conda.sh
cd ..

conda activate peregrine
conda deactivate

wget https://github.com/broadinstitute/picard/releases/download/2.20.2/picard.jar

git clone https://github.com/shilpagarg/HapCUT2.git
wget https://github.com/gt1/biobambam2/releases/download/2.0.87-release-20180301132713/biobambam2-2.0.87-release-20180301132713-x86_64-etch-linux-gnu.tar.gz

tar -xvzf biobambam2-2.0.87-release-20180301132713-x86_64-etch-linux-gnu.tar.gz

git clone https://github.com/theaidenlab/3d-dna.git

cd ..
# conda version: 4.7.5
conda env create -n whdenovo -f environment.yml

conda activate whdenovo
bash ./tools/3d-dna/run-asm-pipeline.sh

conda env create -n dv -f dv.yml




