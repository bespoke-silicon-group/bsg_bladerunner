# BSG Bladerunner

This repository tracks releases of the BSG Manycore source code and
infrastructure. It can be used to:

* Create [Amazon Machine
  Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) with
  manycore tools and libraries-preinstalled.

* Compile and Simulate FPGA Designs using the repositories and git hashes listed
  in `Makefile.deps`

* Generate [Amazon FPGA Images](https://aws.amazon.com/ec2/instance-types/f1/)
  using the repositories and git hashes listed in `Makefile.deps`.

## Relevant Makefile targets

* `checkout-repos`: Clone repositories that are needed for building new F1
    images

* `build-ami` : Builds the Amazon Machine Image (AMI) and emits the AMI ID.

* `build-dcp` : Compiles the manycore design (locally) as a Design Checkpoint
  (DCP)

* `upload-agfi` : Uploads a Design Checkpoint (DCP) to AWS and processes it into
  an Amazon FPGA Image (AFI) with an Amazon Global FPGA Image ID (AGFI)

## File List

`Makefile` provides targets cloning repositories and building new Amazon Machine
images.

`Makefile.amibuild` provides targets for building and installing the manycore
tools on a Amazon EC2 instance. Indirectly used by the target `build-ami` in Makefile.

`Makefile.deps` denotes what commits on repositories constitute this
release as `REPO_NAME := commit_hash`

