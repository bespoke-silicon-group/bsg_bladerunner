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

On macOS, install the Xcode Command Line Tools and Homebrew, then install:

```sh
brew install autoconf automake libtool gawk bison flex texinfo gperf expat dtc cmake make python wget xz argp-standalone gmp mpfr libmpc pkgconf gnu-sed m4
```

HammerBlade's makefiles do not support whitespace in the checkout path. Use a
path such as `~/hammerblade/bsg_bladerunner` rather than a directory whose name
contains spaces. Homebrew installs current GNU Make as `gmake`; use `gmake` for
the commands below on macOS.


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

4. Run `make -f amibuild.mk riscv-gcc`

### AlmaLinux 9 (x86-64)

The [AlmaLinux setup bundle](scripts/alma9/README.md) separates system packages
from independent user-owned HammerBlade checkouts. It provides a DNF prerequisite
installer, pinned source/tool builds, execution and profiling checks, and a
wrapper that selects one checkout's tools and runtime libraries. GitHub device
authorization can be completed on another computer; the scripts do not launch a
browser on the server.

From `scripts/alma9`, after configuring GitHub access if needed:

```sh
bash install-alma9-prerequisites.sh
HB_MACHINE_NAME=pod_X1Y1_ruche_X16Y8_hbm_one_pseudo_channel \
  bash setup-hammerblade.sh all "$HOME/hb-16x8"
bash validate-hammerblade.sh "$HOME/hb-16x8"
```

The default is a smaller physical 4x2 model; the explicit selection above uses
the 16x8 reference. Keep different machine configurations in separate complete
checkouts because some generated libraries are shared within each checkout.
The broader `riscv-tools` target also builds historical LLVM/Spike components
that are unnecessary for this GCC-based setup.

### macOS (Apple Silicon and Intel)

The repository pins a tested release from the authoritative
[Verilator repository](https://github.com/verilator/verilator) and builds it
from source. A GitHub SSH key is not required for this setup:

```sh
mkdir -p ~/hammerblade
git clone https://github.com/bespoke-silicon-group/bsg_bladerunner.git \
  ~/hammerblade/bsg_bladerunner
cd ~/hammerblade/bsg_bladerunner
git -c url.https://github.com/.insteadOf=git@github.com: \
  submodule update --init --recursive
gmake verilator-exe
./verilator/bin/verilator --version
```

Build the customized GCC and newlib toolchain needed by the examples. This is
the longest setup step:

```sh
gmake -f amibuild.mk riscv-gcc
```

The broader `riscv-tools` target also builds Spike and the customized LLVM tree;
those components are not required for the Verilator warmup.

For the current pinned HammerBlade LLVM 22 compiler and a complete 16×8
HammerBench comparison, follow [the fresh-checkout guide](docs/macos-hammerbench.md).
Use `gmake -f llvm22.mk llvm22-install`; the historical `riscv-tools` LLVM
installer targets an older Linux development environment and is not the
LLVM 22 build path.

On macOS, the execution model defaults to one Verilator worker thread:

```sh
gmake exec.log
```

Other hosts continue to default to 16 workers. Override the count explicitly,
for example with `gmake VERILATOR_THREADS=4 exec.log`, after benchmarking the
specific model. The selected count is stored with the generated execution
model, and changing it automatically invalidates and rebuilds that model.


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
