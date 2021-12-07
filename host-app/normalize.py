#!/usr/bin/env python3

import numpy as np
from PIL import Image as im
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('input_file', help='input image to be normalized')
parser.add_argument('output_file', help='ouptut path for normalized image')
args = parser.parse_args()

img = im.open(args.input_file)
img = img.convert('RGB')
img = img.resize((224, 224))
npimg = np.array(img).astype(np.float32) / 255.0

mean = np.mean(npimg, axis=(0, 1))
std = np.std(npimg, axis=(0, 1))

npimg = (npimg - mean) / std

npimg.tofile(args.output_file)
