#!/bin/bash
. /opt/conda/bin/activate
conda env create -n whdenovo -f environment.yml
conda activate whdenovo
git clone https://github.com/theaidenlab/3d-dna.git
