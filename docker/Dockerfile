#creates a base image from condo
FROM continuumio/miniconda3
SHELL ["/bin/bash", "-c"]
RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y parallel time make zlib1g zlib1g-dev
RUN mkdir /tools/
WORKDIR /tools/
RUN git clone https://github.com/cschin/Peregrine.git 
COPY install_peregrin.sh /tools/Peregrine/
RUN cd Peregrine && \
bash install_peregrin.sh
COPY environment.yml .
COPY install_whdenovo.sh /tools/
RUN bash /tools/install_whdenovo.sh

RUN apt-get install -y vim tree 
RUN apt-get install -y docker.io
RUN wget --no-check-certificate https://github.com/broadinstitute/picard/releases/download/2.20.2/picard.jar
RUN git clone https://github.com/shilpagarg/HapCUT2.git
RUN wget --no-check-certificate https://github.com/gt1/biobambam2/releases/download/2.0.87-release-20180301132713/biobambam2-2.0.87-release-20180301132713-x86_64-etch-linux-gnu.tar.gz
RUN tar -xvzf biobambam2-2.0.87-release-20180301132713-x86_64-etch-linux-gnu.tar.gz
RUN apt-get install -y libbz2-dev liblzma-dev libcurl4-gnutls-dev
RUN mkdir -p /root/.parallel
RUN touch /root/.parallel/will-cite
#run INSTALLATION.sh to install dependencies in Docker
#RUN chmod +x /INSTALLATION.sh && /INSTALLATION.sh
