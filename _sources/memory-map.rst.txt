.. _memory_map:

Memory map
==========

Multiple memory areas are used in the system, this includes both register areas for IP cores and shared memory:

+-------------+---------+----------------+
| Base        | Size    | Name           |
+-------------+---------+----------------+
| 0x6000_0000 | 128 MiB | RPU FW area    |
+-------------+---------+----------------+
| 0x6800_0000 | 384 MiB | NVMe ramdisk   |
+-------------+---------+----------------+
| 0xA000_0000 | 64 KiB  | PCIe DMA IP    |
+-------------+---------+----------------+
| 0xA001_0000 | 64 KiB  | NVMe IP        |
+-------------+---------+----------------+
| 0xB000_0000 | 4 KiB   | VTA Fetch IP   |
+-------------+---------+----------------+
| 0xB000_1000 | 4 KiB   | VTA Load IP    |
+-------------+---------+----------------+
| 0xB000_2000 | 4 KiB   | VTA Compute IP |
+-------------+---------+----------------+
| 0xB000_3000 | 4 KiB   | VTA Store IP   |
+-------------+---------+----------------+

.. _nvme_cores:

PCIe and NVMe Cores
-------------------

Location of PCIe and NVMe cores in memory map is set in Vivado design located in :gh:`alkali-csd-hw/tree/main/vivado`.
After making changes to their addresses you need to adjust :gh:`nvme.overlay for RPU firmware <alkali-csd-fw/blob/main/rpu-app/nvme.overlay>` to contain correct base addresses.

.. _vta_cores:

VTA Cores
---------

Location of VTA cores in memory map is set in Vivado design located in :gh:`alkali-csd-hw/tree/main/vivado`.
After making changes to their addresses you need to adjust :gh:`vta_params.hpp <alkali-csd-fw/blob/main/apu-app/src/vta/vta_params.hpp>` file used by the ``apu-app`` to contain correct base addresses.

.. _rpu_memory:

RPU-APU shared memory
---------------------

The main memory is shared between Linux running on the APU and Zephyr RTOS app running on the RPU.
To ensure that the two don't interfere with each other a memory range dedicated to the RPU needs to be defined.
It can then be used in Linux to reserve that part of the RAM and in Zephyr to limit size of the application and its buffers.
In both cases this is defined via the devicetree.

For RPU it is defined in :gh:`nvme.overlay <alkali-csd-fw/blob/main/rpu-app/nvme.overlay>` as ``sram0`` which represents area for the firmware.
In APU case it is declared in:

* an300 - ``zynqmp-an300-nvme.dts`` added in :gh:`alkali-csd-fw/blob/main/br2-external/common/patches/linux/0012-dts-add-an300-support.patch`
* zcu106 - ``zynqmp-zcu106-nvme.dts`` added in :gh:`lkali-csd-fw/blob/main/br2-external/common/patches/linux/0003-dts-add-separate-devicetree-for-NVMe-ZCU106.patch`

as ``reserved-memory``.

Ramdisk area
------------

Ramdisk is also located in the main memory and is shared between Linux on the APU and Zephyr on the RPU.
For RPU it is defined in :gh:`nvme.overlay <alkali-csd-fw/blob/main/rpu-app/nvme.overlay>` as ``sram1``.
In APU case it is declared in ``zynqmp-basalt-nvme.dts`` as part of ``reserved-memory`` and you need to adjust :gh:`alkali-csd-fw/blob/main/apu-app/src/lba.h` in ``apu-app`` when changing ramdisk location in Zephyr.
To access a particular page you need to first calculate it's offset with ``(lba * RAMDISK_PAGE) + RAMDISK_BASE`` and then either use that address directly (in case of RPU) or MMAP it (on APU).

.. note::
    Accessing ramdisk area from the BPF code is achieved with help of ``Use local storage as accelerator input`` and ``Use local storage as accelerator output`` commands.
    Those commands take LBA value to calculate correct offset, MMAP it and then pass it as a pointer to your main BPF function.

