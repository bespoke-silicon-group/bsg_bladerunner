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

1. First, [add SSH Keys to your GitHub account](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account). 

2. Run `make setup`. This will build the RISC-V Tools for your machine.

3. Run `make verilator-exe`. This will build a recent version of Verilator.

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

