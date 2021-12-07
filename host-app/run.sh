#!/bin/bash

set -x

clang -O2 -target bpf -c $2 -o bpf.o

touch $4

sudo ./host-app $1 bpf.o $3 $4
