FROM python:3.10-slim

# Install dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        autoconf \
        automake \
        libtool \
        pkg-config \
        git \
        rsync \
        libncurses5-dev \
        libbz2-dev \
        liblzma-dev \
        zlib1g-dev \
        libcurl4-openssl-dev \
        ca-certificates \
        libpq-dev \
        rsync \
    && rm -rf /var/lib/apt/lists/*


# Clone repositories and build bcftools
RUN cd ~ && \
    git clone --recurse-submodules https://github.com/samtools/htslib.git && \
    git clone https://github.com/samtools/bcftools.git && \
    cd bcftools && \
    autoheader && autoconf && ./configure prefix=$HOME && \
    make && \
    make install && \
    cp bcftools /usr/local/bin && \
    export BCFTOOLS_PLUGINS=~/bcftools/plugins/

RUN pip install ga4gh.vrs[extras]~=2.1.0 && \
    pip install biocommons.seqrepo

CMD ["/bin/bash"]
