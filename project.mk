DEPENDENCIES           := bsg_manycore bsg_f1 basejump_stl

BLADERUNNER_ROOT       := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
BUILD_PATH             := $(BLADERUNNER_ROOT)

BSG_F1_DIR             := $(BLADERUNNER_ROOT)/bsg_f1
BSG_F1_COMMIT_ID       := $(shell cd $(BSG_F1_DIR); git rev-parse --short HEAD)
BSG_MANYCORE_DIR       := $(BLADERUNNER_ROOT)/bsg_manycore
BSG_MANYCORE_COMMIT_ID := $(shell cd $(BSG_MANYCORE_DIR); git rev-parse --short HEAD)
BASEJUMP_STL_DIR       := $(BLADERUNNER_ROOT)/basejump_stl
BASEJUMP_STL_COMMIT_ID := $(shell cd $(BASEJUMP_STL_DIR); git rev-parse --short HEAD)

FPGA_IMAGE_VERSION     := 3.4.0
AWS_FPGA_VERSION       := v1.4.5
F12XLARGE_TEMPLATE_ID  := lt-01bc73811e48f0b26
AFI_ID                 := 
AGFI_ID                := 
