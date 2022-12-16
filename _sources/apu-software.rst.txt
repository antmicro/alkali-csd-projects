APU Software
============

This chapter describes the software that will be running on the APU (A53 cores) part of the Zynq US+ MPSoC.
The APU software is responsible for processing the custom NVMe commands.

The firmware is available under :gh:`alkali-csd-fw`.

Building the APU software
-------------------------

To build the system and necessary software, follow :gh:`alkali-csd-fw README <alkali-csd-fw/tree/main>`.

APU base system
---------------

`Linux Kernel linux-xlnx <https://github.com/xilinx/linux-xlnx>`_ is used as the operating system for the APU.
`Buildroot <https://buildroot.org/>`_ is used to build all dependencies and utilities for the APU and creates rootfs.

The rootfs contains basic set of system utilities, APU and RPU applications.

uBPF Virtual Machine
--------------------

:gh:`uBPF Virtual Machine <ubpf/tree/61725ce189f65f8e9cf10985d5932dac9aa3b861>` a user space software allowing execution of a BPF programs.
the uBPF library is integrated with the APU application and is used to execute BPF payloads sent from the host.
The capabilities of BPF programs can be easily extended by adding external functions that can be called from the BPF binary.
Such functions are implemented in :gh:`alkali-csd-fw/tree/main/apu-app/src/vm`.

Currently, the BPF programs allow to delegate inference of TFLite models to the VTA delegate.

The example of such program is :gh:`ADD runner in alkali-csd-projects project <alkali-csd-projects/blob/main/examples/tflite_vta/add/bpf.c>`.

Userspace custom NVMe command handler
-------------------------------------

Userspace application is used to handle custom Accelerator-related NVMe commands.
Communication with firmware running on the RPU is achieved by using `rpmsg <https://www.kernel.org/doc/Documentation/rpmsg.txt>`_.
All vendor specific commands detected by the firmware are passed through to this application.

The application is available in :gh:`alkali-csd-fw/tree/main/apu-app`.

.. _zcu_commands:

Adding support for new NVMe commands
++++++++++++++++++++++++++++++++++++

Adding support for additional commands is fairly simple.
Commands are dispatched by ``handle_adm_cmd`` and ``handle_io_cmd`` functions located in :gh:`alkali-csd-fw/blob/main/apu-app/src/cmd.cpp`.
To handle another command, simply expand the ``switch`` responsible for calling handlers by calling your new handler and then ``send_ack`` with proper ACK type (``PAYLOAD_ACK_DATA`` when command returns data, ``PAYLOAD_ACK`` otherwise).
Buffer with the command will be provided using ``recv`` and ``mmap_buf`` represents buffer for data transferred to or from host.
