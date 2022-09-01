#!/bin/bash
# Copyright 2021-2022 Western Digital Corporation or its affiliates
# Copyright 2021-2022 Antmicro
#
# SPDX-License-Identifier: Apache-2.0


# This script is used to scan for available PCIe devices

echo "1" | sudo tee /sys/bus/pci/rescan
