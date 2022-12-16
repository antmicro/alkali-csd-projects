VTA accelerator
===============

This chapter covers the VTA accelerator - its model, structure, instructions and accessing.

.. note::

    The full specification of the VTA accelerator, along with examples can be found in `VTA Design and Developer Guide <https://tvm.apache.org/docs/topic/vta/dev/index.html>`_ in the Apache TVM documentation.

.. _vta-basic-information:

Basic information
-----------------

VTA (Versatile Tensor Accelerator) is a generic deep learning accelerator designed for efficient linear algebra calculations.
It is a simple RISC-like processor consisting of four modules:

* Fetch module - loads instruction streams from DRAM, decodes them and routes them to one of the following modules based on instruction type,
* Load module - loads data from shared DRAM with the host to VTA's SRAM for processing,
* Store module - stores data from VTA's SRAM to shared DRAM,
* Compute module - takes data and instructions from SRAM and computes micro-Op kernels containing ALU (add, sub, max, ...) and GEMM operations.

Both GEMM and ALU operations are performed on whole tensors of values.

The separate modules work asynchronously, which allows to hide memory access latency (loading new data and storing previous results while compute module processes current data).
The order of operations between all three modules is ensured with dependency FIFO queues.

Key parameters of the VTA accelerator
-------------------------------------

VTA is a configurable accelerator, where the computational and memory capabilities
are parameterized.

As mentioned in :ref:`vta-basic-information`, GEMM and ALU are operating on tensors.
The dimensionalities of those tensors are specified with the following parameters:

* ``VTA_BATCH`` - 1
* ``VTA_BLOCK_IN`` - 16
* ``VTA_BLOCK_OUT`` - 16

GEMM core computes the following tensors::

    out[VTA_BATCH * VTA_BLOCK_OUT] = inp[VTA_BATCH * VTA_BLOCK_IN] * wgt[VTA_BLOCK_IN * VTA_BLOCK_OUT]

It means that with the default settings the GEMM multiples 1x16-element input vector by 16x16 weight matrix and produces 1x16-element output vector.

ALU core computes the following tensors::

    out[VTA_BATCH * VTA_BLOCK_OUT] = func(out[VTA_BATCH * VTA_BLOCK_OUT], inp[VTA_BATCH * VTA_BLOCK_OUT])

It means that with the default settings the ALU core computes requested operation on 1x16 vectors.

Next, there are parameters controlling the number of bits in tensors:

* ``VTA_INP_WIDTH`` - number of bits for input tensor elements, 8
* ``VTA_OUT_WIDTH`` - number of bits for output tensor elements, 8
* ``VTA_WGT_WIDTH`` - number of bits for weights tensor elements, 8
* ``VTA_ACC_WIDTH`` - number of bits for accumulator (used in GEMM and ALU for storing intermediate results), 32
* ``VTA_UOP_WIDTH`` - number of bits representing micro-op data width, 32
* ``VTA_INS_WIDTH`` - length of a single instruction in VTA, 128

.. note:: The last parameter should not be modified

Another set of parameters configures buffer sizes (in bytes) for:

* ``VTA_INP_BUFF_SIZE`` - input buffer size, 32768 B
* ``VTA_OUT_BUFF_SIZE`` - output buffer size, 32768 B
* ``VTA_WGT_BUFF_SIZE`` - weights buffer size, 262144 B
* ``VTA_ACC_BUFF_SIZE`` - accumulator buffer size, 131072 B
* ``VTA_UOP_BUFF_SIZE`` - micro-op buffer size, 32768 B

The above parameters affect directly such aspects as:

* Data addressing in SRAM,
* Computational capabilities,
* Scheduling of operations.

VTA instructions
----------------

There are four instructions in VTA:

* ``LOAD`` - loads a 2D tensor from DRAM into the input buffer, weight buffer or register file, and micro-kernel into the micro-op cache.
* ``STORE`` - stores a 2D tensor from the output buffer to DRAM.
* ``GEMM`` - performs a micro-op sequence of matrix multiplications,
* ``ALU`` - performs a micro-op sequence of ALU operations.

