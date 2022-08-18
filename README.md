# Alkali Build System

This repository contains an automated build system for hardware (FPGA design)
and firmware of Western Digital NVMe accelerator test platform.

The Alkali Hardware repository is used to generate:
* bitstream
* hardware description file

The Alkali Firmware repository, on the other hand, is used to build:
* APU application
* RPU application
* U-Boot binaries
* Linux kernel
* Root filesystem image

Finally, the Alkali Build is responsible for generating FSBL and PMUFW
binaries from the hardware description file and generating Zynq boot image.

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

To build this project it is recommended to use a dedicated docker container
with all the prerequisites installed. The appropriate docker image can be
created using `alkali.dockerfile` provided in the `docker` directory.

Note that to build the image, you have to provide a tarball with Vivado 2019.2
installer. This file has to be placed in the
`docker/Xilinx_Vivado_2019.2_1106_2127.tar.gz` path before building the image.
It can be [downloaded](https://www.xilinx.com/member/forms/download/xef.html?filename=Xilinx_Vivado_2019.2_1106_2127.tar.gz)
from the Official Xilinx Website.

After placing the file in the specified location use `make docker` to build
the image. In case you want to install all the prerequisites directly on
your machine, follow the instructions from the `alkali.dockerfile`.

Use `make enter` to open the container and then execute the rest of
the commands inside it.

# Usage

**NOTE: You have to be in the dedicated docker container or have all
the prerequisites installed locally to use the instructions below correctly.
Refer to the [#Prerequisites](#prerequisites) section in case of any problems
with building the project**

Before building any target choose the desired board (`basalt` or ` zcu106`),
by setting the `BOARD` environment variable:
```
export BOARD=basalt
```

Then run the target that you want to compile. The list of targets is available
after running `make help`. To build all output products use:
```
make all
```

## Before publishing

**Note: Before making the alkali repositories public, it is necessary
to bind your ssh keys to the docker container to download
all the private repositories**

This can be done be setting `DOCKER_RUN_EXTRA_ARGS`:
```
export DOCKER_RUN_EXTRA_ARGS="-v ${HOME}/.ssh:${HOME}/.ssh"
```
