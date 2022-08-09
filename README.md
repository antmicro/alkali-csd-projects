# Alkali build system

This repository contains an automated build system for hardware (FPGA design) and Firmware of Western Digital NVMe accelerator test platform.

## Repository structure

The diagram below presents the simplified structure of this repository along with its submodules.
```
.
├── alkali-csd-hw (submodule)
    └── ...
├── alkali-csd-fw (submodule)
    └── ...
├── Makefile
├── README.md
└── requirements.txt
```

# Prerequisites

To build the design you must have `Vivado 2019.2` binary available in your
system path. Additionally, you will need a few system packages which you can
install using the following commands:

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

There are many various options to run `make`. It includes all executable
targets from both Hardware and Firmware Makefile flows. These are prefixed with
`firmware/` and `hardware/` after which you should enter a command. To see all
available options, type `make help`.

It is recommended to build docker images for both parts using prepared
Dockerfiles:
```bash
make firmware/docker
make hardware/docker
```
Then you can enter them:
```bash
make firmware/enter # OR make hardware/enter
```

When you are in docker image, you should be able to build all required
components with correct build commands.

In case you are not able to install docker and you prefer to configure your
environment manually, just execute build targets directly on your machine
environment.
