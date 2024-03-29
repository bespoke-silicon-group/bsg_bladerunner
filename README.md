# BSG Bladerunner

This repository tracks releases of the HammerBlade source code and
infrastructure. It can be used to simulate HammerBlade Nodes of
diverse sizes and memory types.

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
Simulated (Cosimulated) HammerBlade Node using Synopysis VCS or
Verilator. 
The HammerBlade Runtime and Cosimulation top levels are in [BSG
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

To run applications on HammerBlade follow the instructions below:

## Requirements

### CAD Tools

* To simulate with VCS you must have VCS-MX installed. (After 2019,
  VCS-MX is included with VCS)

* Verilator is built as part of the setup process.

The Makefiles will warn/fail if it cannot find the appropriate tools.

### Packages

Building the RISC-V Toolchain requires several distribution
packages. The following are required for CentOS/RHEL-based
distributions:

```libmpc autoconf automake libtool curl gmp gawk bison flex texinfo gperf expat-devel dtc cmake3 python3-devel```

On debian-based distributions, the following packages are required:

```libmpc-dev autoconf automake libtool curl libgmp-dev gawk bison flex texinfo gperf libexpat-dev device-tree-compiler cmake build-essential python3-dev```


## Setup: VCS

**Non Bespoke Silicon Group (BSG) users MUST have VCS installed on PATH before these steps**

The default VCS environment simulates the manycore architecture, without any closed-source or encrypted IP. 

1. [Add SSH Keys to your GitHub account](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account). 

2. Initialize the submodules: `git submodule update --init --recursive`

3. (BSG Users Only: `git clone git@github.com:bespoke-silicon-group/bsg_cadenv.git`)

4. Run `make -f amibuild.mk riscv-tools`


## Setup: Verilator (Beta)

Verilator simulates the HammerBlade architecture using C/C++ transpilation.

1. [Add SSH Keys to your GitHub account](https://help.github.com/en/github/authenticating-to-github/adding-a-new-ssh-key-to-your-github-account). 

2. Initialize the submodules: `git submodule update --init --recursive`

3. Run `make verilator-exe`

4. Run `make -f amibuild.mk riscv-tools`


## Examples

See [bsg_replicant/README.md](bsg_replicant/README.md)


## [Makefile](Makefile) targets

* `setup`: Build all tools and updates necessary for cosimulation
  
  You can also run `make help` to see all of the available targets in this repository. 

## Repository File List

* [Makefile](Makefile) provides targets cloning repositories and
setting up the repository. See the section on [Makefile
Targets](https://github.com/bespoke-silicon-group/bsg_bladerunner#makefile-targets)
for more information.

* [project.mk](project.mk) defines paths to each of the submodule
dependencies

* [scripts](scripts): Scripts used to upload Amazon FPGA images (AFIs) and configure Amazon Machine Images (AMIs).


## Notes:

   AWS FPGA support has been deprecated, though the files remain for posterity.