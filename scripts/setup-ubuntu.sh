#!/usr/bin/env bash
set -euo pipefail
sudo apt-get update
sudo apt-get install -y build-essential python3 python3-venv verilator iverilog yosys \
    gcc-riscv64-unknown-elf binutils-riscv64-unknown-elf
