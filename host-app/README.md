NVMe host application
=====================

Copyright (c) 2022 [Antmicro](https://www.antmicro.com)

This directory contains host PC userspace application that is responsible for
controlling the accelerator using NVMe commands.

Building
--------

To build this app you need to have CMake, GCC and Tensorflow sources on your PC.
Once that is read, you can build the app with:

    mkdir -p build && cd build
    cmake .. -DTENSORFLOW_SOURCE_DIR=<path-to-tensorflow>
    cmake --build . -j

This should create `host-app` and `tf-app` executables in the `build` directory.
