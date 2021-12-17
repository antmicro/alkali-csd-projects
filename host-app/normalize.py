#!/usr/bin/env python3

import numpy as np
from PIL import Image as im
import argparse

import tensorflow as tf

parser = argparse.ArgumentParser()
parser.add_argument('input_file', help='input image to be normalized')
parser.add_argument('output_file', help='ouptut path for normalized image')
parser.add_argument('-m', '--model', help='TFLite model file', default=None)
args = parser.parse_args()

img = im.open(args.input_file)
img = img.convert('RGB')
img = img.resize((224, 224))

npimg = tf.keras.applications.resnet50.preprocess_input(np.array(img).astype('float32'))

if args.model is not None:
    with open(args.model, 'rb') as m:
        model = tf.lite.Interpreter(model_content=m.read())
        det = model.get_input_details()[0]
        scale, zero_point = det['quantization']
        npimg = (npimg / scale).astype('int8') + zero_point

npimg.tofile(args.output_file)
