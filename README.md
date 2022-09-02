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

To build this project it is recommended to use a dedicated docker image
with all the prerequisites installed. The image can be downloaded from
DockerHub using the following command:
```
docker pull antmicro/alkali
```
Alternatively, it can be built by invoking `make docker` command.

Use `make enter` to open the container and then execute the rest of
the commands inside it. If you want to bind `vivado` from outside
the container you have to provide a custom binding option, by setting the
`DOCKER_RUN_EXTRA_ARGS` environment variable before entering the container:
```
DOCKER_RUN_EXTRA_ARGS="-v <path-to-vivado-host>:<path-to-vivado-container>" make enter
```

# Building

**NOTE: You have to be in the dedicated docker container or have all
the prerequisites installed locally to use the instructions below correctly.
Refer to the [#Prerequisites](#prerequisites) section in case of any problems
with building the project**

Before building any target choose the desired board (`an300` or ` zcu106`),
by setting the `BOARD` environment variable:
```
export BOARD=an300
```

Then run the target that you want to compile. The list of targets is available
after running `make help`. To build all output products use:
```
make all
```

# Running examples

To run one of the examples on a board, you need to load the files generated in
the previous step to the board and initialize the system.

After that, you can load one of the tests from the `examples/` directory
to the given NVMe device, by using:

```
EXAMPLE=<example-name> NVME_DEVICE=/dev/<nvme-dev> load-example
```
For example:
```
EXAMPLE=add NVME_DEVICE=/dev/nvme1n1 load-example
```
