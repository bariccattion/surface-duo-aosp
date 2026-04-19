FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

RUN sed -i 's|http://archive.ubuntu.com|http://mirror.math.princeton.edu/pub/ubuntu|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|http://mirror.math.princeton.edu/pub/ubuntu|g' /etc/apt/sources.list && \
    dpkg --add-architecture i386 && \
    apt update && apt install -y \
    aapt \
    bc \
    bison \
    build-essential \
    curl \
    dos2unix \
    flex \
    fontconfig \
    g++-multilib \
    gcc-multilib \
    git \
    gnupg \
    gperf \
    imagemagick \
    jq \
    libncurses5 \
    libstdc++6 \
    libstdc++6:i386 \
    libxml2-utils \
    locales \
    lunzip \
    lzip \
    lzop \
    m4 \
    openjdk-17-jdk \
    python-is-python3 \
    python3-pip \
    rsync \
    simg2img \
    squashfs-tools \
    sudo \
    tree \
    unzip \
    wget \
    xattr \
    xmlstarlet \
    xsltproc \
    zip \
    zlib1g \
    zlib1g:i386 ; \
    apt clean autoclean ; \
    locale-gen en_US.UTF-8 && \
    dpkg-reconfigure locales

RUN curl https://storage.googleapis.com/git-repo-downloads/repo > /usr/local/bin/repo && \
    chmod a+x /usr/local/bin/repo

RUN curl https://packagecloud.io/install/repositories/github/git-lfs/script.deb.sh | bash && \
    apt update && apt install -y git-lfs && \
    git lfs install

RUN git config --global user.name "Surface Duo Builder" && \
    git config --global user.email "bariccatti@gmail.com" && \
    git config --global color.ui auto

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN mkdir -p /aosp/source /aosp/surface-duo-aosp

VOLUME /aosp/source
VOLUME /aosp/surface-duo-aosp

USER root
WORKDIR /aosp

ENTRYPOINT ["bash", "/aosp/surface-duo-aosp/build.sh"]
