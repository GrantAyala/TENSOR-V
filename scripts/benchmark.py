"""Run real RTL, validate completion, and retain machine-readable kernel metrics."""
import json
import re
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def main():
    run = subprocess.run([str(ROOT / "build/sim/Vtensorv_soc"), "build/benchmark.bin"],
                         cwd=ROOT, capture_output=True, text=True, check=True, timeout=120)
    print(run.stdout, end="")
    metrics = {int(i): int(n) for i, n in re.findall(r"metric\[(\d+)\]=(\d+)", run.stdout)}
    if set(metrics) != set(range(7)) or metrics[4] != metrics[5] or metrics[6] != 256:
        raise RuntimeError("Incomplete or inconsistent benchmark output")
    if not metrics[0] or not metrics[1] or "exit=0" not in run.stdout:
        raise RuntimeError("Invalid cycle count or exit status")
    if not re.search(r"dot4=512\b", run.stdout):
        raise RuntimeError("Expected 256 validation and 256 benchmark DOT4 instructions")
    result = {
        "workload": "256 packed INT8 dot products (kernel only, not neural inference)",
        "scalar_isa": "RV32I with software multiplication (libgcc)",
        "memory": "64 KiB, zero extra wait states",
        "scalar_cycles": metrics[0], "dot4_cycles": metrics[1],
        "scalar_instructions": metrics[2], "dot4_instructions": metrics[3],
        "cycle_speedup": round(metrics[0] / metrics[1], 4),
        "checksum_u32": metrics[4],
        "measurement_note": "Same core; cycle windows include counter-read overhead. No clock/power/FPGA claim.",
    }
    (ROOT / "build/benchmark.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2))


if __name__ == "__main__":
    main()
