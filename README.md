# BSG Bladerunner

This repository tracks releases of the HammerBlade source code and
infrastructure. It can be used to:

* Simulate HammerBlade Nodes of diverse sizes and memory types

* Generate HammerBlade [Amazon FPGA Images](https://aws.amazon.com/ec2/instance-types/f1/)

* Create [Amazon Machine
  Images](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html)
  with pre-installed tools and libraries

## HammerBlade Overview

HammerBlade is an open-source manycore architecture for performing
efficient computation on large general-purpose workloads. A
HammerBlade is composed of nodes attached to a general purpose host,
simliar to a general-purpose GPU. Each node is a single an array of
tiles interconnected by a 2-D mesh network attached to a flexible
memory system.

HammerBlade is a Single-Program, Multiple-Data (SPMD) architecture:
All tiles execute the same program on a different set of input data to
complete a larger computation kernel. Programs are written in the
CUDA-Lite lanaguage (C/C++) and executed on the tiles in parallel
"groups", and sequential "grids". The CUDA-Lite host runtime (C/C++)
manages execution parallel and sequential execution. 

The HammerBlade is being integrated with higher-level parallel
frameworks and Domain-Specific Languages. A Pytorch
[Pytorch](https://github.com/pytorch/pytorch) backend is being
developed to accelerate Machine Learning and a
[Graphit](https://github.com/GraphIt-DSL/graphit) code-generator is
being developed to support Graph Computations.

C/C++, Python, and Pytorch programs can interact with a Cooperatively
Simulated (Cosimulated) HammerBlade Node using Synopysis VCS. The
HammerBlade Runtime and Cosimulation top levels are in [BSG
Replicant](https://github.com/bespoke-silicon-group/bsg_replicant)
repository.

For a more in-depth overview of the HammerBlade architecture, see the
[HammerBlade
Overview](https://docs.google.com/document/d/1wpdx0FykCyIAL3VdJEBz0tK-aQyChW0TKdHfbIXQJQI/edit).

The architectural HDL for HammerBlade is in the [BSG Manycore
Repository](https://github.com/bespoke-silicon-group/bsg_manycore) and
the [BaseJump
STL](https://github.com/bespoke-silicon-group/basejump_stl)
repositories. For technical details about the HammerBlade
architecture, see the [HammerBlade Technical Reference
Manual](https://docs.google.com/document/d/1b2g2nnMYidMkcn6iHJ9NGjpQYfZeWEmMdLeO_3nLtgo)

To run cosimulation or build FPGA images from this repository, follow
the instructions in
[Setup](https://github.com/bespoke-silicon-group/bsg_bladerunner#setup)
and then the relevant sections for
[Cosimulation](https://github.com/bespoke-silicon-group/bsg_bladerunner#cc-cosimulation)
or [F1
Execution](https://github.com/bespoke-silicon-group/bsg_bladerunner#f1-execution)

## Repository File List

* [Makefile](Makefile) provides targets cloning repositories and
building new Amazon Machine images. See the section on [Makefile
Targets](https://github.com/bespoke-silicon-group/bsg_bladerunner#makefile-targets)
for more information.

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

## [Makefile](Makefile) targets

* `setup`: Build all tools and updates necessary for cosimulation

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
