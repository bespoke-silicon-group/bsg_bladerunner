# Build the shared Verilator simulator without an application's host defines.
# From bsg_bladerunner: make -f simulator.mk -j24 sim-exec
# Replicant supplies sim-exec, sim-profile, sim-trace and sim-debug.
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
.DEFAULT_GOAL := sim-exec
