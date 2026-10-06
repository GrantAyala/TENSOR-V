#!/usr/bin/env bash
set -euo pipefail
# Verilator's generated Makefile rejects spaces in its build directory.
# Compile in a private Linux temporary directory, then retain the executable.
project_dir=$(pwd)
build_tmp=$(mktemp -d /tmp/tensorv.XXXXXXXX)
[[ "$build_tmp" == /tmp/tensorv.* && -d "$build_tmp" ]]
trap 'rm -rf -- "$build_tmp"' EXIT
cp rtl/tensorv_soc.sv rtl/tensorv_dot4.sv third_party/picorv32/picorv32.v sim/main.cpp "$build_tmp/"
cd "$build_tmp"
verilator --cc --exe --build -j 2 --top-module tensorv_soc \
    tensorv_soc.sv tensorv_dot4.sv picorv32.v main.cpp
mkdir -p "$project_dir/build/sim"
cp obj_dir/Vtensorv_soc "$project_dir/build/sim/Vtensorv_soc"
