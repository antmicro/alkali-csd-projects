SHELL := /bin/bash

ROOT_DIR = $(realpath $(CURDIR))
BUILD_DIR ?= $(ROOT_DIR)/build
HW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-hw
FW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-fw
HW_MAKEFILE = $(HW_ROOT_DIR)/Makefile
FW_MAKEFILE = $(FW_ROOT_DIR)/Makefile

HW_FLAGS = BUILD_DIR=$(BUILD_DIR)

PHONY: all
all: build-hw

PHONY: build-hw
build-hw:
	make -f $(HW_MAKEFILE) $(HW_FLAGS) all

PHONY: clean
clean:
	make -f $(HW_MAKEFILE) $(HW_FLAGS) clean

PHONY: clean-hw
clean-hw:
	make -C $(HW_ROOT_DIR) clean
