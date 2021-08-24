FROM ubuntu:18.04
LABEL maintainer "Jan Delgado <jdelgado@gmx.net>"

RUN apt-get update \
     && apt-get install -y  build-essential libncurses5-dev wget \
        zlib1g-dev gawk gcc-multilib flex git-core gettext libssl-dev unzip \
        python3 python3-distutils python rsync\
     && rm -rf /var/cache/apk/*  \
     && mkdir /workdir /lede

ADD home/ /lede
ADD usr/local/bin/entrypoint.sh /usr/local/bin/
RUN chmod 755 /usr/local/bin/entrypoint.sh

WORKDIR "/workdir"
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]

