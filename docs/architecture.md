# Architecture contract, revision 0

## Processor configuration

PicoRV32 is pinned to `a473fc8fca393771d83b0ffcf0b14db3393339d8`. PCPI and
the default cycle/instruction counters are enabled. Compressed instructions,
interrupts, and hardware multiplication/division are disabled. The reset PC is
zero and initial stack top is `0x00010000`. Firmware uses the ILP32 ABI and
`-march=rv32i_zicsr`; only the supported counter reads are used from CSR space.
There is no operating system, libc, cache, or modeled memory protection.

## DOT4 instruction

| Bits | Value / interpretation |
|---|---|
| 31:25 | `0000000` (funct7) |
| 24:20 | rs2 |
| 19:15 | rs1 |
| 14:12 | `000` (funct3) |
| 11:7 | rd |
| 6:0 | `0001011` (custom-0) |

Both operands contain four little-endian signed two's-complement INT8 lanes.
Each product fits in signed 16 bits. The sum ranges from -65,024 to +65,536;
an 18-bit signed adder result is sign extended to 32 bits. There is no saturation,
rounding, implicit accumulation, memory operation, or status flag. The ordinary
RISC-V destination rules apply, including discarding writes to x0.

On a recognized valid instruction the unit asserts `pcpi_wait` combinationally.
At the next rising edge it registers the sum and asserts `pcpi_ready`. During
the result cycle, `pcpi_wr` is asserted and `pcpi_wait` is low. The CPU samples
ready/result at the next edge and the unit clears ready. The requester must
keep instruction and operands stable until completion, as PicoRV32 does.
The accelerator's one register stage is not the complete instruction latency:
processor decode, operand acquisition, and writeback add cycles.

Synchronous active-low reset clears the result and ready state; wait and write
enable are also qualified by reset. Unknown opcode/funct3/funct7 combinations
assert none of wait/write/ready when idle, so the CPU handles them as illegal
instructions. `enable_dot4=0` disconnects the accelerator for the baseline tests;
it is a simulation configuration input and should stay constant during a run.

## Simulation memory map

| Address | Behavior |
|---|---|
| `0x00000000..0x0000ffff` | 64 KiB little-endian RAM, shared instructions/data |
| `0x10000004` | Full-word write: finish with status (zero = success) |
| `0x10000010..0x1000002c` | Full-word writes: eight unsigned metric slots |

RAM implements byte write strobes. The host acknowledges transactions once at
their accepting rising edge. Normally memory adds no extra wait states.
`--stalls` permits completion only when the simulator's cycle number is divisible
by four. Invalid addresses or invalid MMIO access sizes fail the simulation.
Trap is an error unless `--expect-trap` was explicitly requested. A fixed
20-million-cycle limit catches hangs. Host wall time is never reported as CPU time.

Firmware starts at zero, establishes a stack, clears BSS, calls main, then writes
its return code to the exit register. The linker reserves 4 KiB for the stack
and rejects images whose static storage overlaps it. There is no stack-overflow
detector at runtime. The ELF linker may warn about an RWX LOAD segment because
the bare-metal memory is unified and deliberately has no protection attributes.

## Measurement contract

The benchmark initializes 256 deterministic packed operand pairs, including
all-lane extrema, and first compares every scalar result with the custom
instruction. It then measures one scalar loop and one accelerated loop using
rdcycle/rdinstret. Unsigned checksums avoid undefined signed accumulation overflow.
Input arrays are volatile so both loops load their inputs at runtime. DOT4 uses
volatile inline assembly so the compiler cannot replace it with a constant.

Both kernels run on the same CPU with the same memory policy. The scalar helper
is intentionally simple and not yet optimized. With the hardware M extension
disabled, scalar multiplication calls GCC's software multiplication helper.
The benchmark's magnitude therefore reflects that baseline choice. Counter
reads add small overhead: cycle windows contain both instruction-counter reads;
instruction windows include a counter-read instruction and loop setup. No empty
window overhead has been subtracted. Packing costs outside the measured loops
and full inference are not measured yet.
