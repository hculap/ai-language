#!/usr/bin/env python3
"""
Noise Injection for V2 Emergent Language Experiment.

Usage: python3 noise.py <input_file> <output_file> <rate>

Corrupts characters in the message at the given rate.
- 40% chance: delete character
- 40% chance: substitute with random char from message's alphabet
- 20% chance: insert random char from message's alphabet before it

ALL characters including whitespace are subject to corruption.
Substitution/insertion uses chars from the sender's alphabet
(keeps alphabets disjoint after corruption).
"""

import random
import sys


def get_alphabet(msg: str) -> list[str]:
    """Extract the unique non-whitespace characters as the sender's alphabet."""
    chars = list(set(c for c in msg if not c.isspace()))
    if not chars:
        chars = list("0123456789")
    return chars


def inject_noise(msg: str, rate: float) -> str:
    """Apply noise to message at given rate."""
    alphabet = get_alphabet(msg)
    result = []

    for c in msg:
        if random.random() < rate:
            r = random.random()
            if r < 0.4:
                # Delete: skip this character
                continue
            elif r < 0.8:
                # Substitute: replace with random from sender's alphabet
                result.append(random.choice(alphabet))
            else:
                # Insert: add random char before keeping original
                result.append(random.choice(alphabet))
                result.append(c)
        else:
            result.append(c)

    return "".join(result)


def main():
    if len(sys.argv) != 4:
        print(f"Usage: {sys.argv[0]} <input_file> <output_file> <rate>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = sys.argv[2]
    rate = float(sys.argv[3])

    with open(input_file, "r") as f:
        original = f.read()

    corrupted = inject_noise(original, rate)

    with open(output_file, "w") as f:
        f.write(corrupted)

    # Stats for logging
    orig_len = len(original)
    corr_len = len(corrupted)
    diff = abs(orig_len - corr_len)
    print(f"Noise: {orig_len} → {corr_len} chars ({rate*100:.0f}% rate, {diff} char diff)")


if __name__ == "__main__":
    main()
