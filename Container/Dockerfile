# Alpine would probably be better but BSG uses some glibc functionality that musl doesn't provide.
FROM centos:8
RUN yum -y install epel-release dnf-plugins-core && yum -y config-manager --set-enabled PowerTools &&  yum -y install ncurses-devel gettext libmpc autoconf automake libtool curl gmp gawk bison flex gperf expat-devel dtc cmake3 python3-devel git wget ninja-build make gcc gcc-c++ texi2html texinfo which bc python2 python38 stat lbzip2 diffutils file zlib-devel && alternatives --set python $(which python3)

# Clone RISC-V GNU toolchain
COPY clone_toolchain.sh /
RUN bash /clone_toolchain.sh

# Install RISC-V toolchain
COPY install_toolchain.sh /
RUN bash /install_toolchain.sh

# Install LLVM
COPY install_llvm.sh /
RUN bash /install_llvm.sh

# Install Verilator
COPY install_verilator.sh /
RUN bash /install_verilator.sh

