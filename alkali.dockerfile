# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0

FROM debian:buster

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && apt-get install -y \
  bc \
  bison \
  build-essential \
  bzip2 \
  clang \
  cpio \
  curl \
  flex \
  gcc-8 \
  git \
  gperf \
  libcurl4-openssl-dev \
  libelf-dev \
  libffi-dev \
  libjpeg-dev \
  libncurses5-dev \
  libpcre3-dev \
  libssl-dev \
  libtinfo5 \
  libxtst6 \
  make \
  ninja-build \
  python3 \
  python3-pip \
  rsync \
  tcl \
  u-boot-tools \
  unzip \
  wget \
  x11-xserver-utils \
  xsltproc \
  && rm -rf /var/lib/apt/lists/*

# Install rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install CMake
RUN git clone -b v3.16.7 https://gitlab.kitware.com/cmake/cmake.git cmake && \
  cd cmake && \
  ./bootstrap --system-curl && \
  make -j$(nproc) && \
  make install && \
  cd - && \
  rm -rf cmake

# Install Python dependencies
COPY requirements.txt requirements.txt
COPY alkali-csd-fw/requirements.txt alkali-csd-fw/requirements.txt
COPY alkali-csd-fw/registers-generator/requirements.txt alkali-csd-fw/registers-generator/requirements.txt
RUN pip3 install -r requirements.txt
RUN rm requirements.txt alkali-csd-fw/requirements.txt alkali-csd-fw/registers-generator/requirements.txt

# Install Zephyr dependencies
RUN wget https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v0.10.3/zephyr-sdk-0.10.3-setup.run && \
  chmod +x zephyr-sdk-0.10.3-setup.run && \
  ./zephyr-sdk-0.10.3-setup.run -- -d /zephyr-sdk-0.10.3
RUN apt-get update && apt install --no-install-recommends -y \
  git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1
ENV ZEPHYR_TOOLCHAIN_VARIANT=zephyr
ENV ZEPHYR_SDK_INSTALL_DIR=/zephyr-sdk-0.10.3
RUN wget https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/64dbc3e610d79db74f3ff1395fc9b1bf891f73c2/scripts/requirements.txt && \
    pip3 install -r requirements.txt && \
    rm requirements.txt

# Install Chisel dependencies
RUN apt-get update && apt install -y default-jdk
RUN wget www.scala-lang.org/files/archive/scala-2.13.0.deb && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian all main" | tee /etc/apt/sources.list.d/sbt.list && \
    echo "deb https://repo.scala-sbt.org/scalasbt/debian /" | tee /etc/apt/sources.list.d/sbt_old.list && \
    curl -sL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x2EE0EA64E40A89B84B2DF73499E82A75642AC823" | apt-key add && \
    apt update && \
    dpkg -i scala*.deb && \
    apt install -y sbt=1.4.9 && \
    rm scala-2.13.0.deb

# Install mkbootimage
RUN git clone https://github.com/antmicro/zynq-mkbootimage.git && \
  cd zynq-mkbootimage && \
  make -j$(nproc) && \
  mv mkbootimage /opt/. && \
  mv exbootimage /opt/.
ENV PATH=${PATH}:/zynq-mkbootimage

# Aarch64 bare-metal toolchain
RUN wget https://developer.arm.com/-/media/Files/downloads/gnu-a/10.3-2021.07/binrel/gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz && \
  tar xJf gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf.tar.xz -C / && \
  cp -r gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf/* / && \
  rm -rf gcc-arm-10.3-2021.07-x86_64-aarch64-none-elf/*

# Install make 4.3
RUN wget https://ftp.gnu.org/gnu/make/make-4.3.tar.gz && \
  tar xf make-4.3.tar.gz && \
  cd make-4.3 && \
  ./configure && \
  make -j$(nproc) && \
  cp make /opt/. && \
  cd - && \
  rm -rf make-4.3*
ENV PATH="/opt:${PATH}"
