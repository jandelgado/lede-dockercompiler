FROM debian:8 
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list \
    && apt-get update \
    && apt-get -t jessie-backports install "gosu" \
    && apt-get install -y --no-install-recommends   \
               ca-certificates wget vim less \
               subversion g++ zlib1g-dev build-essential git python rsync \
               libncurses5-dev gawk gettext unzip file libssl-dev wget \
               bsdmainutils util-linux \
    && apt-get autoclean \
    && apt-get clean \
    && apt-get autoremove\
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /lede

WORKDIR "/workdir"

ADD usr/local/bin /usr/local/bin/
ADD home/ /lede

RUN chmod 755 /usr/local/bin/entrypoint.sh 

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

