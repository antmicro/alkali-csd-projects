#!/usr/bin/env python3

import numpy as np
from PIL import Image as im
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('input_file', help='input image to be normalized')
parser.add_argument('output_file', help='ouptut path for normalized image')
args = parser.parse_args()

data = np.array(im.open(args.input_file).resize((224, 224))).astype('float32')

print(type(data))
print(data.shape)

data -= np.mean(data, axis=(0, 1))
data /= np.std(data, axis=(0, 1))

data.tofile(args.output_file)
