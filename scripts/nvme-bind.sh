#!/bin/bash
# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0


# This script is used to bind the Alkali NVMe device

DEVICE_ID=$(lspci | grep 'Western Digital Device 0001' | cut -d ' ' -f 1)
sudo sh -c "echo -n \"0000:${DEVICE_ID}\" > /sys/bus/pci/drivers/nvme/bind"
