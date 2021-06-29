#!/bin/bash

set -x

clang -O2 -target bpf -c $2 -o bpf.o

touch $4

sudo ./host-app $1 bpf.o $3 $4

sleep 1

sudo ./host-app $1 bpf.o $3 $4

hexdump -C $3 > input.hex

hexdump -C $4 > output.hex
