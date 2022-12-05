TensorFlow Lite model preparation
=================================

This chapter describes the preparation and conversion process of models to the TensorFlow Lite FlatBuffers format.

TensorFlow Lite models and runtime
----------------------------------

The framework used for running inference in the :doc:`APU software <apu-software>` is `TensorFlow Lite <https://www.tensorflow.org/lite>`_.
TensorFlow Lite provides:

* a compiler for optimizing and converting the TensorFlow model to the `.tflite` model,
* an interpreter and runtime for running the model.

The TFLite models are represented and stored in a `FlatBuffers format <https://google.github.io/flatbuffers/>`_.
The interpreter loads the model from file, and upon invoking it runs the inference.

In TensorFlow Lite, it is possible to run all or some of the model operations (matrix multiplication, convolution, vector operations and more) on an accelerator using `TFLite Delegates <https://www.tensorflow.org/lite/performance/delegates>`_.
Delegates are libraries that tell if the current operation during runtime can be executed on the accelerator instead of the CPU (in this case APU), and if so they also implement the communication of the host (APU) with the target in order to delegate the operation and receive results.

In this project, the APU has a delegate for the `Versatile Tensor Accelerator (VTA) <https://tvm.apache.org/docs/topic/vta/index.html>`_.
This accelerator computes the most popular operations present in the deep learning models, such as GEMM, MIN, MAX, ADD, MUL, operations on matrices and vectors.
The acceleration is performed on quantized models (with INT8 precision).

.. _test-models:

Test models used in development
-------------------------------

For the test purposes during development, models are generated in ONNX format using the :gh:`alkali-csd-fw/blob/main/apu-app/scripts/simple-models.py`.

.. _compiling-tflite-models:

Compiling the TensorFlow Lite models with examples
--------------------------------------------------

The detailed description on how to compile a TensorFlow model and get the ``.tflite`` file is present in `TensorFlow Lite Converter Overview <https://www.tensorflow.org/lite/convert>`_.

The models from :ref:`test-models` are compiled using random data as calibration dataset in the :gh:`alkali-csd-fw/blob/main/apu-app/scripts/convert-to-tflite.py`.
