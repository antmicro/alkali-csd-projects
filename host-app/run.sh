#!/bin/bash
# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0


HOSTAPP_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
REPO_ROOT=$(realpath "${HOSTAPP_DIR}/..")

HOSTAPP_BIN=$(realpath "${REPO_ROOT}/build/host-app/host-app")

set -o pipefail

function help()
{
	echo "Usage run.sh /dev/<nvme-dev> <bpf.o> <input.bin> <output.bin>"
	echo "Run tflite model on NVMe accelerator"
}

if [ "$#" -ne 4 ]; then
	help
	exit 1
fi

NVME_DEVICE=$1
BPF_OBJECT_FILE=$2
INPUT_BIN_FILE=$3
OUTPUT_BIN_FILE=$4

if [ ! -b "$NVME_DEVICE" ]; then
	echo "NVMe device not available"
	exit 1
fi

if [ ! -f "$BPF_OBJECT_FILE" ]; then
	echo "BPF file does not exist"
	exit 1
fi

if [ ! -f "$INPUT_BIN_FILE" ]; then
	echo "Input bin file does not exist"
	exit 1
fi

NVME_DEVICE_NAME="$(sudo nvme list | grep "${NVME_DEVICE}" | cut -c 39-79 | xargs)"
echo -e "\033[0;33mAre you sure that you want to use ${NVME_DEVICE} (${NVME_DEVICE_NAME})?\033[0m"
read -p $'\033[0;33m[Y]es/[N]o: \033[0m'
if [[ $REPLY =~ ^[Yy](es)?$ ]]
then
	sudo "${HOSTAPP_BIN}" "${NVME_DEVICE}" "${BPF_OBJECT_FILE}" "${INPUT_BIN_FILE}" "${OUTPUT_BIN_FILE}"
else
	echo -e "\033[0;33mQuiting without any changes\033[0m"
fi
