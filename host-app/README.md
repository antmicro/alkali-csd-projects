NVMe host application
=====================

Copyright (c) 2021 [Antmicro](https://www.antmicro.com)

This repository contains host PC userspace application that is responsible for controlling the accelerator using NVMe commands.

Building
--------

To build this app you need to have GCC toolchain installed.
Once that is installed, you can build the app with:

    make

This should create a file `host-app`.

Usage
-----

Easiest way to use the app is to utilize the `run.sh` wrapper script:

    ./run.sh <path to NVMe device> <path to BPF source file> <input file> <output file>