The instructions have 128-bit length, storing both operation type and their parameters.

The structure of the VTA accelerator
------------------------------------

.. note:: More thorough documentation can be found in `VTA Design and Developer Guide`_.

As described in :ref:`vta-basic-information`, there are four modules - FETCH, LOAD, COMPUTE and STORE.

FETCH module receives instructions from DRAM, and forwards them to one of the other three modules.

Each of the modules work asynchronously, fetching the instructions from the fetch module and performing actions.

The API for communicating with the VTA via its driver implementation is provided in the :gh:`alkali-csd-fw/blob/main/apu-app/src/vta/vta_runtime.h`.

The following subsections will provide both high-level look at operations, as well as low-level functions used to implement them.

Shared DRAM between VTA and host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

To perform ``LOAD`` and ``STORE`` operation between the shared DRAM and VTA's SRAM modules, the shared (memory mapped) space needs to be allocated.

Managing shared buffers is done via ``VTABufferAlloc(size_t size)`` (allocating the memory mapped region) and ``VTABufferFree(void *bufferaddr)`` (releasing the memory mapped region).

LOAD/STORE modules
~~~~~~~~~~~~~~~~~~

``LOAD`` and ``STORE`` modules are responsible for passing data between shared DRAM and SRAM buffers in VTA.

They perform 2D transfers, allowing to apply padding and stride of the data on-the-fly.

.. warning::

    Some parameters in the below functions are going to have **in unit elements** disclaimer.
    It is the smallest tensor the SRAM can accept, and it depends on the SRAM type.
    The meaning of unit elements is specified in the :ref:`vta-memory-scheme`.

To load the data from DRAM to VTA's SRAM, the ``VTALoadBuffer2D`` method is used

.. code-block:: cpp

    VTALoadBuffer2D(
        VTACommandHandle cmd,
        void* src_dram_addr,
        uint32_t src_elem_offset,
        uint32_t x_size,
        uint32_t y_size,
        uint32_t x_stride,
        uint32_t x_pad_before,
        uint32_t y_pad_before,
        uint32_t x_pad_after,
        uint32_t y_pad_after,
        uint32_t dst_sram_index,
        uint32_t dst_memory_type);

Where:

* ``cmd`` - VTA command handle, created using ``VTATLSCommandHandle()``
* ``src_dram_addr`` - source DRAM address, allocated in shared space
* ``src_elem_offset`` - the source DRAM offset **in unit elements**
* ``x_size`` - the lowest dimension (x axis) size in **unit elements**
* ``y_size`` - the number of rows (y axis)
* ``x_stride`` - the x axis stride
* ``x_pad_before`` - start padding on x axis
* ``y_pad_before`` - start padding on y axis
* ``x_pad_after`` - end padding on x axis
* ``y_pad_after`` - end padding on y axis
* ``dst_sram_index`` - destination SRAM index
* ``dst_memory_type`` - destination memory type (memory types are specified in :ref:`vta-memory-scheme`)

To load the data from VTA's SRAM to DRAM, the ``VTAStoreBuffer2D`` method is used:

.. code-block:: cpp

    VTAStoreBuffer2D(
        VTACommandHandle cmd,
        uint32_t src_sram_index,
        uint32_t src_memory_type,
        void* dst_dram_addr,
        uint32_t dst_elem_offset,
        uint32_t x_size,
        uint32_t y_size,
        uint32_t x_stride);

Where:

* ``cmd`` - VTA command handle
* ``src_sram_index`` - the beginning location of the data in given SRAM, **in unit elements**
* ``src_memory_type`` - source memory type (memory types are specified in :ref:`vta-memory-scheme`)
* ``dst_dram_addr`` - pointer to DRAM memory
* ``dst_elem_offset`` - offset from the ``dst_dram_addr``
* ``x_size`` - size of the tensor on x axis **in unit elements**
* ``y_size`` - size of the tensor on y axis
* ``x_stride`` - stride along x axis

.. warning:: Only ``VTA_MEM_ID_OUT`` SRAM is supported as ``src_memory_type`` in ``VTAStoreBuffer2D``.

