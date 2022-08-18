# -----------------------------------------------------------------------------
# Common settings -------------------------------------------------------------
# -----------------------------------------------------------------------------

ROOT_DIR = $(realpath $(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
BOARD=zcu106

# Input settings --------------------------------------------------------------

ifndef BUILD_DIR
$(error BUILD_DIR is not set. Please provide path to build directory (e.g. BUILD_DIR=build))
endif

ifndef XSA_FILE
$(error XSA_FILE is not set. Please provide path to XSA file (e.g. XSA_FILE=top.xsa))
endif

# Input paths -----------------------------------------------------------------

EMBEDDEDSW_DIR = $(realpath $(ROOT_DIR)/../../third-party/embeddedsw)
SCRIPTS_DIR = $(realpath $(ROOT_DIR)/../../scripts)

# Output paths ----------------------------------------------------------------

XSA_BUILD_DIR = $(BUILD_DIR)/xsa

EMBEDDEDSW_BUILD_DIR = $(BUILD_DIR)/embeddedsw
EMBEDDEDSW_BUILD_FSBL_SRC_DIR = $(EMBEDDEDSW_BUILD_DIR)/lib/sw_apps/zynqmp_fsbl/src
EMBEDDEDSW_BUILD_FSBL_BOARD_MISC_DIR = $(EMBEDDEDSW_BUILD_DIR)/lib/sw_apps/zynqmp_fsbl/misc/$(BOARD)
EMBEDDEDSW_BUILD_PMUFW_SRC_DIR = $(EMBEDDEDSW_BUILD_DIR)/lib/sw_apps/zynqmp_pmufw/src

FSBL_OUTPUT = $(BUILD_DIR)/fsbl.elf
PMUFW_OUTPUT = $(BUILD_DIR)/pmufw.elf

# -----------------------------------------------------------------------------
# All -------------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: all
all: pmufw fsbl

# create build directories ----------------------------------------------------

$(BUILD_DIR):
	@mkdir -p $(BUILD_DIR)

$(XSA_BUILD_DIR):
	@mkdir -p $(XSA_BUILD_DIR)

# -----------------------------------------------------------------------------
# Clean -----------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: clean
clean:
	$(RM) $(FSBL_OUTPUT) $(PMUFW_OUTPUT)
	$(RM) -r $(EMBEDDEDSW_BUILD_DIR)
	$(RM) -r $(XSA_BUILD_DIR)

# -----------------------------------------------------------------------------
# Embeddedsw ------------------------------------------------------------------
# -----------------------------------------------------------------------------

XSA_FILE_NAMES = \
	psu_init.c \
	psu_init_gpl.c \
	psu_init_gpl.h \
	psu_init.h \
	psu_init.html \
	psu_init.tcl

XSA_OUTPUTS = $(addprefix $(XSA_BUILD_DIR)/, $(XSA_FILE_NAMES))
$(XSA_OUTPUTS): | $(XSA_BUILD_DIR)
	unzip -o $(XSA_FILE) -d $(XSA_BUILD_DIR)

EMBEDDEDSW_ZCU106_OUTPUTS = $(addprefix $(EMBEDDEDSW_BUILD_FSBL_BOARD_MISC_DIR)/, $(XSA_FILE_NAMES))
$(EMBEDDEDSW_ZCU106_OUTPUTS): $(XSA_OUTPUTS) $(EMBEDDEDSW_BUILD_DIR)
	@echo EMBEDDEDSW_ZCU106_OUTPUTS=$(EMBEDDEDSW_ZCU106_OUTPUTS)
	cp $(XSA_OUTPUTS) $(EMBEDDEDSW_BUILD_FSBL_BOARD_MISC_DIR)/.

$(EMBEDDEDSW_BUILD_DIR): | $(BUILD_DIR)
	$(SCRIPTS_DIR)/copy_and_patch.py -f $(EMBEDDEDSW_DIR) $(EMBEDDEDSW_BUILD_DIR) -p $(ROOT_DIR)/embeddedsw.patch

# -----------------------------------------------------------------------------
# FSBL ------------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: fsbl
fsbl: $(FSBL_OUTPUT)

$(FSBL_OUTPUT): $(EMBEDDEDSW_ZCU106_OUTPUTS)
	$(MAKE) -C $(EMBEDDEDSW_BUILD_FSBL_SRC_DIR) BOARD=zcu106
	aarch64-none-elf-strip $(EMBEDDEDSW_BUILD_FSBL_SRC_DIR)/fsbl.elf
	cp $(EMBEDDEDSW_BUILD_FSBL_SRC_DIR)/fsbl.elf $@

# -----------------------------------------------------------------------------
# PMUFW -----------------------------------------------------------------------
# -----------------------------------------------------------------------------

.PHONY: pmufw
pmufw: $(PMUFW_OUTPUT)

$(PMUFW_OUTPUT): pmufw.elf
$(PMUFW_OUTPUT): | $(BUILD_DIR)
	cp pmufw.elf $(BUILD_DIR)/.
