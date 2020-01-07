# COSIM

## Setup (For UW Users)

These steps only need to be done once.

### Prerequisites

UW Users must have an SSH Key registered on their bitbucket account, and access
to the bsg_cadenv repository. The SSH Key will be used to clone the latter.

Non-UW Users will need to run on a machine that already has VCS-MX and
Vivado on $PATH. See the Non-UW User instructions below.

The Makefiles will warn/fail with appropriate error messages if the
environment is not configured correctly.

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

### Prerequisites

To run cosimulation you must have Vivado 2019.1 installed and correctly
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

This will take 20-30 minutes but only needs to be done every release.

## Running Regression/Cosimulation

These steps explain how to run regression tests in
cosimulation. Adding regression tests is not covered in this document.

### Running the Entire Regression Suite

From the `bsg_bladerunner` root directory:

```
cd bsg_f1/testbenches/
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
cd bsg_f1/testbenches/<subsuite>/
make regression
```

### Running a Single Test

From `bsg_bladerunner` root directory:

```
cd bsg_f1/testbenches/<subsuite>/
make <test_name> 
```

Here's an example in which we run the `test_rom` test in the `library` suite:

```
cd bsg_f1/testbenches/library/
make test_rom.log
```

For each subsuite, tests are list in
`bsg_f1/regression/<suite>/tests.mk`. The C/C++ source files are in
the same directory.
