# BSG Bladerunner

This repository tracks releases of the HammerBlade source code and
infrastructure. It can be used to:

* Compile and Simulate FPGA Designs

* Generate [Amazon FPGA Images](https://aws.amazon.com/ec2/instance-types/f1/)

* Create [Amazon Machine
  Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) with
  manycore tools and libraries preinstalled.

## [Makefile](Makefile) targets

* `setup`: Build all tools and perform all patching and updates
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

* [scripts](scripts): Scripts used to upload Amazon FPGA images (AFIs) and configure Amazon Machine Images (AMIs).

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

### C/C++ Cosimulation

To run C/C++ cosimulation, and run applications on an RTL simulation of the
Manycore architecure, see the instructions in [COSIM.md](COSIM.md).

### F1 Execution

To run C/C++ applications on F1, build an AMI & AFI (instructions below), and
then run `make regression` inside of [bsg_f1](bsg_f1) on the generated AMI.

### Build an Amazon FPGA Image (AFI)

These steps will build the FPGA image and upload it to AWS. `FPGA_IMAGE_VERSION`
will be used as the value for the 'Version' key in AFI Tags. The new AFI/AGFI
IDs are printed on the command line and in upload.json.

To run these steps, you will need to install the [Amazon Web Services Command
Line Interface (CLI)](https://aws.amazon.com/cli/) and configure it for your
user account.

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
r
