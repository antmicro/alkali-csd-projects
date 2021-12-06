#!/usr/bin/env python3

import numpy as np
import argparse

parser = argparse.ArgumentParser()
parser.add_argument('label_file', help='File containing all class labels')
parser.add_argument('input_file', help='File produced from resnet run')
args = parser.parse_args()

with open(args.label_file) as f:
    idx2label = eval(f.read())

data = np.fromfile(args.input_file, dtype='float32')
data = data[:1000]

for i in np.argpartition(data, -5)[-5:]:
    print(idx2label[i])
