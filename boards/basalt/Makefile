BOARD=basalt

ifndef BUILD_DIR
$(error BUILD_DIR is not set. Please provide path to build directory (e.g. BUILD_DIR=build))
endif

.PHONY: pmu
pmu: ## Copy prebuilt pmu.elf to build directory
	cp pmu.elf $(BUILD_DIR)/$(BOARD)

.PHONY: fsbl
fsbl: ## Copy prebuilt fsbl.elf to build directory
	cp fsbl.elf $(BUILD_DIR)/$(BOARD)
