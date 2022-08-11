BOARD ?= basalt

# Helper directories ----------------------------------------------------------
SHELL:=/bin/bash
ROOT_DIR = $(realpath $(CURDIR))
BUILD_DIR ?= $(ROOT_DIR)/build
HW_BUILD_DIR ?= $(ROOT_DIR)/build/hardware
FW_BUILD_DIR ?= $(ROOT_DIR)/build/firmware
HW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-hw
FW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-fw
THIRD_PARTY_DIR = $(ROOT_DIR)/third-party
BOARD_BUILD_DIR = $(BUILD_DIR)/$(BOARD)
BOARD_DIR = $(ROOT_DIR)/boards/$(BOARD)
SCRIPTS_DIR = $(BOARD_DIR)/scripts

# Helper macros ---------------------------------------------------------------
FW_WEST_YML = $(FW_ROOT_DIR)/rpu-app/west.yml
WEST_YML = $(FW_BUILD_DIR)/rpu-app/west.yml
WEST_CONFIG = $(ROOT_DIR)/.west/config
WEST_INIT_DIR = $(ROOT_DIR)

HW_MAKE_OPTS = BUILD_DIR=$(HW_BUILD_DIR)
FW_MAKE_OPTS = BUILD_DIR=$(FW_BUILD_DIR) WEST_CONFIG=$(WEST_CONFIG) \
	       WEST_YML=$(WEST_YML) WEST_INIT_DIR=$(BUILD_DIR)

# Check supported boards ------------------------------------------------------
define UNSUPPORTED_BOARD_MSG
Boards $(BOARD) is not supported, choose one of following:
$(foreach BOARD, $(SUPPORTED_BOARDS),	- $(BOARD)
)

endef

SUPPORTED_BOARDS =zcu106 basalt
ifneq '$(BOARD)' '$(findstring $(BOARD),$(SUPPORTED_BOARDS))'
$(error $(UNSUPPORTED_BOARD_MSG))
endif

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
	$(RM) -r $(ROOT_DIR)/.west


# -----------------------------------------------------------------------------
# Firmware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

# All -------------------------------------------------------------------------
.PHONY: firmware/all
firmware/all: $(WEST_YML) ## Build all Firmware binaries (Buildroot, APU App, RPU App)
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) all

# Clean -----------------------------------------------------------------------
.PHONY: firmware/clean
firmware/clean: ## Remove ALL Firmware build artifacts
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) clean

# Other -----------------------------------------------------------------------
.PHONY: firmware//%
firmware//%: ## Forward rule to invoke firmware rules directly e.g. `make firmware//apu-app`, `make firmware//buildroot//menuconfig`
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) $*

$(WEST_YML): # Generate west.yml based on manifest from Firmware repository
	mkdir -p $(FW_BUILD_DIR)/rpu-app
	sed -e 's/path: build/path: build\/firmware/g' \
		-e 's/rpu-app/alkali-csd-fw\/rpu-app/g' $(FW_WEST_YML) > $(WEST_YML)


# -----------------------------------------------------------------------------
# Hardware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

# All -------------------------------------------------------------------------
.PHONY: hardware/all
hardware/all: ## Build all Hardware binaries (Vivado design)
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) all

# Clean -----------------------------------------------------------------------
.PHONY: hardware/clean
hardware/clean:
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) clean

# Other -----------------------------------------------------------------------
.PHONY: hardware//%
hardware//%: ## Forward rule to invoke hardware rules directly e.g. `make hardware//chisel`
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) $*


# -----------------------------------------------------------------------------
# Build boot image ------------------------------------------------------------
# -----------------------------------------------------------------------------
SYSTEM_DTB = $(FW_BUILD_DIR)/linux-9c71c6e9/arch/arm64/boot/dts/xilinx/zynqmp-$(BOARD)-nvme.dtb
LINUX_IMAGE = $(FW_BUILD_DIR)/linux-9c71c6e9/arch/arm64/boot/Image
BL31_ELF = $(FW_BUILD_DIR)/arm-trusted-firmware-xilinx-v2019.2/build/zynqmp/release/bl31/bl31.elf
FSBL_ELF = $(BOARD_BUILD_DIR)/fsbl.elf
PMU_ELF = $(BOARD_BUILD_DIR)/pmufw.elf
TOP_BIT = $(HW_BUILD_DIR)/$(BOARD)/project_vta/out/top.bit
TOP_XSA = $(HW_BUILD_DIR)/$(BOARD)/project_vta/out/top.xsa
U_BOOT_ELF = $(FW_BUILD_DIR)/uboot-xilinx-v2019.2/u-boot.elf
BOOT_BIF = $(SCRIPTS_DIR)/$(BOARD)/boot.bif
BOOT_CMD = $(SCRIPTS_DIR)/$(BOARD)/boot.cmd
BOOT_BIN = $(BOARD_BUILD_DIR)/boot.bin
BOOT_SCR = $(BOARD_BUILD_DIR)/boot.scr
MKBOOTIMAGE = $(THIRD_PARTY_DIR)/zynq-mkbootimage/mkbootimage
U_BOOT_XLNX_DIR = $(THIRD_PARTY_DIR)/u-boot-xlnx
MKIMAGE = $(U_BOOT_XLNX_DIR)/tools/mkimage

.PHONY: boot-image
boot-image: $(BOOT_BIN) ## Build boot.bin

$(BOARD_BUILD_DIR):
	mkdir -p $@

$(BOARD_BUILD_DIR)/boot.bin: firmware/buildroot
$(BOARD_BUILD_DIR)/boot.bin: hardware/all
$(BOARD_BUILD_DIR)/boot.bin: $(MKBOOTIMAGE)
$(BOARD_BUILD_DIR)/boot.bin: $(BOOT_SCR)
$(BOARD_BUILD_DIR)/boot.bin: $(FSBL_ELF)
$(BOARD_BUILD_DIR)/boot.bin: $(PMU_ELF)
$(BOARD_BUILD_DIR)/boot.bin: | $(BOARD_BUILD_DIR)
	cp $(SYSTEM_DTB) $(LINUX_IMAGE) $(BL31_ELF) $(FSBL_ELF) $(PMU_ELF) $(TOP_BIT) $(U_BOOT_ELF) $(BOARD_BUILD_DIR)
	cd $(BOARD_BUILD_DIR) && $(MKBOOTIMAGE) --zynqmp $(BOOT_BIF) $(BOOT_BIN)

$(BOARD_BUILD_DIR)/boot.scr: $(MKIMAGE)
	$(MKIMAGE) -c none -A arm -T script -d $(BOOT_CMD) $(BOOT_SCR)

$(TOP_XSA):
	$(MAKE) hardware/all

$(FSBL_ELF): $(TOP_XSA)
	BUILD_DIR=$(BOARD_BUILD_DIR) XSA_FILE=$(TOP_XSA) make -C $(BOARD_DIR) fsbl

$(PMU_ELF): $(TOP_XSA)
	BUILD_DIR=$(BOARD_BUILD_DIR) XSA_FILE=$(TOP_XSA) make -C $(BOARD_DIR) pmufw

.PHONY: fsbl
fsbl: $(FSBL_ELF)

.PHONY: pmufw
pmufw: $(PMU_ELF)


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