The above functions create 128-bit instructions that are passed to instruction fetch module, and later passed to ``LOAD``/``STORE`` modules.

COMPUTE module
~~~~~~~~~~~~~~

``COMPUTE`` module loads data from SRAM buffers - input, weight or accumulator buffers (more information in :ref:`vta-memory-scheme`), and performs either ``GEMM`` or ``ALU`` operations.

The instructions for COMPUTE module are wrapped in so-called micro-op kernels - a set of instructions applied on whole ranges of SRAM buffers.

The micro-op definition starts with specifying optional outer and inner loops, created using:

.. code-block:: cpp

    VTAUopLoopBegin(
        uint32_t extent,
        uint32_t dst_factor,
        uint32_t src_factor,
        uint32_t wgt_factor);

Where:

* ``extent`` - the extent of the loop, in other words the number of iterations for a given loop (outer or inner)
* ``dst_factor`` - the accum factor, is a factor by which the iterator is multiplied when computing address for ACC SRAM
* ``src_factor`` - the input factor, is a factor by which the iterator is multiplied when computing address for INP SRAM
* ``wgt_factor`` - the weight factor, is a factor by which the iterator is multiplied when computing address for WGT SRAM

The end of such loop is marked with ``VTAUopLoopEnd()``.
From the driver perspective, it changes the parameters of all ``VTAUopPush`` functions within the loop's scope.
All of those ``VTAUopPush`` are treated as list of micro-op instructions (``uop_instructions``), and those instructions along with loops are micro-op kernel.

The ``COMPUTE`` module instructions are created using:

.. code-block:: cpp

    VTAUopPush(
        uint32_t mode,
        uint32_t reset_out,
        uint32_t dst_index,
        uint32_t src_index,
        uint32_t wgt_index,
        uint32_t opcode,
        uint32_t use_imm,
        int32_t imm_val);

* ``mode`` - 0 (``VTA_UOP_GEMM``) for GEMM, 1 (``VTA_UOP_ALU``) for ALU
* ``reset_out`` - 1 if ACC SRAM in given address should be zeroed, 0 otherwise
* ``dst_index`` - the ACC SRAM base index
* ``src_index`` - the INP SRAM base index for GEMM, the ACC SRAM base index for second value for ALU
* ``wgt_index`` - the WGT SRAM base index
* ``opcode`` - ALU opcode, tells what operation is computed
* ``use_imm`` - tells if the immediate value ``imm_val`` should be used instead of tensor provided in ``src_index``
* ``imm_val`` - immediate value in ALU mode, applied as a second value in ALU operation

The ``imm_val`` immediate value is a 16-bit signed integer.

The GEMM operation pseudo-code looks as follows

.. code-block:: cpp

    for (e0 = 0; e0 < extent0: e0++)
    {
        for (e1 = 0; e1 < extent1; e1++)
        {
            for (instruction : uop_instructions)
            {
                src_index, wgt_index, dst_index = get_src_wgt_dst_indices(instruction);
                acc_idx = dst_index + e0 * dst_factor0 + e1 * dst_factor1;
                inp_idx = src_index + e0 * src_factor0 + e1 * src_factor1;
                wgt_idx = wgt_index + e0 * wgt_factor0 + e1 * wgt_factor1;
                ACC_SRAM[acc_idx] += GEMM(INP_SRAM[inp_idx], WGT_SRAM[wgt_idx]);
            }
        }
    }

And the ALU operation pseudo-code looks as follows

.. code-block:: cpp

    for (e0 = 0; e0 < extent0: e0++)
    {
        for (e1 = 0; e1 < extent1; e1++)
        {
            for (instruction : uop_instructions)
            {
                src_index, dst_index = get_src_dst_indices(instruction);
                acc_idx_1 = dst_index + e0 * dst_factor0 + e1 * dst_factor1;
                acc_idx_2 = src_index + e0 * src_factor0 + e1 * src_factor1;
                if (use_imm)
                {
                    ACC_SRAM[acc_idx1] = ALU_OP(ACC_SRAM[acc_idx1], imm_val);
                }
                else
                {
                    ACC_SRAM[acc_idx1] = ALU_OP(ACC_SRAM[acc_idx1], ACC_SRAM[acc_idx2]);
                }
            }
        }
    }

