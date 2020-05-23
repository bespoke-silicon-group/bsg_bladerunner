# BSG Bladerunner

This repository tracks releases of the HammerBlade source code and
infrastructure. It can be used to:

* Compile and Simulate HammerBlade Manycore Designs

## [Makefile](Makefile) targets

* `setup`: Build all tools and perform all patching and updates
  necessary for cosimulation

* `verilator-exe`: Build the verilator toolchain
  
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

