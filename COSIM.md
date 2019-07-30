# COSIM

## Setup (For UW Users)

These steps only need to be done once.

### Prerequisites

UW Users must have an SSH Key registered on their bitbucket account, and access
to the bsg_cadenv repository. The SSH Key will be used to clone the latter.

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

This will take some time. Go get lunch.


## Setup (For Non-UW Users)

### Prerequisites

To run cosimulation you must have Vivado 2018.2 installed and correctly
configured in your environment. Typically this is done by running `source
<path-to-Vivado>/settings64.sh`. 

You must also have VCS-MX correctly installed and configured in your
environment. Your system administrator can help with this.

In either case, the cosimulation makefiles will warn/fail if it cannot find
either tool.

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

This will take some time. Go get lunch.


## Running Regression/Cosimulation

These steps explain how to run regxsression tests in cosimulation.

### Running the Entire Regression Suite

From the `bsg_bladerunner` root directory:

```
cd bsg_f1/cl_manycore/testbenches/
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
cd bsg_f1/cl_manycore/testbenches/<subsuite>/
make regression
```

### Running a Single Test

From `bsg_bladerunner` root directory:

```
cd bsg_f1/cl_manycore/testbenches/<subsuite>/
make <test_name> 
```

Here's an example in which we run the `test_rom` test in the `library` suite:

```
cd bsg_f1/cl_manycore/testbenches/library/
make test_rom.log
```

For each subsuite, tests are list in `bsg_f1/cl_manycore/regression/<suite>/Makefile.tests`
