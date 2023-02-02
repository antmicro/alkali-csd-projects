.. _basalt_flashing:

Flashing and connecting the Basalt board
========================================

Flashing through NVMe interface
###############################

Using the `fw-download` and `fw-commit` commands you can flash new firmware to the onboard QSPI flash.

First you need to send the firmware file to the device with:

.. code-block:: bash

   sudo nvme fw-download <nvme device> --fw=<boot.bin file> --xfer=131072

And then trigger the flashing process with:

.. code-block:: bash

   sudo nvme fw-commit <nvme device>

After running the `fw-commit` command you need to monitor `apu-app` logs to determine when flashing completes.
Once completed then app prints out how much data was written:

.. code-block:: bash

   Writing 50856272 bytes of firmware to /dev/mtd0
   50856272 bytes written

Flashing via JTAG using Vivado
##############################

In case of anything going wrong and you cannot access Basalt via NVMe you can flash it via JTAG and Vivado

1. First you need to ensure that Basalt won't boot from QSPI because once it does the flashing will fail (Vivado hangs). There are two options available:

  a). Select JTAG boot mode

    To do this use the tiny dipsitches on the board, they should be accessible through a window in the cover. Set MODE to ``3'b000`` by turning on all of them (on = low).

  b). Erase the QSPI flash

    This is possible provided that you have access to the UART and at least U-Boot works. Interrupt the boot process by hitting enter in the UART console right after powering on the board (PCIe need not to be connected). Once you get an U-Boot prompt (it should say "ZynqMP>") issue the following commands to erase the flash completely:

    .. code-block::

      sf probe 0 0 0
      sf erase 0 0x8000000

  Once the flash is erased the board needs to be power cycled.

2. Vivado needs the ``BOOT.bin`` file as well as ``fsbl.elf`` separately. **Do not extract and use the FSBL from BOOT.bin as it won't work** But you can use the same FSBL that was used to created ``BOOT.bin``.

3. Connect a JTAG adapter compatible with Vivado to the J2 connector on the Basalt board.

4. Launch Vivado (tested with 2019.2 and 2021.2). It is best to do that from a terminal as during flashing it will output some progress information there which is not visible in GUI

5. Open a new HW target, You should see two "devices": ``xczu7_0`` and ``arm_dap_1``.

6. Right click the first one and select "Add configuration memory device". Select ``mt25ql01g-qspi-x4-single`` for the flash type (whether it is x1, x2 or x4 should not matter).

7. Point Vivado to the ``BOOT.bin`` file for Basalt as well as to the extracted ``fsbl.elf`` file.

8. Uncheck the "Erase" option (the flash has been already erased) and "Verify" (for speedup, unless you want to be absolutely sure that the flashing succeeds). Click "OK"

9. Vivado should start flashing which may take ~30min. In the terminal (used to run Vivado) you should see the following (or simial) output:

  .. code-block::

    Using default mini u-boot image file - ../Vivado/2021.2/data/xicom/cfgmem/uboot/zynqmp_qspi_x4_single.bin
    ===== mrd->addr=0xFF5E0204, data=0x00000222 =====
    BOOT_MODE REG = 0x0222
    Downloading FSBL...
    Running FSBL...
    ===== mrd->addr=0xFFD80044, data=0x00000000 =====
    ===== mrd->addr=0xFFD80044, data=0x00000003 =====
    Finished running FSBL.

    U-Boot 2021.01-00102-g43adebe (Oct 11 2021 - 01:44:06 -0600)
    
    Model: ZynqMP MINI QSPI SINGLE
    Board: Xilinx ZynqMP
    DRAM:  WARNING: Initializing TCM overwrites TCM content
    256 KiB
    EL Level:       EL3
    Multiboot:      16384
    In:    dcc
    Out:   dcc
    Err:   dcc
    ZynqMP> sf probe 0 0 0
    SF: Detected n25q00a with page size 256 Bytes, erase size 64 KiB, total 128 MiB
    ZynqMP> Sector size = 65536.
    sf write FFFC0000 0 20000
    device 0 offset 0x0, size 0x20000
    SF: 131072 bytes @ 0x0 Written: OK
    ZynqMP> sf write FFFC0000 20000 20000
    device 0 offset 0x20000, size 0x20000
    SF: 131072 bytes @ 0x20000 Written: OK

  The last three lines should continuously repead with increasing addresses.

10. Once the flashing is complete power cycle the board.

Connecting the board to the PC
##############################

For instructions on connecting the board to the PC follow :gh:`alkali-csd-projects README <alkali-csd-projects>`.
