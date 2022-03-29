###########################################################
# base image, used for build stages and final images
FROM ubuntu:20.04 as base
ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir /opt/arm
WORKDIR /opt/arm

COPY ./scripts/add-ppa.sh /root/add-ppa.sh

# setup Python virtualenv and gnupg/wget for add-ppa.sh
RUN \
    apt update -y && \
    apt upgrade -y && \
    apt install -y --no-install-recommends \
        wget \
        build-essential \
        libcurl4-openssl-dev \
        libssl-dev \
        gnupg \
        gosu \
        libudev-dev \
        udev \
        python3 \
        python3-dev \
        python3-pip \
        python3-wheel \
        python-psutil \
        python3-pyudev \
        nano \
        vim \
        && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*


###########################################################
# install deps for ripper
FROM base as deps-ripper
RUN \
    bash /root/add-ppa.sh ppa:mc3man/focal6 && \
    bash /root/add-ppa.sh ppa:heyarje/makemkv-beta && \
    bash /root/add-ppa.sh ppa:stebbins/handbrake-releases

RUN \
    apt update -y && \
    apt install -y --no-install-recommends \
        abcde \
        eyed3 \
        atomicparsley \
        cdparanoia \
        eject \
        ffmpeg \
        flac \
        glyrc \
        default-jre-headless \
        libavcodec-extra \
        udev \
        libudev-dev \
        && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*

# install python reqs
COPY requirements.txt /requirements.txt
RUN \
    apt update -y && \
    apt install -y --no-install-recommends \
    && \
    pip3 install --upgrade pip wheel setuptools psutil pyudev \
    && \
    pip3 install --ignore-installed --prefer-binary -r /requirements.txt \
        && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*

# install libdvd-pkg
RUN \
    apt update -y && \
    apt install -y --no-install-recommends libdvd-pkg && \
    dpkg-reconfigure libdvd-pkg && \
    apt clean -y && \
    rm -rf /var/lib/apt/lists/*


###########################################################
# Final image pushed for use
FROM deps-ripper as arm-dependencies

# install makemkv and handbrake
RUN \
    apt update -y && \
    apt install -y --no-install-recommends \
        rsyslog \
        handbrake-cli \
        makemkv-bin \
        makemkv-oss \
    && \
    rm -rf /var/lib/apt/lists/*

RUN sed -i '/imklog/s/^/#/' /etc/rsyslog.conf

# reset to default after build
ENV DEBIAN_FRONTEND=newt

# set metadata
LABEL org.opencontainers.image.source=https://github.com/shitwolfymakes/arm-dependencies
LABEL org.opencontainers.image.license=MIT
LABEL org.opencontainers.image.revision="1.0"
