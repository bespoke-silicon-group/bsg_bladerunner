
include Makefile.deps

.PHONY: checkout-repos
all: checkout-repos

define hash
$($(shell echo $(1)_HASH | tr [:lower:] [:upper:]))
endef

# Generate a list of the repositories with their commit hashes appended
define repo-list
$(foreach dep,$(DEPENDENCIES),$(dep)_$(call hash,$(dep)))
endef

# Generate Makefile rules for each of our dependency repositories
define nested-rule
$(1)_$(call hash,$(1)):
	git clone git@bitbucket.org:taylor-bsg/$(1).git $(1)_$(call hash,$(1))
	cd $(1)_$(call hash,$(1)) && git reset --hard $(call hash,$(1))
endef

$(foreach dep,$(DEPENDENCIES),$(eval $(call nested-rule,$(dep))))

checkout-repos: $(call repo-list)

build-ami:

build-agti:

build:

clean:
	$(foreach dep,$(DEPENDENCIES),rm -rf $(dep)*)
