#!/bin/bash

# This script is used to bind the Alkali NVMe device

DEVICE_ID=$(lspci | grep 'Western Digital Device 0001' | cut -d ' ' -f 1)
sudo sh -c "echo -n \"0000:${DEVICE_ID}\" > /sys/bus/pci/drivers/nvme/bind"
