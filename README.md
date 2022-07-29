# Alkali build system

This repository contains an automated build system for hardware (FPGA design) and Firmware of Western Digital NVMe accelerator test platform.

## Repository structure

The diagram below presents the simplified structure of this repository along with its submodules.
```
.
├── alkali-csd-hw (submodule)
    └── ...
├── Makefile
├── README.md
└── requirements.txt
```

# Prerequisites

To build the design you must have `Vivado 2019.2` binary available in your
system path. Additionally, you will need a few system packages.
You can install them using the following commands:

```
sudo apt update -y
sudo apt install -y wget bc bison build-essential cpio curl default-jdk flex \
    g++-aarch64-linux-gnu gcc-aarch64-linux-gnu git gperf libcurl4-openssl-dev \
    libelf-dev libffi-dev libjpeg-dev libpcre3-dev libssl-dev make ninja-build \
    python3 python3-pip python3-sphinx rsync rustc unzip
```

Then, install the required python packages:
```
pip3 install -r requirements.txt
```

# Usage

To generate both hardware and firmware, just run:
```
make
```

If you want to specify which one to build then run:
1. `make build-fw` for firmware or
2. `make build-hw` for hardware.
