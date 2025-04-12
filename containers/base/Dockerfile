FROM circleci/python:3.10

# Clone repositories and build bcftools
RUN cd ~ && \
    git clone --recurse-submodules https://github.com/samtools/htslib.git && \
    git clone https://github.com/samtools/bcftools.git && \
    cd bcftools && \
    autoheader && autoconf && ./configure prefix=$HOME && \
    make && \
    make install && \
    export BCFTOOLS_PLUGINS=~/bcftools/plugins/

# get tabix
RUN cd ~/htslib && \
    autoheader && \
    autoconf && \
    ./configure prefix=$HOME && \
    make && \
    make install


RUN pip install ga4gh.vrs[extras]@git+https://github.com/ga4gh/vrs-python.git@vcf-collection-memory && \
    pip install biocommons.seqrepo

RUN sudo apt-get update && sudo apt-get install -y rsync

CMD ["/bin/bash"]
