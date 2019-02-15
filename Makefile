
.PHONY: checkout-repos
include Manifest.include

checkout-repos:
	deps := $(foreach dep, $(DEPENDENCIES), $(dep))
	echo $(deps)