.. _vta-instructions:

VTA module synchronization mechanism
------------------------------------

The VTA ``LOAD``, ``STORE``, ``COMPUTE`` work asynchronously.
It allows to perform data loading, storing and computations in parallel, which makes latency hiding possible.

However, it requires proper synchronization mechanism so all instructions are executed in a correct order.
For this purpose, dependency queues are created.

There are four dependency queues:

* ``LOAD``->``COMPUTE`` dependency queue - tells ``COMPUTE`` module that data has finished loading and processing can start.
* ``COMPUTE``->``LOAD`` dependency queue - tells ``LOAD`` module that ``COMPUTE`` module has finished processing and new data can be loaded.
* ``STORE``->``COMPUTE`` dependency queue - tells ``COMPUTE`` module that computed data from ACC SRAM is stored in shared DRAM and can be overriden with new computations.
* ``COMPUTE``->``STORE`` dependency queue - tells ``STORE`` module that ``COMPUTE`` module has finished processing and data is ready to be stored in shared DRAM.

There are two methods for managing those dependency queues:

* ``VTADepPush(from, to)`` - for pushing a token of "readiness",
* ``VTADepPop(from, to)`` - for popping a "readiness" token from the given queue.
  If the token is not present, the module waits until ``VTADepPush`` pushes a new token.

This allows to control latency hiding and all of the algorithm's flow.

.. _vta-memory-scheme:

VTA memory/addressing scheme
----------------------------

VTA accelerator consists of several SRAM modules.
Each of them is characterized by three parameters:

* ``kBits`` - number of bits per element,
* ``kLane`` - number of lanes in a single element,
* ``kMaxNumElements`` - maximum number of elements.

There are following SRAM modules:

* UOP SRAM (``VTA_MEM_ID_UOP``) - memory for storing micro-op kernels' instructions,
* WGT SRAM (``VTA_MEM_ID_WGT``) - memory for storing weights,
* INP SRAM (``VTA_MEM_ID_INP``) - memory for storing inputs,
* ACC SRAM (``VTA_MEM_ID_ACC``) - accumulator memory, holding the intermediate results and ALU input tensors,
* OUT SRAM (``VTA_MEM_ID_OUT``) - provides the casted 8-bit values from the ACC SRAM.

.. list-table:: VTA memory types
    :header-rows: 1
    :align: center

    * - Memory type
      - ``kBits``
      - ``kLane``
      - ``kMaxNumElements``
    * - ``VTA_MEM_ID_WGT``
      - ``VTA_WGT_WIDTH`` (8)
      - ``VTA_BLOCK_IN * VTA_BLOCK_OUT`` (16 * 16)
      - ``VTA_WGT_BUFF_DEPTH`` (1024)
    * - ``VTA_MEM_ID_INP``
      - ``VTA_INP_WIDTH`` (8)
      - ``VTA_BATCH * VTA_BLOCK_IN`` (1 * 16)
      - ``VTA_INP_BUFF_DEPTH`` (2048)
    * - ``VTA_MEM_ID_ACC``
      - ``VTA_ACC_WIDTH`` (32)
      - ``VTA_BATCH * VTA_BLOCK_OUT`` (1 * 16)
      - ``VTA_ACC_BUFF_DEPTH`` (2048)
    * - ``VTA_MEM_ID_OUT``
      - ``VTA_OUT_WIDTH`` (8)
      - ``VTA_BATCH * VTA_BLOCK_OUT`` (1 * 16)
      - ``VTA_OUT_BUFF_DEPTH`` (2048)
    * - ``VTA_MEM_ID_UOP``
      - ``VTA_UOP_WIDTH`` (32)
      - 1
      - ``VTA_UOP_BUFF_DEPTH`` (8192)

``VTALoadBuffer2D`` can write to INP, WGT and ACC SRAMs.
``VTAStoreBuffer2D`` can read from OUT SRAM (not ACC SRAM).

.. warning:: It means that values need to be properly requantized and clamped to prevent overflows.
