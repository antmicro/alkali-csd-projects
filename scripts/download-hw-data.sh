#!/bin/bash

# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0

function help()
{
	echo "Usage download-hw-data.sh <board> <hw-build-directory>"
	echo
	echo "Download prebuilt files from Alkali HW releases for a given <board>"
	echo "and copy them to a proper place inside the <hw-build-directory>"
}

if [ "$#" -ne 2 ]; then
	help
	exit 1
fi

BOARD=$1
BUILD_DIR=$2

LINK_TO_RELEASES=https://github.com/antmicro/alkali-csd-hw/releases/download/v1.0

BOARD_LOWERCASE=$(echo "${BOARD}" | tr '[:upper:]' '[:lower:]')
PREBUILD_NAME="${LINK_TO_RELEASES}/${BOARD_LOWERCASE}.zip"
DOWNLOAD_DIR="$(mktemp -d)"

wget -O "${DOWNLOAD_DIR}/data.zip" "${PREBUILD_NAME}"
unzip "${DOWNLOAD_DIR}/data.zip" -d "${DOWNLOAD_DIR}"
mkdir -p "${BUILD_DIR}/${BOARD}/project_vta/out"
cp "${DOWNLOAD_DIR}/${BOARD}"/* "${BUILD_DIR}/${BOARD}/project_vta/out"
