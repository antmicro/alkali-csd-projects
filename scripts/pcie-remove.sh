#!/bin/bash

# This script is used to remove the Alkali PCIe device from bus

DEVICE_ID=$(lspci | grep 'Western Digital Device 0001' | cut -d ' ' -f 1)
echo "1" | sudo tee /sys/bus/pci/devices/0000:${DEVICE_ID}/remove
