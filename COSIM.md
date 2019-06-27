# COSIM

## One Time Setup Steps

These steps only need to be done once.

### Step 1

Clone this repository.

```
git clone https://github.com/bespoke-silicon-group/bsg_bladerunner
```

### Step 2

Checkout correct revisions of dependent projects and build RISCV toolchain.

```
cd bsg_bladerunner/
make setup
```

This will take some time. Go get lunch.

### Step 3 

Apply our patch to aws-fpga.

From the `bsg_bladerunner` root directory:

```
cd aws-fpga/
patch -p0 < ../aws-fpga.patch
```

## Every Time Setup Steps

These steps need to done before you run cosimulation after you have logged in.

### Step 1

Setup your AWS HDK environment.

From the `bsg_bladerunner` root directory:

```
source aws-fpga/hdk_setup.sh
```

The first time you do this it will take a little while. It will be quick every time after that.

### Step 2

Setup your VCS development environment.

How this is done depends on your organization's setup.

If you are a member of Bespoke Silicon Group contact Dustin for instructions.

## Running the Regression

These steps explain how to run regression tests in cosimulation.

### Running the Entire Regression Suite

From the `bsg_bladerunner` root directory:

```
cd bsg_f1_<hash>/cl_manycore/testbenches/
make cosim AXI_MEMORY_MODEL=(0|1)
```

We recommend setting `AXI_MEMORY_MODEL` to 1 if possible: it's noticably faster.


### Running a Single Regression Subsuite

At the moment the regression subsuites are:

1. library
2. spmd
3. cuda

From `bsg_bladerunner` root directory:

```
cd bsg_f1_<hash>/cl_manycore/testbenches/<subsuite>/
make cosim AXI_MEMORY_MODEL=(0|1)
```

### Running a Single Test

From `bsg_bladerunner` root directory:

```
cd bsg_f1_<hash>/cl_manycore/testbenches/<subsuite>/
make <test_name> AXI_MEMORY_MODEL=(0|1)
```

Here's an example in which we run the `test_printing` test in the `library` suite:

```
cd bsg_f1_<hash>/cl_manycore/testbenches/library/
make test_printing AXI_MEMORY_MODEL=(0|1)
```

For each subsuite, tests are list in `bsg_f1_<hash>/cl_manycore/regression/<suite>/Makefile.tests`

## Running Your Own Application

TODO: fill this in.
