# Helper directories ----------------------------------------------------------
SHELL:=/bin/bash
ROOT_DIR = $(realpath $(CURDIR))
BUILD_DIR ?= $(ROOT_DIR)/build
HW_BUILD_DIR ?= $(ROOT_DIR)/build/hardware
FW_BUILD_DIR ?= $(ROOT_DIR)/build/firmware
HW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-hw
FW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-fw

# Helper macros ---------------------------------------------------------------
FW_WEST_YML = $(FW_ROOT_DIR)/rpu-app/west.yml
WEST_YML = $(FW_BUILD_DIR)/rpu-app/west.yml
WEST_CONFIG = $(ROOT_DIR)/.west/config
RPUAPP_APP_DIR = alkali-csd-fw/rpu-app

HW_MAKEFILE = $(HW_ROOT_DIR)/Makefile
FW_MAKEFILE = $(FW_ROOT_DIR)/Makefile
HW_MAKE_OPTS = BUILD_DIR=$(HW_BUILD_DIR)
FW_MAKE_OPTS = BUILD_DIR=$(FW_BUILD_DIR) WEST_CONFIG=$(WEST_CONFIG) WEST_YML=$(WEST_YML) \
	RPUAPP_APP_DIR=$(RPUAPP_APP_DIR)


# -----------------------------------------------------------------------------
# All -------------------------------------------------------------------------
# -----------------------------------------------------------------------------

# All -------------------------------------------------------------------------
.PHONY: all
all: hardware/all
all: firmware/all ## Build all binaries for Hardware and Firmware


# -----------------------------------------------------------------------------
# Clean -----------------------------------------------------------------------
# -----------------------------------------------------------------------------

# Clean -----------------------------------------------------------------------
.PHONY: clean
clean: ## Remove ALL build artifacts
	$(RM) -r $(BUILD_DIR)


# -----------------------------------------------------------------------------
# Firmware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

# All -------------------------------------------------------------------------
.PHONY: firmware/all
firmware/all:  ## Build all Firmware binaries (Buildroot, APU App, RPU App)
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) all

# Clean -----------------------------------------------------------------------
.PHONY: firmware/clean
firmware/clean: ## Remove ALL Firmware build artifacts
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) clean

# Buildroot -------------------------------------------------------------------
.PHONY: firmware/buildroot
firmware/buildroot: ## Build Buildroot
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) buildroot

.PHONY: firmware/buildroot/distclean
firmware/buildroot/distclean: ## Remove Buildroot build
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) buildroot/distclean

.PHONY: firmware/buildroot/sdk
firmware/buildroot/sdk: ## Generate Buildroot toolchain
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) buildroot/sdk

.PHONY: firmware/buildroot/sdk-untar
firmware/buildroot/sdk-untar: ## Untar Buildroot toolchain (helper)
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) buildroot/sdk-untar

.PHONY: firmware/buildroot//%
firmware/buildroot//%: ## Forward rule to invoke Buildroot rules directly e.g. `make buildroot//menuconfig`
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) buildroot//$*

# APU App ---------------------------------------------------------------------
.PHONY: firmware/apu-app
firmware/apu-app: ## Build APU App
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) apu-app

.PHONY: firmware/apu-app/clean
firmware/apu-app/clean: ## Remove APU App build files
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) apu-app/clean

# RPU App ---------------------------------------------------------------------
.PHONY: firmware/rpu-app
firmware/rpu-app: $(WEST_YML) $(WEST_CONFIG) ## Build RPU App
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) rpu-app

.PHONY: firmware/rpu-app/with-sdk
firmware/rpu-app/with-sdk: $(WEST_YML) $(WEST_CONFIG) ## Build RPU App with local Zephyr SDK (helper)
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) rpu-app/with-sdk

.PHONY: firmware/rpu-app/clean
firmware/rpu-app/clean: ## Remove RPU App build files
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) rpu-app/clean

$(WEST_YML): # Generate west.yml based on manifest from Firmware repository
	mkdir -p $(FW_BUILD_DIR)/rpu-app
	sed -e 's/path: build/path: build\/firmware/g' \
		-e 's/rpu-app/alkali-csd-fw\/rpu-app/g' $(FW_WEST_YML) > $(WEST_YML)

# Zephyr ----------------------------------------------------------------------
.PHONY: firmware/zephyr/sdk
firmware/zephyr/sdk: ## Install Zephyr SDK locally (helper)

.PHONY: firmware/zephyr/setup
firmware/zephyr/setup: ## Clone main zephyr repositories and modules

.PHONY: firmware/zephyr/clean
firmware/zephyr/clean: ## Remove Zephyr installed files
	$(RM) -r $(BUILD_DIR)/zephyr*

# Help ------------------------------------------------------------------------
.PHONY: firmware/help
firmware/help: ## Show Firmware help message
	make -f $(FW_MAKEFILE) $(FW_MAKE_OPTS) help


# -----------------------------------------------------------------------------
# Hardware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

# All -------------------------------------------------------------------------
.PHONY: hardware/all
hardware/all: ## Build all Hardware binaries (Vivado design)
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) all

# Clean -----------------------------------------------------------------------
.PHONY: hardware/clean
hardware/clean:
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) clean

# Vivado ----------------------------------------------------------------------
.PHONY: hardware/vivado
hardware/vivado: ## Build Vivado design
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) vivado

# Generate  -------------------------------------------------------------------
.PHONY: hardware/generate
hardware/generate: ## Generate register description in chisel
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) generate

# Chisel ----------------------------------------------------------------------
.PHONY: hardware/chisel
hardware/chisel: ## Generate verilog sources using chisel
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) generate

# Test  -----------------------------------------------------------------------
.PHONY: hardware/test
hardware/test: ## Run all tests
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) test

# Format  ---------------------------------------------------------------------
.PHONY: hardware/format
hardware/format: ## Format code
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) format

# Docker  ---------------------------------------------------------------------
.PHONY: hardware/docker
hardware/docker: ## Build development docker image
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) docker

# Enter  ----------------------------------------------------------------------
.PHONY: hardware/enter
hardware/enter: ## Enter development docker image
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) enter

# Help  -----------------------------------------------------------------------
.PHONY: hardware/help
hardware/help: ## Show Hardware help message
	make -f $(HW_MAKEFILE) $(HW_MAKE_OPTS) help


# -----------------------------------------------------------------------------
# Help ------------------------------------------------------------------------
# -----------------------------------------------------------------------------
HELP_COLUMN_SPAN = 30
HELP_FORMAT_STRING = "\033[36m%-$(HELP_COLUMN_SPAN)s\033[0m %s\n"
.PHONY: help
help: ## Show this help message
	@echo Here is the list of available targets:
	@echo ""
	@grep -E '^[^#[:blank:]]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf $(HELP_FORMAT_STRING), $$1, $$2}'
	@echo ""

.DEFAULT_GOAL := help
