# Validation snapshot

Executed locally under Ubuntu WSL on September 6, 2026.

## Environment

| Tool | Version |
|---|---|
| Verilator | 5.020 |
| Icarus Verilog | 12.0 |
| RISC-V GCC | 13.2.0 |
| Yosys | 0.33 |
| Python | 3.12.3 |

## Passing checks

- 262,144 arithmetic vectors cover all 65,536 signed byte pairs in each lane.
- 49 vectors exercise parallel extrema and zero/one values.
- 10,000 seeded vectors exercise all lanes together against Python integer arithmetic.
- Each fixed opcode/funct3/funct7 bit is flipped individually and must be rejected.
- Register-index fields vary across vectors; wait, result, write enable, ready,
  completion, and reset cancellation are checked.
- RV32I smoke firmware returns checksum 29 and status zero, with no DOT4 calls.
  It completes in 98 simulation cycles normally and 141 with memory delays.
- An unsupported custom instruction traps.
- Firmware containing DOT4 traps when the accelerator is disabled.
- Accelerated firmware completes with 256 per-vector correctness checks and
  256 measured DOT4 executions, both normally and with memory delays.
- Scalar and accelerated checksums both equal 265,865.
- Verilator builds without suppressed warnings. Firmware compiles with
  `-Wall -Wextra -Werror`; the linker emits the documented unified-RAM RWX warning.

## Kernel results

| Metric | No extra memory wait states | Memory completion every four cycles |
|---|---:|---:|
| Scalar cycle window | 566,670 | 761,044 |
| DOT4 cycle window | 8,979 | 12,308 |
| Scalar instruction window | 139,155 | 139,155 |
| DOT4 instruction window | 2,052 | 2,052 |
| Complete firmware simulation cycles | 1,176,873 | 1,578,801 |
| DOT4 executions, including validation | 512 | 512 |

The no-extra-wait-state kernel ratio is 63.1106. This is a comparison against
RV32I **software multiplication**, not RV32IM, tuned scalar code, or end-to-end
neural inference. The full simulation totals also include initialization,
validation, reporting, and startup. Do not use this ratio as an AI inference claim.

## Synthesis

`make synth` successfully synthesizes the standalone DOT4 unit. Yosys reports
2,023 generic cells, including 19 flip-flop cells. This confirms that the RTL
passes this synthesis flow and supplies an initial logic-complexity estimate.
No target technology, FPGA mapping, timing constraints, or placed-and-routed
implementation is included. It does not establish physical area, achievable
frequency, power, or the incremental cost of a complete integrated SoC.

## Reproduce

Run `make all synth tools` in WSL from the project root. The kernel runner fails
on nonzero firmware exit, inconsistent checksums, incomplete metrics, unexpected
DOT4 execution count, or missing cycle data. The unit test fails on mismatches,
protocol errors, a missing/malformed vector file, or timeout. Outputs are retained
in `build/benchmark.json`, `build/verilator.log`, `build/synthesis.log`, and firmware
disassembly files. Generated artifacts are not versioned; this file records the
first observed result and should be updated when the design changes.

These tests are targeted verification, not formal verification or a full RISC-V
architectural compliance suite. The current project does not use cocotb yet.
