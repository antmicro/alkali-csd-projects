Operations accelerated on VTA accelerator
=========================================

This chapter describes the currently supported TFLite operations on VTA accelerator.

TensorFlow Lite delegation scheme
---------------------------------

TensorFlow Lite allows to delegate certain operations to an accelerator using the Delegate API. It consists of:

* ``SimpleDelegateInterface`` - is executed during initialization of model runtime, it decides what operations should be delegated to the accelerator based on its capabilities.
* ``SimpleDelegateKernelInterface`` - is executed during inference, it implements the communication with the accelerator to compute and obtain results.

SimpleDelegateInterface
~~~~~~~~~~~~~~~~~~~~~~~

In the VTA delegate implementation, the ``VTADelegate`` class derives from ``SimpleDelegateInterface``.

This class requires implementing following methods:

* ``IsNodeSupportedByDelegate`` - this function decides whether the node (operation in the neural network model) can be delegated or not to the accelerator.
* ``Initialize`` - performs initialization actions for the delegation checker, not the accelerator itself.
* ``Name`` - returns the name of the delegate.
* ``CreateDelegateKernelInterface`` - creates an object inheriting from ``SimpleDelegateKernelInterface``.

``IsNodeSupportedByDelegate`` receives:

* ``registration`` data, such as ``builtin_code`` or ``custom_name``, telling the type of the operator (e.g. ``kTfLiteBuiltinAdd``, ``kTfLiteBuiltinConv2d``.
* ``node`` is a pointer to the current node that is being considered for delegation.
  It contains such data as indices for inputs, outputs, intermediate and temporary tensors (indices to tensors in ``context->tensors`` array)
* ``context`` - a TFLite context containing list and count of tensors in the model, execution plan and methods for getting and manipulating tensors.

It returns ``true`` when the node can be delegated, ``false`` otherwise.

In ``VTADelegate``, the currently supported operators are:

* ``kTfLiteBuiltinAdd`` - tensor addition of elements in 8-bit format.
* ``kTfLiteBuiltinConv2d`` - 2D convolution, with 8-bit inputs, kernels, outputs and 32-bit bias.

.. warning:: The support for ``kTfLiteBuiltinConv2d`` is not complete.

Adding a new operator to the delegate with 8-bit precision
----------------------------------------------------------

The neural network models usually operate using 32-bit floats, as required during the training process to train them efficiently.
However, VTA accelerator can only operate on quantized models, where weights and activations are 8-bit.

TensorFlow Lite provides methods for quantizing neural networks, as well as necessary parameters to infer quantized models during inference.

During the quantization process, the algorithm passes the calibration dataset through the neural network, and computes the following parameters for every tensor in the network (input tensors, output tensors, activation tensors, weights' tensors):

* ``scale`` - 32-bit float
* ``zero_point`` - 8-bit signed integer

During inference, the floating-point operations are simulated with integers using dequantization and requantization.
Dequantization is the process of representing quantized number in a higher-precision form (e.g. 32-bit integers representing fixed-point arithmetics, as in TensorFlow Lite). Requantization is a process of bringing higher precision values (e.g. 32-bit accumulators) to 8-bit representation.

The requantization (or rather quantization) and dequantization process includes inputs and outputs.

The formula for quantization with given ``scale`` and ``zero_point`` is following::

    Q(r) = int(s / scale) + zero_point

The dequantization, on the other hand, is computed as follows::

    D(q) = cast<type>(q - zero_point) * scale

Where ``type`` corresponds to the type after dequantization (in terms of network's outputs it is 32-bit float).

When it comes to operations within the neural network, each input tensor (activations, weights, ...) of the node (operation) needs to be dequantized, and the final output of a given node (operation) needs to be requantized.

What is more, to prevent overflows, the clamping of the outputs is performed on every outputs.

To sum up, the flow of every node should look as follow:

* Dequantize all input tensors
* Compute the operation on dequantized input tensors
* Requantize the output tensors (in higher precision)
* Clamp values in output tensors to range (the range may differ depending on the operator, usually it is the range of values in quantized values)
* Cast the output tensors to a target type
* Return the outputs.

The ``scale`` and ``zero_point`` parameters can be computed per-tensor, or per-channel.
The details which variant is used in a given operation is described in `TensorFlow Lite Quantization specification <https://www.tensorflow.org/lite/performance/quantization_spec>`_.

.. note::

    It is possible to simplify requantization/dequantization process for certain operations by simplifying formulas.

In TensorFlow Lite, since the operations are supposed to be quantized and scales are 32-bit floating points, they are firstly decomposed into a normalized fraction and an integral power of two (shift)::

    scale = multiplier * 2 ^ (shift)

E.g. for value 96 the multiplier is 0.75 and shift is 7.
The shift in TensorFlow Lite a 32-bit signed integer, and the multiplier is again 32-bit floating point value in range [0.5-1.0].

Secondly, the multiplier is multiplied by ``2 ^ 31`` and stored as a 32-bit Integer.

The above approach present in TensorFlow lite requires up to 64-bit registers during requantization when the 32-bit integer value (subtracted by zero point) is multiplied by 32-bit signed integer representing multiplier.

VTA accelerator cannot follow this scheme since the ACC SRAM has only 32-bit width.

To address this, the VTA delegate follows a customized approach where multiplier and shift are 16-bit signed integers instead of 32-bit signed integers.
This, in the peak processing requires 32-bit registers, which still fits in VTA capabilities.

To sum up, the computation of multiplier and shift looks as follows::

    q = frexp(scale, &shift32);
    q_fixed = round(q * (1 << 15));
    if (q_fixed == (1 << 15))
    {
        q_fixed /= 2;
        ++shift32;
    }
    multiplier = static_cast<int16_t>(q_fixed);
    shift = static_cast<int16_t>(shift32);

Dequantization of values is computed as follows::

    valoffset = offset + val; // max 7 bits required
    valshift = valoffset * (1 << left_shift); // ~15 bits required
    valscaledraw32 = valshift * multiplier; // ~32 bits required
    valscaled = (valscaledraw32 + nudge) >> 15; // ~16 bits required
    finval = valscaled >> -shift;

Left shift is a constant value equal to 7.
Nudge is a value used for rounding to nearest.

.. note:: The left shift is being embedded in the scaling factor.

Requantization of values is computed as follows::

    valscaled = val * qdata.multiplier;
    valshifted = valscaled >> (15 - qdata.shift);
    valoffset = valshifted + qdata.offset;
    valclamped = max(MIN, min(valoffset, MAX));

ADD operator
------------

The current implementation supports adding signed 8-bit integer tensors and returning signed 8-bit integer.
The operation can be represented as follows::

    (Y_q - z_y) * s_y = (A_q - z_a) * s_a + (B_q - z_b) * s_b
    Y_q = 1/s_y * [(A_q - z_a) * s_a + (B_q - z_b) * s_b] + z_y
    Y_q = s_yinv * [(A_q - z_a) * s_a + (B_q - z_b) * s_b] + z_y

Where:

* ``z_y``, ``s_y`` - zero point and scale for output tensor,
* ``z_a``, ``s_a`` - zero point and scale for 1st input tensor,
* ``z_b``, ``s_b`` - zero point and scale for 2nd input tensor,
* ``Y_q`` - quantized output,
* ``A_q`` - quantized 1st input,
* ``B_q`` - quantized 2nd input,
* ``s_yinv`` - inverted ``s_y``.

The aim is to compute ``Y_q``.

The scales are going through additional processing before converting to multipliers and shifts::

    doubled_max_scale = 2 * max(s_a, s_b);
    s_a' = s_a / doubled_max_scale;
    s_b' = s_b / doubled_max_scale;
    s_yinv' = doubled_max_scale / ((1 << left_shift) * s_y)

Usage of ``doubled_max_scale`` is to prevent having too small scales for 16-bit multipliers and shifts to store.

Firstly, the inputs are dequantized, so the above formula takes the following form::

    Y_q = s_yinv * [A' + B'] + z_y

.. warning::

    Current implementation performs dequantization on CPU.
    Those operations may need to be performed on VTA in the future to perform operations entirely on VTA.

The ``A'`` and ``B'`` are 16-bit signed integers that are passed to VTA's ACC SRAM buffer.
They are aligned to have size divisible by ``VTA_BATCH * VTA_BLOCK_OUT`` - those are the smallest units on which VTA performs ALU operations.

After this, the delegate sends the vectors of the following length::

    maxelements = VTA_ACC_BUFF_DEPTH / NUM_THREADS / 2 *  VTA_BLOCK_OUT

Where 2 stands for two input vectors to be stored in the ACC SRAM, and ``NUM_THREADS`` is a number of "threads" of processing in the VTA, can be either 1 or 2.

The idea of threading in VTA comes from asynchronous nature of ``LOAD``, ``STORE`` and ``COMPUTE`` modules - the ``COMPUTE`` module can process data while ``LOAD`` module handles data loading from DRAM and ``STORE`` module stores results in DRAM.
This approach is called latency hiding.
The "threading" is achieved by proper management of dependency queues between the modules.

To sum up, the ``LOAD`` module fills half of the SRAM based on which "thread" it works on, while the ``COMPUTE`` module processes the data on the other half of the SRAM.

The processing of ``COMPUTE`` module consists of following operations::

    A = A + B
    A = A * multiplier
    A = A >> (15 - shift)
    A = A + offset
    A = MIN(A, 128)
    A = MAX(A, -127)

After the above operations, the ACC SRAM contains the results that can safely be casted to 8-bit integers - it can be loaded using ``VTAStoreBuffer2D``.

The operation is repeated until all the elements in the input tensors are processed.

The implementation of the operation is present in ``alkali-csd-fw/apu-app/src/vta-delegate-ops.cpp``.

CONV2D operator
---------------

Two dimensional convolution in TensorFlow Lite for VTA takes 8-bit input, 8-bit weights, 32-bit bias and returns 8-bit outputs.
Weights are quantized symmetrically, which means that zero point for them equals 0.
Assuming ``x`` is a convolution operator, the operations look like this::

    (Y_q - z_y) * s_y = (s_w * W) x [s_i * (I - z_i)] + (s_b * B)
    (Y_q - z_y) * s_y = s_w * s_i * [W x (I - z_i)] + (s_b * B)

The quantization algorithm assures that ``s_b = s_w * s_i`` (approximately).
This leads to::

    (Y_q - z_y) * s_y = s_w * s_i * [W x (I - z_i) + B]
    Y_q = [(s_w * s_i) / s_y] * [W x (I - z_i) + B] + z_y

It means that convolution ``W x (I - z_i)`` can be performed without dequantization (values are 8-bit).
The result of convolution is 32-bit, to which the 32-bit bias is added.

The only floating-point parameter here is ``[(s_w * s_i) / s_y]`` - it can be applied at the very end of processing (only before adding ``z_y``).
For this parameter the multiplier and shift are computed.

When loading data from TensorFlow Lite, the first step is to convert the data to proper, VTA-compliant layout.

Layouts for convolution data are following:

* input: ``N I Hi Wi``
* weights: ``O I Hk Wk``
* output: ``N O Ho Wo``

Where:

* ``N`` - batch size,
* ``I`` - number of input channels,
* ``Hi`` - input height,
* ``Wi`` - input width,
* ``O`` - output channels,
* ``Hk`` - kernel height,
* ``Wk`` - kernel width,
* ``Ho`` - output height,
* ``Wo`` - output width.

The expected layouts by VTA are:

* input: ``N' I' Hi Wi n i``
* weights: ``O' I' Hk Wk o i``
* output: ``N' O' Ho Wo n o``

Where:

* ``n`` - subgroup of batch dimension of size ``VTA_BATCH`` (1),
* ``i`` - subgroup of input channels' dimension of size ``VTA_BLOCK_IN`` (16),
* ``o`` - subgroup of output channels' dimension of size ``VTA_BLOCK_OUT`` (16),
* ``N'`` - number of batch subgroups ``n``,
* ``I'`` - number of input channels subgroups ``i``,
* ``O'`` - number of output channels subgroups ``o``.

To convert data to this layout the original dimensions need to be:

* zero-padded so they are divisible by block computable by VTA
* rearranged so the data can be passed just for processing directly to VTA.

During convolution, for particular sample ``n``, input pixel ``(h,w)`` and particular kernel pixel ``(hk,wk)`` partial convolution result is computed for 16 input channels and 16 output channels (using 16x16 weights).

Current implementation assumes that:

* at least a single input row should fit into INPUT SRAM,
* at least a single kernel (for 16 output channels) should fit into WGT SRAM,
* at least for 16 output channels, full output row, needed biases, multipliers and shifts should fit into ACC SRAM.

The pseudocode for the current implementations is as follows::

    for each batch subgroup
        for each output channel subgroup
            LOAD weights for current output channels to WGT SRAM
            LOAD biases for current output channels to ACC SRAM
            LOAD multipliers for current output channels to ACC SRAM
            LOAD shifts for current output channels to ACC SRAM
            for each output row
                COMPUTE micro-op
                    VTAFOR output channels to compute
                        VTAFOR rows to compute
                            RESET outputs in ACC SRAM
                for each input channel subgroup
                    Load input row for given input channels to INP SRAM
                    COMPUTE micro-op
                        VTAFOR output channels to compute
                            VTAFOR rows to compute
                                for kernel rows
                                    for kernel cols
                                        RUN GEMM on data
                VTA ALU ADD bias to convolution output
                VTA ALU MUL outputs by scale multiplier
                VTA ALU SHR outputs by scale shift
                VTA ALU ADD zero_point to outputs
                Store partial outputs from OUT SRAM in DRAM

The implementation of the operation is present in ``alkali-csd-fw/apu-app/src/vta-delegate-ops.cpp``.

Further work
------------

* Finish testing CONV2D operator.
* Test and debug (if necessary) sequence of VTA operations.
* Load data with or without preprocessing depending on context (next VTA op vs loading data from TFLite context).
* Add loading padding and stride data from model's structure.
* Run and benchmark VTA accelerator on large network.

Resources
---------

* `TVM VTA Getting started guide <https://tvm.apache.org/docs/topic/vta/tutorials/vta_get_started.html#sphx-glr-topic-vta-tutorials-vta-get-started-py>`_
* `Example demonstrating sample IR code <https://tvm.apache.org/docs/topic/vta/tutorials/vta_get_started.html#alu-operations>`_
* `TFLite tutorial on delegate implementation <https://www.tensorflow.org/lite/performance/implementing_delegate>`_
* In :gh:`alkali-csd-fw repository <alkali-csd-fw>`, the sources regarding delegate provide lots of useful information regarding VTA, delegating system and quantization scheme, they are also documented:

    * ``apu-app/src/vta-delegate.hpp``
    * ``apu-app/src/vta-delegate.cpp``
    * ``apu-app/src/vta-delegate-ops.cpp``
    * ``apu-app/src/vta/sim_driver.cc``
