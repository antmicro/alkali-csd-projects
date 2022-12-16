Host Software
=============

.. _host_software:

This chapter describes the software that will be used on the host PC.
The host software will communicate with the target platform using the NVMe interface.

It is located in :gh:`alkali-csd-projects/tree/main/host-app`.

Building the app
----------------

The host application is a simple C program that uses reads, writes and ioctls to communicate with the accelerator.
To build it, run:

.. code-block:: bash

   git clone https://github.com/antmicro/alkali-csd-projects.git
   cd alkali-csd-projects
   make host-app

To build the host application along with additional files needed to run an example, run:

.. code-block:: bash

   EXAMPLE=add make example/build

For more details check :gh:`Running examples section of alkali-csd-projects README <alkali-csd-projects#running-examples>`.

Using the app
-------------

The easiest way to use the application is to utilize the wrapper script which is located in the :gh:`alkali-csd-projects/tree/main/host-app` directory:

.. code-block:: bash

   cd host-app
   ./run.sh <path to NVMe device> <path to BPF source file> <input file> <output file>

The example of ADD operation can be executed with ``make`` in the root ``alkali-csd-projects``:

.. code-block:: bash

   EXAMPLE=add NVME_DEVICE=/dev/<nvmedevice> make example/load

Where:

* ``/dev/<nvmedevice>`` is the path to the NVMe accelerator,
* ``EXAMPLE`` is the example available under :gh:`alkali-csd-projects/tree/main/examples/tflite_vta/add`
* ``example/load`` is a target building the example and running the ``run.sh`` script to send data to process to the accelerator.

The results will be stored in ``build/examples/add/output.bin``.

The program that is running in the accelerator is :gh:`alkali-csd-projects/blob/main/examples/tflite_vta/add/bpf.c`.
It is a simple C file that contains the BPF program that will be built using `clang`.

It runs a sample :gh:`alkali-csd-projects/blob/main/examples/tflite_vta/add/model.tflite` TFLite model on VTA accelerator on input specified in the :gh:`alkali-csd-projects/blob/main/examples/tflite_vta/add/input-vector.bin`.
