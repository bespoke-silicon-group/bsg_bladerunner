# BSG Manycore Release

This repository tracks releases of the BSG Manycore source code and
infrastructure.

## Relevant Makefile goals

* `checkout-repos`: Clone repositories that are needed for building new F1
    images

* `build-ami` : Builds the Amazon Machine Image and provides an ID in <TODO
    INSERT FILE HERE>

* `build-agti`:

* `build`:

## File List

`Makefile` provides an interface for managing repositories and building new
images for Amazon F1

`Makefile.deps` denotes what commits on repositories constitute this
release as `REPO_NAME := commit_hash`

