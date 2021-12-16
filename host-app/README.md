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

Preparing input file 
--------------------

TFLite model is included as part of the input file.

To create input file in correct format you can use:

    cat resnet50-int8.tflite input-data.bin > input.bin

You will also need to update `model_size` with size of the `.tflite` file used and `input_size`/`output_size` with tensor sizes of your model. 
Those values are defined in your BPF file.

Processing Resnet inputs/outputs (non-int8 model)
-------------------------------------------------

Inputs and outputs used by the model must be processed.

For inputs this is covered by `normalize.py` that decodes the image, performs normalization and saves it as raw binary file:

    ./normalize.py dog.jpg dog.bin

For outputs `label.py` is used to convert weights into labels:

    ./label.py imagenet1000_clsidx_to_labels.txt output.bin
