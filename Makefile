# -----------------------------------------------------------------------------
# Common settings -------------------------------------------------------------
# -----------------------------------------------------------------------------

ROOT_DIR = $(realpath $(CURDIR))

# Input settings -------------------------------------------------------------

BOARD ?= basalt
BUILD_DIR ?= $(ROOT_DIR)/build
HW_BUILD_DIR ?= $(ROOT_DIR)/build/hardware
FW_BUILD_DIR ?= $(ROOT_DIR)/build/firmware

define UNSUPPORTED_BOARD_MSG
Boards $(BOARD) is not supported, choose one of following:
$(foreach BOARD, $(SUPPORTED_BOARDS),	- $(BOARD)
)
endef

SUPPORTED_BOARDS = zcu106 basalt
ifneq '$(BOARD)' '$(findstring $(BOARD),$(SUPPORTED_BOARDS))'
$(error $(UNSUPPORTED_BOARD_MSG))
endif

# Input paths -----------------------------------------------------------------

HW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-hw
FW_ROOT_DIR = $(ROOT_DIR)/alkali-csd-fw
THIRD_PARTY_DIR = $(ROOT_DIR)/third-party
BOARD_DIR = $(ROOT_DIR)/boards/$(BOARD)
FW_WEST_YML = $(FW_ROOT_DIR)/rpu-app/west.yml
WEST_CONFIG = $(ROOT_DIR)/.west/config
WEST_INIT_DIR = $(ROOT_DIR)

# Output paths ----------------------------------------------------------------

BOARD_BUILD_DIR = $(BUILD_DIR)/$(BOARD)
BUILDROOT_BUILD_DIR = $(BUILD_DIR)/firmware/buildroot/images
WEST_YML = $(FW_BUILD_DIR)/rpu-app/west.yml

# Helpers  --------------------------------------------------------------------

HW_MAKE_OPTS = BUILD_DIR=$(HW_BUILD_DIR)
FW_MAKE_OPTS = BUILD_DIR=$(FW_BUILD_DIR) WEST_CONFIG=$(WEST_CONFIG) \
	       WEST_YML=$(WEST_YML) WEST_INIT_DIR=$(BUILD_DIR)

# -----------------------------------------------------------------------------
# All -------------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: all
all: hardware/all
all: firmware/all ## Build all binaries for Hardware and Firmware

# -----------------------------------------------------------------------------
# Clean -----------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: clean
clean: ## Remove ALL build artifacts
	$(RM) -r $(BUILD_DIR)
	$(RM) -r $(ROOT_DIR)/.west

# -----------------------------------------------------------------------------
# Firmware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: firmware/all
firmware/all: $(WEST_YML) ## Build all Firmware binaries (Buildroot, APU App, RPU App)
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) all

.PHONY: firmware/clean
firmware/clean: ## Remove ALL Firmware build artifacts
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) clean

.PHONY: firmware/enter
firmware/enter: ## Enter firmware development docker image
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) enter

# Firmware rule forwarding depends on $(WEST_YML) to make sure that
# all zephyr and rpu-app targets work correctly
.PHONY: firmware//%
firmware//%: $(WEST_YML) ## Forward rule to invoke firmware rules directly e.g. `make firmware//apu-app`, `make firmware//buildroot//menuconfig`
	$(MAKE) -C $(FW_ROOT_DIR) $(FW_MAKE_OPTS) $*

$(WEST_YML): # Generate west.yml based on manifest from Firmware repository
	mkdir -p $(FW_BUILD_DIR)/rpu-app
	sed -e 's/path: build/path: build\/firmware/g' \
		-e 's/rpu-app/alkali-csd-fw\/rpu-app/g' $(FW_WEST_YML) > $(WEST_YML)

# -----------------------------------------------------------------------------
# Hardware --------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: hardware/all
hardware/all: ## Build all Hardware binaries (Vivado design)
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) all

.PHONY: hardware/clean
hardware/clean:
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) clean

.PHONY: hardware/enter
hardware/enter: ## Enter hardware development docker image
	$(MAKE) -C $(HW_ROOT_DIR) $(FW_MAKE_OPTS) enter

.PHONY: hardware//%
hardware//%: ## Forward rule to invoke hardware rules directly e.g. `make hardware//chisel`
	$(MAKE) -C $(HW_ROOT_DIR) $(HW_MAKE_OPTS) $*

# -----------------------------------------------------------------------------
# Build boot image ------------------------------------------------------------
# -----------------------------------------------------------------------------

$(BOARD_BUILD_DIR):
	mkdir -p $@

BOOTBIN_BUILD_DIR = $(BOARD_BUILD_DIR)/bootbin
$(BOOTBIN_BUILD_DIR):
	mkdir -p $@

SYSTEM_DTB = $(BUILDROOT_BUILD_DIR)/zynqmp-basalt-nvme.dtb
ROOTFS_CPIO = $(BUILDROOT_BUILD_DIR)/rootfs.cpio.uboot
LINUX_IMAGE = $(BUILDROOT_BUILD_DIR)/Image
BL31_ELF = $(BUILDROOT_BUILD_DIR)/bl31.elf
U_BOOT_ELF = $(BUILDROOT_BUILD_DIR)/u-boot

