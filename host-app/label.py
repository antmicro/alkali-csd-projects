#!/usr/bin/env python3

import numpy as np
import argparse

import tensorflow as tf

parser = argparse.ArgumentParser()
parser.add_argument('label_file', help='File containing all class labels')
parser.add_argument('input_file', help='File produced from resnet run')
parser.add_argument('-m', '--model', help='TFLite model file', default=None)
args = parser.parse_args()

with open(args.label_file) as f:
    idx2label = eval(f.read())


if args.model is not None:
    data = np.fromfile(args.input_file, dtype='int8')
    with open(args.model, 'rb') as m:
        model = tf.lite.Interpreter(model_content=m.read())
        det = model.get_output_details()[0]
        scale, zero_point = det['quantization']
        data = (data - zero_point).astype('float32') * scale
else:
    data = np.fromfile(args.input_file, dtype='float32')

for i in np.argsort(-data)[:5]:
    print("{}: {}".format(idx2label[i], data[i]))
