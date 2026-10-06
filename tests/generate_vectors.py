"""Independent unbounded-integer oracle; no third-party Python packages."""
import itertools
import random
import sys
from pathlib import Path


def pack(values):
    return int.from_bytes(bytes(x & 255 for x in values), "little")


def vectors():
    # Every signed INT8 product at each physical byte lane.
    for lane in range(4):
        for x, y in itertools.product(range(-128, 128), repeat=2):
            a, b = [0] * 4, [0] * 4
            a[lane], b[lane] = x, y
            yield a, b
    # Parallel extrema catch reduction-width/sign-extension errors.
    for x, y in itertools.product((-128, -127, -1, 0, 1, 126, 127), repeat=2):
        yield [x] * 4, [y] * 4
    rng = random.Random(0x54454E53)
    for _ in range(10000):
        yield [rng.randrange(-128, 128) for _ in range(4)], [rng.randrange(-128, 128) for _ in range(4)]


if __name__ == "__main__":
    count = 0
    with Path(sys.argv[1]).open("w", encoding="ascii") as output:
        for a, b in vectors():
            result = sum(x * y for x, y in zip(a, b))
            output.write(f"{pack(a):08x} {pack(b):08x} {result & 0xffffffff:08x}\n")
            count += 1
    print(f"Generated {count} DOT4 oracle vectors")
