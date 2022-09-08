NVMe host application
=====================

Copyright 2021-2022 Western Digital Corporation or its affiliates
Copyright 2021-2022 Antmicro

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
