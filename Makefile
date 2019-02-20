
include Makefile.deps

.PHONY: checkout-repos build-ami
all: build-ami

BUILD_PATH := $(shell pwd)

# Get the hash associated with $(1) in Makefile.deps.
# hash(bsg_manycore) returns the git commit hash for bsg_manycore
define hash
$($(shell echo $(1)_HASH | tr [:lower:] [:upper:]))
endef

# Generate a list of the repositories with their commit hashes appended
define repo-list
$(foreach dep,$(DEPENDENCIES),$(dep)_$(call hash,$(dep)))
endef

# Define a makefile rule for the repo $(1)
# Each of the repos (and resulting directories) is named
# "<repo>@<commit_hash>". The rule for each clones the repo into the
# directory named with the commit hash and resets to the commit pointed
# to by the has.
define nested-rule
$(1)_$(call hash,$(1)):
	git clone git@bitbucket.org:taylor-bsg/$(1).git $(BUILD_PATH)/$(1)@$(call hash,$(1))
	cd $(BUILD_PATH)/$(1)@$(call hash,$(1)) && git reset --hard $(call hash,$(1))
	export $(shell echo $(1) | tr [:lower:] [:upper:])_PATH=$(BUILD_PATH)/$(1)@$(call hash, $(1))
endef

# Generate a Makefile goal for each of the repositories
$(foreach dep,$(DEPENDENCIES),$(eval $(call nested-rule,$(dep))))

checkout-repos: $(call repo-list)

build-ami: checkout-repos
	$(BSG_F1_PATH)/scripts/build/build.py \
	    $(foreach repo,$(DEPENDENCIES),-r $(BUILD_PATH)/$(repo)@$(call hash,$(repo))) \
	    -b $(BUILD_PATH) \
	    -v $(AWS_FPGA_VERSION)

build-agti:

build:

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
