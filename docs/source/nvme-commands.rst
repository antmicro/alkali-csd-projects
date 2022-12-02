NVMe commands and extensions
============================

This chapter discusses a proposal of the NVMe protocol with vendor-specific commands.
Custom commands are extending both Admin and I/O commands sets.
All the additional commands are encoded in the vendor-specific commands address space.

.. _basic_nvme_tests:

Basic NVMe operations
---------------------

To perform basic NVMe operations once the device gets probed successfully, you can use `nvme-cli <https://github.com/linux-nvme/nvme-cli>`_.
This tool allows you to send various commands to NVMe devices.

Currently supported commands are:

* `list`
* `list-subsys`
* `id-ctrl`
* `id-ns`
* `list-ns`
* `smart-log`
* `set-feature`
* `read`
* `write`
* `fw-download`
* `fw-commit`

.. _nvme_commands:

NVMe Vendor extensions
----------------------

In order to use the accelerator you need to be able to control it over NVMe interface.
The control functionality can be implemented with additional, vendor-specific commands.
This way the accelerator device will be compatible with generic NVMe software.
Custom software will be required to use the additional accelerator functionalities.
Some of the commands defined in the NVMe standard support vendor extensions which can
be used to implement basic features, e.g. retrieving accelerator logs.

Get Log Page (Log Page Identifier 0xC0)
+++++++++++++++++++++++++++++++++++++++

The get log page command returns a data buffer containing the log page for the specified accelerator.
The command returns a variable length buffer containing a list of status descriptors.

Accelerators are identified using numeric ID values. Accelerator ID is provided in the ``Log Specific Identifier`` field.
Bits 15:0 of the ``Log Specific Identifier`` field contain Accelerator ID.

Accelerator logs are packed into Log Entry descriptors.
The tables below contain the descriptors' structure:

.. csv-table:: Get Accelerator Log Page data structure
   :header: "Bytes", "Description"

   0:3, Log page length (in bytes)
   4:15, reserved for future use
   16:N, Accelerator log entry descriptor list

.. csv-table:: Accelerator Log Entry descriptor
   :header: "Bytes", "Description"

   0:3, Descriptor length (in bytes)
   4:11, Timestamp 
   12:15, Entry type ID
   16:N, Accelerator-specific information (optional)

The data inside the optional information block can be used to provide more information for the log entry, e.g. error message string.

Entry types are identified with unique IDs.
The exact ID list is to be defined.
Below is an example list:

.. csv-table:: Entry type IDs
   :header: "ID", "Descrption"

   0, Invalid firmware ID was selected
   1, Invalid input buffer configuration
   2, Invalid output buffer configuration
   3, Accelerator specific error

Custom NVMe commands
--------------------

Controlling accelerator-related features will require a set of custom commands on top of what NVMe provides.
The NVMe standard supports defining vendor-specific commands that use a separate range of opcodes.
The following sections lists custom (vendor-specific) commands extending the Admin and I/O sets.

Admin command set extension
+++++++++++++++++++++++++++

Custom admin commands will be used to obtain information about the device, status of the accelerators and will enable basic accelerator control.

The ``DPTR`` field of an NVMe command frame will be used to specify buffer location for commands that transfer data to or from the device.

Accelerator Identify (0xC2)
___________________________

The identify command returns a data buffer that describes information about the custom accelerators available in the device.
The command may also be used to determine if the connected device is an NVMe accelerator device.
The data structure has a variable length.
The length is determined by reading the first 8 bytes (confirming that the first 4 bytes hold the magic value).
Once the length is known, the whole buffer can be retrieved.

Accelerators are described using descriptors.
The tables below depict data structures used by the Accelerator Identify command.

.. csv-table:: Accelerators Idenfity descriptor structure
   :header: "Bytes", "Description"

   0:3, Magic value ("WDC\0")
   4:7, Descriptor length (in bytes)
   8:15, Reserved for future use
   16:N, Accelerator descriptor list

