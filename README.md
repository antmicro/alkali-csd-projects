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

The repository contains a docker image which can be used to simplify
the process of installing dependencies. Before running other rules from
this repository make sure that you build the docker image by using:
```
make docker
```

For now, to enable the ability to build Vivado designs.
You have to use a custom base docker image with Vivado installed.
To specify the custom base set the `DOCKER_IMAGE_BASE` variable before
building the development image:
```
export DOCKER_IMAGE_BASE=debian-vivado-2019.2
make docker
```

In case you want to install all the prerequisites directly on your machine,
follow the instructions from the `Dockerfile`

# Usage

If you use docker workflow, use `make enter` to open the docker container
before running other commands.

**Note: Before making the alkali repositories public, it is necessary
to bind your ssh keys to the docker container to download
all the private repositories**

This can be done be setting DOCKER_RUN_EXTRA_ARGS:
```
export DOCKER_RUN_EXTRA_ARGS="-v ${HOME}/.ssh:${HOME}/.ssh"
```

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
