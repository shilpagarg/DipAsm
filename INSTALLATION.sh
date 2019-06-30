#!/bin/sh
# installation of tools not on conda
[ -d tools ] || mkdir -p tools
cd tools
git clone https://github.com/malonge/RaGOO.git
cd RaGOO
python setup.py install
cd ../

wget https://github.com/broadinstitute/picard/releases/download/2.20.2/picard.jar

git clone https://github.com/vibansal/HapCUT2.git
cd HapCUT2
make
cd ../

conda env create -f environment.yml

if ( ! sudo yum install -y docker ) ; then
echo \"sudo yum install -y docker\" failed, trying apt-get;
if ( ! sudo apt-get install --yes docker ); then
echo \"sudo apt-get install --yes docker\" failed.;
echo docker installation failed;
echo If you have docker intalled, run \"sudo systemctl start docker\" to activate it.
exit;
fi
fi

sudo systemctl start docker

