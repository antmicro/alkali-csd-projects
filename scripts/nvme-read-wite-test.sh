#!/bin/bash
# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0


set -o pipefail

function help()
{
	echo "Usage nvme-read-wite-test.sh /dev/<nvme-dev>"
	echo "Test read-write operation on NVMe device"
}

if [ "$#" -ne 1 ]; then
	help
	exit 1
fi

NVME_DEVICE=$1
NVME_DEVICE_NAME="$(sudo nvme list | grep ${NVME_DEVICE} | cut -c 39-79 | xargs)"

echo -e "\033[0;33mAre you sure that you want to write to ${NVME_DEVICE} (${NVME_DEVICE_NAME})?\033[0m"
read -p $'\033[0;33m[Y]es/[N]o: \033[0m'
if [[ $REPLY =~ ^[Yy](es)?$ ]]
then
	REF_FILE=$(mktemp nvme-read-write-ref.XXXXXX)
	OUT_FILE=$(mktemp nvme-read-write-out.XXXXXX)

	dd if=/dev/urandom of=${REF_FILE} bs=1M count=1
	sudo dd if=${REF_FILE} of=${NVME_DEVICE} bs=1M count=1
	sudo dd if=${NVME_DEVICE} of=${OUT_FILE} bs=1M count=1
	cmp ${REF_FILE} ${OUT_FILE}

	EXIT_CODE=$?
	rm ${REF_FILE} ${OUT_FILE}
	if [ $EXIT_CODE -eq 0 ]; then
		echo -e "\033[0;32mTest passed!\033[0m"
	else
		echo -e "\033[0;31mTest failed!\033[0m"
	fi
	exit ${EXIT_CODE}
else
	echo -e "\033[0;33mQuiting without any changes\033[0m"
fi
