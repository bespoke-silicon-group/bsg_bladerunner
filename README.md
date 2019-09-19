# BSG Bladerunner

This repository tracks releases of the HammerBlade source code and
infrastructure. It can be used to:

* Compile and Simulate FPGA Designs

* Generate [Amazon FPGA Images](https://aws.amazon.com/ec2/instance-types/f1/)

* Create [Amazon Machine
  Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) with
  manycore tools and libraries-preinstalled.

## [Makefile](Makefile) targets

* setup: Build all tools and perform all patching and updates
  necessary for cosimulation

* `setup-uw: Same as `setup` but clones bsg-cadenv to configure the
  CAD environment for BSG users. Other users will need to install
  Synopsys VCS-MX and Vivado on $PATH

* `build-ami` : Builds the Amazon Machine Image (AMI) and emits the AMI ID.

* `build-tarball` : Compiles the manycore design (locally) as a tarball

* `build-afi` : Uploads a Design Checkpoint (DCP) to AWS and processes it into
  an Amazon FPGA Image (AFI) with an Amazon Global FPGA Image ID (AGFI)

* `print-ami` : Prints the current AMI whose version matches `FPGA_IMAGE_VERSION`
  in [project.mk](project.mk)
  
  You can also run `make help` to see all of the available targets in this repository. 

## File List

* [Makefile](Makefile) provides targets cloning repositories and building new
Amazon Machine images.

* [amibuild.mk](amibuild.mk) provides targets for building and
installing the manycore tools on a Amazon EC2 instance. Indirectly used by the
target `build-ami` in [Makefile](Makefile).

* [project.mk](project.mk) defines paths to each of the submodule
dependencies

## Instructions

### Setup

To run applications in Cosimulation you will need to patch the AWS
repository and build the RISC-V tools. Fortunately we provide
automated steps to do this.

If you are an external user, run `make setup`. This will build the
RISC-V Tools for your machine, and patch the aws-fpga repository.

If you are in Bespoke Silicon Group, run `make setup-uw`. This will do
the same steps as above, and also clone bsg_cadenv to configure your
CAD environment.

### F1 Cosimulation

To run cosimulation see the instructions in [COSIM.md](COSIM.md)

### Build an Amazon FPGA Image (AFI)

These steps will build the FPGA image and upload it to AWS. `FPGA_IMAGE_VERSION`
will be used as the value for the 'Version' key in AFI Tags. The new AFI/AGFI
IDs are printed on the command line and in upload.json.

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Run `make build-afi` from inside this repository. 

The new AFI/AGFI IDs are printed on the command line and in upload.json.

### Build an Amazon Machine Image (AMI)
   
These steps will build the Machine image and upload it to
AWS. `FPGA_IMAGE_VERSION` will be used as the value for the 'Version' key in AMI
Tags. 

To run these steps, you will need to install the [Amazon Web Services Command
Line Interface (CLI)](https://aws.amazon.com/cli/) and configure it for your
user account.

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Commit changes and push to a branch. (This step is critical!)

4. Run `make build-ami` from inside this repository. 

### To Make a Release
   
These steps will build an AMI and an AFI and upload them to
AWS. It is a combination of the steps above.

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Run `make build-afi` from inside this repository. (See the section Build an
Amazon FPGA Image)

4. Replace the `AGFI_ID` and `AMI_ID` variables in
[project.mk](project.mk) with the new values in upload.json (generated
by the previous step).

5. Commit your changes and push to a branch

6. Run `make build-ami` from inside this repository. (See the section Build an
Amazon Machine Image)

7. Test the release
    
8. Make a PR to `dev` or `master` depending on the state of the release.

9. Apply a tag to the release when it is merged to master