.. csv-table:: Accelerators descriptor list entry
   :header: "Bytes", "Descritpion"

   0:3, Accelerator descriptor length (in bytes)
   4:5, Accelerator ID (unique within the device)
   6:7, Reserved for future use
   8:N, Accelerator capabilities list

.. csv-table:: Accelerator capabilities list entry
   :header: "Bytes", "Description"

   0:3, Capability ID
   4:15, Capability specific data

Capabilities are identified with unique IDs.
The exact ID list is to be defined.
Below is an example list:

.. csv-table:: Capabilites IDs
   :header: "ID", "Descrption"

   0, Accelerator supports firmware exchange
   1, Accelerator supports input buffer of size defined in bytes 8:15 of the capability descriptor
   2, Accelerator supports output buffer of size defined in bytes 8:15 of the capability descriptor

Get Accelerator Status (0xC6)
_____________________________

The Get Accelerator Status command is used to retrieve information about the current status of the selected Accelerator available in the system.
The command returns a variable length buffer containing a list of status descriptors.

Accelerators are identified using numeric ID values. Accelerator ID will be provided in the ``CDW12`` field.
Bits 15:0 of the ``CDW12`` field contain Accelerator ID.
Bit 31 of the ``CDW12`` is the Retain Asynchronous Event (``RAE``) flag - when set to true, status information will not be modified until accessed with bit set as false.
This mechanism allows the host to read the header of the status data buffer, determine the length of the whole transaction and finally read the whole buffer.

Accelerators statuses are packed into Status descriptors.
Statuses are tied to accelerators capabilities, e.g. buffers can report how much data was processed.
The tables below summarize the descriptors' structure:

.. csv-table:: Get Accelerator Status data structure
   :header: "Bytes", "Description"

   0:3, Descriptor length
   4:7, Status ID 
   8:31, reserved for future use
   32:N, Accelerators status descriptors list

.. csv-table:: Accelerator status descriptor
   :header: "Bytes", "Description"

   0:3, Capability ID
   4:31, Status specific data

Global Accelerator Control (0xC0)
_________________________________

This Global Accelerator Control command is used to enable/disable accelerator subsystem.

``CDW12`` field contains operation ID.

Operation identifier will take one of the specified values:

* ``0x00`` - Enable accelerator subsystem
* ``0x01`` - Disable accelerator subsystem

I/O commands
++++++++++++

I/O commands are used to transfer data to and from the accelerators.

Bits 15:0 of the ``CDW12`` field contain Accelerator ID.

Send data to accelerator (0x81)
_______________________________

This command is used to fill accelerator input buffer with data from host memory.

``CDW10`` field contains the number of dwords to transfer.

Read data from accelerator (0x82)
_________________________________

This command is used to copy the accelerator output buffer to host memory.

``CDW10`` field contains the number of dwords to transfer.

Send Firmware to accelerator (0x85)
___________________________________

This command is used to upload firmware from the host memory to the selected accelerator firmware buffer.

``CDW10`` field contains the number of dwords to transfer.
``CDW13`` field contains Firmware ID.

Read Firmware from accelerator (0x86)
_____________________________________

This command is used to download firmware with selected ID from accelerator firmware buffer to host.

``CDW10`` field contains number of dwords to transfer.
``CDW13`` field contains Firmware ID.

Use local storage as accelerator input (0x88)
_____________________________________________

This command is used to fill accelerator input buffer with data from local storage.

This command reuse ``CDW10`` to ``CDW13`` field layout from standard ``Read`` command relocated to ``CDW12`` to ``CDW15``.
``CDW14`` and ``CDW15`` from original ``Read`` command will not be used.

Use local storage as accelerator output (0x8c)
______________________________________________

This command is used to copy accelerator output buffer to local storage.

This command reuse ``CDW10`` to ``CDW13`` field layout from standard ``Write`` command relocated to ``CDW12`` to ``CDW15``.
``CDW14`` and ``CDW15`` from original ``Write`` command will not be used.

Basic Accelerator Control (0x91)
________________________________

This Basic Accelerator Control command is used to control the selected accelerator.

The ``CDW13`` field will hold the operation identifier.

