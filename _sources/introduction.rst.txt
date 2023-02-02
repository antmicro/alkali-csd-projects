Introduction
============

This document describes the Western Digital NVMe accelerators test platform.
The main goal of this project is to develop a proof of concept of an open source NVMe accelerator platform.
Initial work will be done using Xilinx ZCU106 platform and then it will be continued on the Basalt platform provided by Western Digital.

The document is divided into the following chapters:

  * :doc:`repositories` lists the repositories used for this project.
  * :doc:`architecture` contains information about the project's architecture, such as :doc:`fpga-design`, :doc:`host-software`, :doc:`apu-software` and :doc:`rpu-software`
  * :doc:`nvme-commands` describes in detail the extended NVMe command set developed as part of this project.
  * :doc:`tflite-models` describes the preparation and usage of TensorFlow Lite models.
  * :doc:`vta-accelerator` describes the VTA accelerator usage details.
  * :doc:`vta-delegated-ops` describes the implemented operations with the VTA delegate.
  * :doc:`flashing-basalt` describes how to flash firmware to QSPI using NVMe commands.

