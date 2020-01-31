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

* `setup-uw`: Same as `setup` but clones bsg-cadenv to configure the
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

## Setup

First, [add SSH Keys to your GitHub account](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account). 

If you are an external user, run `make setup`. This will build the
RISC-V Tools for your machine and setup the aws-fpga repository.

If you are in Bespoke Silicon Group, run `make setup-uw`. This will do
the same steps as above, and also clone bsg_cadenv to configure your
CAD environment.

If you are using Vivado 2019.1 you will need to apply the following AR
before running cosimulation:
https://www.xilinx.com/support/answers/72404.html.

### Step 1

Clone this repository.

```
git clone https://github.com/bespoke-silicon-group/bsg_bladerunner
```

### Step 2

Checkout correct revisions of dependent projects and build the RISC-V
toolchain. This will clone bsg_cadenv, which sets the VCS environment for
cosimulation.

```
cd bsg_bladerunner/
make setup-uw
```

This will take 20-30 minutes but only needs to be done every release.

## Setup (For Non-UW Users)

To use this repository you must have Vivado 2019.1 installed and correctly
configured in your environment. Typically this is done by running `source
<path-to-Vivado>/settings64.sh`. 

You must also have VCS-MX correctly installed and configured in your
environment. Your system administrator can help with this.

In either case, the Makefiles will warn/fail if it cannot find either
tool.

### Step 1

Clone this repository.

```
git clone https://github.com/bespoke-silicon-group/bsg_bladerunner
```

### Step 2

Checkout correct revisions of dependent projects and build the RISC-V
toolchain. 

```
cd bsg_bladerunner/
make setup
```

## C/C++ Cosimulation

To run C/C++ cosimulation, and run applications on an RTL simulation of the
Manycore architecure.

### Running the Entire Regression Suite

From the `bsg_bladerunner` root directory:

```
cd bsg_replicant/testbenches/
make regression
```

### Running a Single Regression Suite

It is also possible to run a single regression suite. At the moment the
regression suites are:

1. library
2. spmd
3. cuda
4. python

From `bsg_bladerunner` root directory:

```
cd bsg_replicant/testbenches/<subsuite>/
make regression
```

### Running a Single Test

From `bsg_bladerunner` root directory:

```
cd bsg_replicant/testbenches/<subsuite>/
make <test_name> 
```

Here's an example in which we run the `test_rom` test in the `library` suite:

```
cd bsg_replicant/testbenches/library/
make test_rom.log
```

For each subsuite, tests are list in
`bsg_replicant/regression/<suite>/tests.mk`. The C/C++ source files are in
the same directory.

## F1 Execution

To run C/C++ applications on F1, build an AMI & AFI (instructions below), and
then run `make regression` inside of [bsg_replicant](bsg_replicant) on the generated AMI.

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
