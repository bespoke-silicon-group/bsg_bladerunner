# Alpine would probably be better but BSG uses some glibc functionality that musl doesn't provide.
FROM debian:buster-slim
RUN apt-get update && apt-get -y install git wget

# NOTE: Whenever we try to run a shell script, it uses Dash as the shell, which does not support
#       the `source` command. Make sure that each shell script has execute permissions (i.e. chmod +x). 

# Clone RISC-V GNU toolchain
COPY clone_toolchain.sh /
RUN /clone_toolchain.sh

# Install dependencies for verilator
RUN apt-get -y install libmpc-dev autoconf automake libtool curl libgmp-dev gawk bison flex libfl-dev texinfo gperf libexpat-dev device-tree-compiler cmake make g++ python3-dev tar libz-dev python bc

# Install RISC-V toolchain
COPY install_toolchain.sh /
RUN /install_toolchain.sh

# Install Verilator
COPY install_verilator.sh /
RUN /install_verilator.sh

RUN apt-get -y install ninja-build
COPY install_llvm.sh /
RUN /install_llvm.sh

RUN apt-get -y install build-essential