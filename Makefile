SHELL := /bin/bash
.DELETE_ON_ERROR:
.SECONDARY:
CROSS ?= riscv64-unknown-elf-
CC := $(CROSS)gcc
CFLAGS := -march=rv32i_zicsr -mabi=ilp32 -O2 -g -ffreestanding -fno-builtin -fno-pic -msmall-data-limit=0 -Wall -Wextra -Werror
LDFLAGS := -nostdlib -nostartfiles -Wl,--no-relax -T firmware/link.ld
RTL := rtl/tensorv_soc.sv rtl/tensorv_dot4.sv third_party/picorv32/picorv32.v

.PHONY: all test unit smoke benchmark synth tools
all: test benchmark

build:
	mkdir -p build

build/sim/Vtensorv_soc: $(RTL) sim/main.cpp scripts/build-verilator.sh | build
	bash scripts/build-verilator.sh > build/verilator.log 2>&1 || { cat build/verilator.log; exit 1; }

build/%.elf: firmware/%.c firmware/start.S firmware/tensorv.h firmware/link.ld | build
	$(CC) $(CFLAGS) $(LDFLAGS) firmware/start.S $< -lgcc -o $@
	$(CROSS)objdump -d $@ > $(@:.elf=.dis)

build/%.bin: build/%.elf
	$(CROSS)objcopy -O binary $< $@

build/vectors.txt: tests/generate_vectors.py | build
	python3 $< $@

build/dot4_tb: tests/dot4_tb.sv rtl/tensorv_dot4.sv | build
	iverilog -g2012 -s dot4_tb -o $@ $^

unit: build/dot4_tb build/vectors.txt
	vvp build/dot4_tb

smoke: build/sim/Vtensorv_soc build/smoke.bin
	build/sim/Vtensorv_soc build/smoke.bin --no-dot4
	build/sim/Vtensorv_soc build/smoke.bin --no-dot4 --stalls

test: unit smoke build/illegal.bin build/benchmark.bin
	build/sim/Vtensorv_soc build/illegal.bin --expect-trap
	build/sim/Vtensorv_soc build/benchmark.bin --no-dot4 --expect-trap
	build/sim/Vtensorv_soc build/benchmark.bin --stalls

benchmark: build/sim/Vtensorv_soc build/benchmark.bin
	python3 scripts/benchmark.py

synth: | build
	yosys -Q -T -p 'read_verilog -sv rtl/tensorv_dot4.sv; synth -top tensorv_dot4; stat' > build/synthesis.log
	tail -20 build/synthesis.log

tools:
	verilator --version
	iverilog -V 2>/dev/null | head -1
	$(CC) --version | head -1
	yosys -V
	python3 --version