TOP_BIT = $(HW_BUILD_DIR)/$(BOARD)/project_vta/out/top.bit
TOP_XSA = $(HW_BUILD_DIR)/$(BOARD)/project_vta/out/top.xsa
BOOT_SCR = $(BOARD_BUILD_DIR)/boot.scr
BOOT_BIF = $(BOARD_DIR)/boot.bif
BOOT_CMD = $(BOARD_DIR)/boot.cmd
BOOT_BIN = $(BOOTBIN_BUILD_DIR)/boot.bin
FSBL_ELF = $(BOOTBIN_BUILD_DIR)/fsbl.elf
PMU_ELF = $(BOOTBIN_BUILD_DIR)/pmufw.elf

$(BOOT_BIN): $(FSBL_ELF)
$(BOOT_BIN): $(PMU_ELF)
$(BOOT_BIN): $(TOP_BIT)
$(BOOT_BIN): $(SYSTEM_DTB)
$(BOOT_BIN): $(BL31_ELF)
$(BOOT_BIN): $(U_BOOT_ELF)
$(BOOT_BIN): $(LINUX_IMAGE)
$(BOOT_BIN): $(ROOTFS_CPIO)
$(BOOT_BIN): $(BOOT_SCR)
$(BOOT_BIN): $(BOOT_BIF)
$(BOOT_BIN): | $(BOOTBIN_BUILD_DIR)
	stat $(FSBL_ELF) $(PMU_ELF) # already in the build directory (check `make fsbl`, `make pmufw`)
	cp $(TOP_BIT) $(BOOTBIN_BUILD_DIR)/.
	cp $(SYSTEM_DTB) $(BOOTBIN_BUILD_DIR)/system.dtb
	cp $(BL31_ELF) $(BOOTBIN_BUILD_DIR)/.
	cp $(U_BOOT_ELF) $(BOOTBIN_BUILD_DIR)/u-boot.elf
	cp $(LINUX_IMAGE) $(BOOTBIN_BUILD_DIR)/.
	cp $(ROOTFS_CPIO) $(BOOTBIN_BUILD_DIR)/.
	cp $(BOOT_SCR) $(BOOTBIN_BUILD_DIR)/.
	cd $(BOOTBIN_BUILD_DIR) && mkbootimage --zynqmp $(BOOT_BIF) $(BOOT_BIN)

.PHONY: boot-image
boot-image: $(BOOT_BIN) ## Build boot.bin

BUILDROOT_OUTPUTS = $(SYSTEM_DTB) $(ROOTFS_CPIO) $(LINUX_IMAGE) $(BL31_ELF) $(U_BOOT_ELF)
$(BUILDROOT_OUTPUTS) &:
	$(MAKE) firmware/all

HARDWARE_OUTPUTS = $(TOP_BIT) $(TOP_XSA)
$(HARDWARE_OUTPUTS) &:
	$(MAKE) hardware/all

$(BOOT_SCR):
	mkimage -c none -A arm -T script -d $(BOOT_CMD) $(BOOT_SCR)

# -----------------------------------------------------------------------------
# FSBL and PMUFW --------------------------------------------------------------
# -----------------------------------------------------------------------------

$(FSBL_ELF): $(TOP_XSA)
	BUILD_DIR=$(BOOTBIN_BUILD_DIR) XSA_FILE=$(TOP_XSA) make -C $(BOARD_DIR) fsbl

.PHONY: fsbl
fsbl: $(FSBL_ELF)

$(PMU_ELF): $(TOP_XSA)
	BUILD_DIR=$(BOOTBIN_BUILD_DIR) XSA_FILE=$(TOP_XSA) make -C $(BOARD_DIR) pmufw

.PHONY: pmufw
pmufw: $(PMU_ELF)

# -----------------------------------------------------------------------------
# SDCARD ----------------------------------------------------------------------
# -----------------------------------------------------------------------------

-include $(BOARD_DIR)/sdcard.mk

ifndef SDCARD_CONTENTS
$(error SDCARD_CONTENTS is not set. Please add sdcard.mk file to $(BOARD_DIR) directory)
endif

SDCARD_BUILD_DIR = $(BOARD_BUILD_DIR)/sdcard
$(SDCARD_BUILD_DIR):
	mkdir -p $@

SDCARD_OUTPUTS = $(addprefix $(SDCARD_BUILD_DIR)/, $(SDCARD_CONTENTS))
SDCARD_FILES = $(addprefix $(BOOTBIN_BUILD_DIR)/, $(SDCARD_CONTENTS))

$(SDCARD_OUTPUTS) &: | $(BOOT_BIN) $(SDCARD_BUILD_DIR)
	cp $(SDCARD_FILES) $(SDCARD_BUILD_DIR)/.

sdcard: $(SDCARD_OUTPUTS) ## Create build directory with SD card contents

# -----------------------------------------------------------------------------
# Help ------------------------------------------------------------------------
# -----------------------------------------------------------------------------

HELP_COLUMN_SPAN = 30
HELP_FORMAT_STRING = "\033[36m%-$(HELP_COLUMN_SPAN)s\033[0m %s\n"
.PHONY: help
help: ## Show this help message
	@echo Here is the list of available targets:
	@echo ""
	@grep -hE '^[^#[:blank:]]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf $(HELP_FORMAT_STRING), $$1, $$2}'
	@echo ""

.DEFAULT_GOAL := help
