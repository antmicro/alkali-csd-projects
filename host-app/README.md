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
    cmake .. -DTENSORFLOW_SOURCE_DIR=~/work/wd-nvme/new/wd-nvme-docker/tensorflow_src
    cmake --build . -j

This should create `host-app` and `tf-app` executables in the `build` directory.

Preparing input files
---------------------

Input images must be normalized before they can be used for inference.
For inputs this is covered by `normalize.py` that decodes the image, performs normalization and saves it as raw binary file:

    ./normalize.py <original input file> <normalized input> -m <model file>

In order to perform the inference on the Basalt platform the TFLite model needs to be included in the input file, hence you should run:

    cat <model file> <normalized input file> > <final input file>

You will also need to update `model_size` with size of the `.tflite` file used and `input_size`/`output_size` with tensor sizes of your model.
Those values are defined in your BPF file.

Usage
-----

Easiest way to use the app with the Basalt platform is to utilize the `run.sh` wrapper script:

    ./run.sh <path to NVMe device> <path to BPF source file> <final input file> <output file>

It is possible to generate a reference output that is calculated on the host machine using the `tf-app` application that uses the TFLite library:

    ./tf-app <model file> <normalized input file> <output file>


Processing Resnet outputs
-------------------------

Inputs and outputs used by the model must be processed.
The output files with results of the inference need to be processed in order read the results of the classification.
The `label.py` is used to convert weights into labels:

    ./label.py <labels text file> <output_file> -m <model name>

`-m` switch is used to retrieve quantization parameters from the model which are needed to prepare input/output data for `int8` models and to select `int8` as input/output format.
Without it, scripts will produce and consume `float32` data.
