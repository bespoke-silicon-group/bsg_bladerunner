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

* `checkout-repos`: Clone repositories that are needed for the
  Manycore/Bladerunner project.

* `build-ami` : Builds the Amazon Machine Image (AMI) and emits the AMI ID.

* `build-dcp` : Compiles the manycore design (locally) as a Design Checkpoint
  (DCP)

* `build-afi` : Uploads a Design Checkpoint (DCP) to AWS and processes it into
  an Amazon FPGA Image (AFI) with an Amazon Global FPGA Image ID (AGFI)

## File List

`Makefile` provides targets cloning repositories and building new Amazon Machine
images.

`Makefile.amibuild` provides targets for building and installing the manycore
tools on a Amazon EC2 instance. Indirectly used by the target `build-ami` in Makefile.

`Makefile.deps` Lists the repository dependencies for this project and what
commits from each repository constitute a release (listed as `<REPO_NAME> :=
commit_hash`)

`Makefile.common` defines paths to each cloned repository using the DEPENDENCIES
variable defined `Makefile.deps`

## Instructions

### F1 Cosimulation

To run cosimulation of the manycore architecture, clone this repository and then
    run `make checkout-repos`. Define BSG_IP_CORES_DIR and BSG_MANYCORE_DIR as
    environment variables pointing to the BaseJump STL and BSG Manycore
    Directories, and run `make cosimulation` from inside the BSG F1/cl_manycore
    directory.

    (This process will be simplified in v0.4.3)

### Build an Amazon FPGA Image (AFI)

To build an AFI:
    1. Clone this repository.

    2. *Update the FPGA_IMAGE_VERSION variable* in `Makefile.deps` to avoid
    naming conflicts.

    3. Change the repository commit IDs in `Makefile.deps` to the desired commit
    IDs.

    4. *Run `make build-afi`* from inside this repository. This will build the
    FPGA image and upload it to AWS. FPGA_IMAGE_VERSION will be used as the
    value for the 'Version' key in AFI Tags.

### Build an Amazon Machine Image (AMI)
   
To build an AMI:
    1. Clone this repository.

    2. *Update the FPGA_IMAGE_VERSION variable* in `Makefile.deps` to avoid
    naming conflicts.

    3. Change the repository commit IDs in `Makefile.deps` to the desired commit
    IDs.

    4. Commit changes and push to a branch. (This step is critical!)

    5. *Run `make build-ami`* from inside this repository. This will build the
    FPGA image and upload it to AWS. FPGA_IMAGE_VERSION will be used as the
    value for the 'Version' key in AMI Tags.

### To Make a Release
   
To make a release:
    1. Clone this repository.

    2. *Update the FPGA_IMAGE_VERSION variable* in `Makefile.deps` to avoid
    naming conflicts.

    3. Change the repository commit IDs in `Makefile.deps` to the desired commit
    IDs.

    4. *Run `make build-afi`* from inside this repository. (See the section
    Build an Amazon FPGA Image)

    5. Commit changes and push to a branch. 

    6. *Run `make build-ami`* from inside this repository. (See the section
    Build an Amazon Machine Image)

    7. Test the release
    
    8. Make a PR to `dev` or `master` depending on the state of the release.
