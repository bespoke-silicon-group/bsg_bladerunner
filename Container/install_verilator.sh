#!/bin/env bash
wget https://github.com/verilator/verilator/archive/v4.102.tar.gz
tar -xf v4.102.tar.gz
mv verilator-4.102 verilator
cd verilator
autoconf
./configure --prefix /usr
make -j 16
make install
rm /v4.102.tar.gz
