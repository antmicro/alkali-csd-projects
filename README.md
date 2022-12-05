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

Start off with loading the Vivado environment:
```
source <path-to-vivado-container>/settings64.sh
```

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

# Flashing the SD card for ZCU106 board

In case the board runs from SD card (as in the case of the ZCU106 board), we can run:
```
make sdcard
```

This will create a directory `build/<target>/sdcard` directory with all files needed to run the project on the target.

To prepare the SD card for the system, plug it to the computer and determine its device handle (e.g. `/dev/sdX`, where `X` is the letter corresponding to the SD card).

**NOTE**: It is crucial to correctly determine the device, since the SD card will be wiped before placing files.

After this, run:

```
./scripts/format-sdcard.sh /dev/<devname>
```

And conduct the formatting process.

After formatting, there are two partitions:

* `boot` bootable FAT32 partition
* `root` EXT4 partition

Mount the FAT partition and copy the contents of the `build/<target>/sdcard` directory to this directory.

# Connecting the board to the computer

After flashing the boards, the remaining thing in order to use them is to connect them to the computer.

To connect and prepare the device for processing:

* Plug the board to a PCIe slot.
* Access the board's serial console, i.e. via `picocom` in PC (`NOTE:` there are more than a single serial console, for RPU, APU and more)
* Power on the board.
* Once the board is successfully booted, reboot the PC.
* After successful boot, check `lspci` for the device.
  Something as follows should be observed:
  ```
  $ lspci | grep -i western
  06:00.0 Non-Volatile memory controller: Western Digital Device 0001
  06:00.1 Serial controller: Western Digital Device 1234
  ```
* Via serial console, in the TTY with the buildroot prompt (APU), log in as `root` and run:
  ```
  /bin/reload.sh
  ```
* After this, on PC, in the directory with `alkali-csd-projects` run [./scripts/pcie-rescan.sh](./scripts/pcie-rescan.sh) and [./scripts/nvme-bind.sh](./scripts/nvme-bind.sh) scripts:
 ```
 ./scripts/pcie-rescan.sh
 ./scripts/nvme-bind.sh
 ```
* Use `nvme list` (from [nvme-cli](https://github.com/linux-nvme/nvme-cli)) to list available NVMe devices - the one with `DEADBEEF` identifier is the connected board, let's name it `/dev/<nvmedevice>`.

From this point it is possible to:

* [run the examples](#running-examples)
* Test the communication with the NVMe device using [./scripts/nvme-read-write-test.sh](./scripts/nvme-read-write-test.sh):
  ```
  $ ./scripts/nvme-read-write-test.sh /dev/<nvmedevice>
  Are you sure that you want to write to /dev/nvme0n1 (0123456789 DEADBEEF)?
  [Y]es/[N]o: Y
  1+0 records in
  1+0 records out
  1048576 bytes (1,0 MB, 1,0 MiB) copied, 0,00305868 s, 343 MB/s
  1+0 records in
  1+0 records out
  1048576 bytes (1,0 MB, 1,0 MiB) copied, 1,26125 s, 831 kB/s
  1+0 records in
  1+0 records out
  1048576 bytes (1,0 MB, 1,0 MiB) copied, 1,0398 s, 1,0 MB/s
  Test passed!
  ```

If the board is rebooted, restart the APU app using `/bin/reload.sh` in the serial console for APU's buildroot as described above, and reconnect the board to the PC using the following commands:

```
./scripts/pcie-remove.sh
./scripts/pcie-rescan.sh
```

The `./scripts/nvme-bind.sh` does not need to be executed again.

# Running examples

To run one of the examples on a board, you need to upload the files generated
in the previous step to the board and initialize the system. After that,
you can build and load one of the tests from the `examples/` directory to
the NVMe accelerator. To build the example, make sure that you are
**inside the docker container** and use the following command:
```
EXAMPLE=<example-name> make example/build
```
To load the example, make sure that you are **outside the docker container** and use:
```
EXAMPLE=<example-name> NVME_DEVICE=/dev/<nvme-dev> make example/load
```

For instance, if your NVMe accelerator is available as `/dev/nvme1n1`,
the following commands may be used to build and load the `add` example:

```bash
make enter                                              # enter the docker container
make all                                                # build all system components
EXAMPLE=add make example/build                          # build the example
exit                                                    # exit the docker container
EXAMPLE=add NVME_DEVICE=/dev/nvme1n1 make example/load  # upload the example to the board
```
