#!/bin/bash

# This script is used to scan for available PCIe devices

echo "1" | sudo tee /sys/bus/pci/rescan
