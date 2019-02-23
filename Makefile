
include Makefile.deps

.PHONY: checkout-repos build-dcp upload-agfi build-ami
all: build-ami

BUILD_PATH := $(shell pwd)
DESIGN_NAME := manycore
BUCKET_NAME := bsgamibuild

define upper
$(shell echo $(1) | tr [:lower:] [:upper:])
endef

# Get the hash associated with $(1) in Makefile.deps.
# hash(bsg_manycore) returns the git commit hash for bsg_manycore
define hash
$($(call upper,$(1)_HASH))
endef


# Generate a list of the repositories with their commit hashes appended
define repo-list
$(foreach dep,$(DEPENDENCIES),$(dep)@$(call hash,$(dep)))
endef

# Define a makefile rule for the repo $(1)
# Each of the repos (and resulting directories) is named
# "<repo>@<commit_hash>". The rule for each clones the repo into the
# directory named with the commit hash and resets to the commit pointed
# to by the hash.
# Also, define <repo_name>_DIR as a variable
define nested-rule
export $(call upper, $(1))_DIR=$(BUILD_PATH)/$(1)\@$(call hash, $(1))

$(1)@$(call hash,$(1)):
	git clone git@bitbucket.org:taylor-bsg/$(1).git $(BUILD_PATH)/$(1)@$(call hash,$(1))
	cd $(BUILD_PATH)/$(1)@$(call hash,$(1)) && git checkout $(call hash,$(1))
endef

# Generate a Makefile goal for each of the repositories
$(foreach dep,$(DEPENDENCIES),$(eval $(call nested-rule,$(dep))))

checkout-repos: $(call repo-list)

build-ami: checkout-repos upload-agfi
	$(BSG_F1_DIR)/scripts/amibuild/build.py $(BUILD_PATH) $(AWS_FPGA_VERSION)\
	    $(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo))) \
		-u upload.json

build-dcp: checkout-repos
	make -C $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/ build

upload-agfi: build-dcp upload.json

upload.json:
	$(BSG_F1_DIR)/scripts/afiupload/upload.py $(BUILD_PATH) $(DESIGN_NAME) \
	    $(FPGA_IMAGE_VERSION) $(BSG_F1_DIR)/cl_$(DESIGN_NAME)/build/checkpoints/to_aws/cl_$(DESIGN_NAME).Developer_CL.tar \
	    $(BUCKET_NAME) "BSG AWS F1 Manycore AGFI" $(foreach repo,$(DEPENDENCIES),-r $(repo)@$(call hash,$(repo)))

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
	rm -rf upload.json