Operation identifier will take one of the specified values:

* ``0x00`` - Reset accelerator - revert the accelerator to a blank stopped state.
* ``0x01`` - Start accelerator - verify the accelerator configuration (i.e. data buffers, eBPF app) and start processing.
* ``0x02`` - Stop accelerator - stop processing without modifying the configuration.
* ``0x03`` - Set active firmware - select the firmware which will be 

More operations are to be defined.

The result of a certain operation can be retrieved with the ``Get Accelerator Status`` command.

``Start accelerator`` operation uses additional fields.

``DPTR`` field contains location of Argument List in host memory.
``CDW10`` field contains Argument List length in dwords.
``CDW14`` field contains Firmware ID.

Argument List will contain 0 or more concatenated entries.
The table below depicts Argument List entry.

.. csv-table:: Argument List entry
   :header: "Bytes", "Description"

   0:3, Argument entry length in bytes
   4:N, Argument entry value

Example command flow
--------------------

An example command flow that utilizes NVMe command set extensions is shown below.

#. Get basic information about the system:

   #. Send the ``Accelerator Identify`` command with the length set to 8 bytes.

      #. Verify that the first 4 bytes of the response match the magic value.
      #. Use the remaining 4 bytes as the Identify structure length.

   #. Send the ``Accelerator Identify`` command again using the length obtained earlier.
         
      #. Process the list of accelerators.
      #. Process the list of capabilities for each accelerator.

#. Enable accelerator subsystem

   #. Send the ``Global Accelerator Control`` command with the operation ID set to ``Enable accelerator subsystem``.

#. Load firmware to the accelerator (applicable only to accelerators supporting firmware reloading)

   #. Check accelerator capabilities to verify that firmware loading is supported. The host software should cache the capabilities, so that it does not have to read it each time.
   #. Send the ``Send Firmware to accelerator`` command.

      #. Use the ``accelerator ID`` field to select which accelerator will receive the firmware.
      #. Set the ``firmware ID`` to select firmware slot.

#. Send data to accelerator input buffer

   #. Check accelerator capabilities to get input buffer size and use that as the upper limit on input data size. The host software should cache the capabilities so that it does not have to read it each time.
   #. Use the ``accelerator ID`` field to select which accelerator will receive the data.
   #. Send the data using either

      * ``Send data to accelerator``, or
      * ``Use local storage as accelerator input``

#. Start processing

   #. Send the ``Basic Accelerator Control`` command.

      #. Use the ``accelerator id`` to select which accelerator should start.
      #. Set operation ID to ``Start accelerator``.
      #. Set the ``Firmware ID`` field to select firmware slot that should be used by the accelerator.
      #. Pack all the firmware arguments into the ``Argument List`` field
      #. Set correct list length and use ``DPTR`` to point to list location in memory.

#. Monitor accelerator status

   #. Send the ``Get Accelerator Status`` command with the length set to 4 bytes and ``RAE=1``.

      #. Use the ``Accelerator ID`` field to select the target accelerator.
      #. Use the returned value as the status structure length.

   #. Send the ``Get Accelerator Status`` command again using the retrieved length and ``RAE=0``.

      #. Check the ``Status ID`` field to see if the accelerator is still processing, is stopped or if an error has occurred.
      #. Use status descriptors to check capability-specific status information, e.g. the amount of output data produced for output data buffer capability.

#. Retrieve accelerator logs

   #. Send the ``Get Log Page`` command with ``Log Page Identifier = 0xC0``, ``RAE=1`` and the length set to 4 bytes.

      #. Use the ``Log Specific Identifier`` field to provide target accelerator ID.
      #. Use the returned value as the log page length.

   #. Send the ``Get Log Page`` command again using the retrieved length and ``RAE=0``.

      #. Process the log entry list.

#. Retrieve data from the accelerator output buffer

   #. Use the output data length obtained from ``Get Accelerator Status`` to see how much output data was produced.
   #. Transfer the data using either:

      * ``Read the data from accelerator``, or
      * ``Use the local storage as accelerator output``

