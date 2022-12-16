RPU Software
============

This chapter describes the software that will be running on the RPU (R5 cores) part of the Zynq US+ MPSoC.
The RPU software will be responsible for handling the functionality required by the NVMe standard including regular read/write transactions.

Operating system
----------------

The RPU software uses `Zephyr RTOS <https://github.com/zephyrproject-rtos/zephyr>`_ as the operating system.

NVMe firmware overview
----------------------

The NVMe app runs from a reserved part of the APU DDR memory. The exact location of this area is specified in :ref:`rpu_memory`.
This space is used for the app itself as well as for various buffers needed to process the NVMe commands.
The app also uses a small chunk (60B) of memory at ``0x0`` to store reset and exception vectors, but that memory range is mapped into the TCM memory.

The debug output from RPU is provided on serial port 0.

The app contains custom drivers for the two peripherals implemented in the PL:

* Verilog-PCIe DMA core
* Custom NVMe register module, described in :ref:`nvme_ip`

Both of these peripherals generate interrupts when RPU attention is needed.
The NVMe register module generates an interrupt for each Host register write, and the DMA generates interrupts after finishing a transfer.

At the moment the app supports a minimal set of Admin commands sent by the NVMe Linux driver:

* Obtaining Identify Controller/Namespace structure with ``Identify``
* Obtaining SMART data structure using ``Get Log Page``
* Manipulating I/O Submission/Completion Queues with ``Create/Delete I/O Completion/Submission Queue``
* Configuring the amount of queues using ``Set Features``

I/O commands are also supported but for the moment support is minimal - all commands are marked as successful in theirs Completions.

This level of supported commands allows the drive to successfully register in the system and `nvme-cli <https://github.com/linux-nvme/nvme-cli>`_ can be used to perform basic operations, e.g. identifying the drive, dumping SMART data.
More details on that can be found in :ref:`basic_nvme_tests`.

Building and running NVMe firmware
----------------------------------

For building instructions follow :gh:`alkali-csd-fw README <alkali-csd-fw>`.

.. note:: It is recommended to build the whole project by following :gh:`alkali-csd-projects README <alkali-csd-projects>`.

.. _rpu_commands:

Adding support for new NVMe commands
------------------------------------

Adding support for additional commands is fairly simple.
Commands are dispatched by ``handle_adm`` and ``handle_io`` functions located in :gh:`alkali-csd-fw/blob/main/rpu-app/src/cmd.c`.
To handle a new one you simply need to add another entry in the ``switch`` block which calls handler for your command.
For example, this is how a handler for ``Write`` command is called:

.. code-block:: c

  case NVME_IO_CMD_WRITE:
      nvme_cmd_io_write(priv);
      break;

.. note::

    Commands can be also passed to APU for processing which is the case for FW update commands and vendor commands.
    You can get more information about handling them on the APU side in :ref:`zcu_commands`.

Once in handler, you will have access to a buffer with your command provided via ``priv`` variable.
You can use that to retrieve all needed command fields just like in this example:

.. code-block:: c

  typedef struct cmd_cdw10 {
          uint32_t fid : 8;
          uint32_t rsvd : 23;
          uint32_t sv : 1;
  } cmd_cdw10_t;

  typedef struct cmd_cdw14 {
          uint32_t uuid_idx : 7;
          uint32_t rsvd : 25;
  } cmd_cdw14_t;

  typedef struct cmd_sq {
          nvme_sq_entry_base_t base;
          cmd_cdw10_t cdw10;
          uint32_t cdw[3];
          cmd_cdw14_t cdw14;
  } cmd_sq_t;

  void nvme_cmd_adm_set_features(nvme_cmd_priv_t *priv)
  {
          cmd_sq_t *cmd = (cmd_sq_t*)priv->sq_buf;

          switch(cmd->cdw10.fid) {
                  case FID_NUMBER_OF_QUEUES:
                          number_of_queues(priv);
                          break;
                  default:
                          printk("Invalid Set Features FID value! (%d)\n", cmd->cdw10.fid);
          }

          nvme_cmd_return(priv);
  }

This snippet also shows another important point - all handlers must include ``nvme_cmd_return`` or ``nvme_cmd_return_data``.
Without that no NVMe response will be sent and the command will timeout.
