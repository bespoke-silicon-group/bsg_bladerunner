# Build the shared Verilator simulator without an application's host defines.
# From bsg_bladerunner: gmake -f simulator.mk -j6 sim-exec sim-profile
include project.mk
REPLICANT_PATH := $(BSG_F1_DIR)
CL_DIR := $(REPLICANT_PATH)
BSG_PLATFORM ?= bigblade-verilator
VERILATOR_ROOT ?= $(BLADERUNNER_ROOT)/verilator
ifeq ($(shell uname -s),Darwin)
CC := /usr/bin/clang
CXX := /usr/bin/clang++
endif
DEFINES :=
include $(CL_DIR)/environment.mk
include $(EXAMPLES_PATH)/compilation.mk
include $(EXAMPLES_PATH)/link.mk
# The profile target records counters, not per-instruction traces.
VDEFINES += VERILATOR_WORKAROUND_DISABLE_VCORE_TRACE

.DEFAULT_GOAL := sim-exec
.PHONY: sim-exec sim-profile
sim-exec: $(BSG_MACHINE_PATH)/$(BSG_PLATFORM)/exec/simsc
sim-profile: $(BSG_MACHINE_PATH)/$(BSG_PLATFORM)/profile/simsc
