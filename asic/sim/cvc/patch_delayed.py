"""Drive the *_delayed signals of the sky130 timing models directly.

The models feed their flip-flops through X_delayed copies that only the
$setuphold timing check creates. Simulators without that feature (Icarus, CVC)
leave them undriven, so every flop goes X. This adds `assign X_delayed = X;`
to each module that uses them. The SDF delays (IOPATH) and the basic
setup/hold checks still work.

Usage: python3 patch_delayed.py <input cells .v> <output cells .v>
"""
import re
import sys

src, dst = sys.argv[1], sys.argv[2]
text = open(src).read()

patched = 0
parts = re.split(r"(?<=endmodule)", text)
for i, mod in enumerate(parts):
    if "endmodule" not in mod:
        continue
        # Only the delayed copies that $setuphold / $recrem should create
    checks = re.findall(r"\$(?:setuphold|recrem)\s*\((.*?)\)\s*;", mod, re.S)
    names = sorted(set(n for c in checks
                       for n in re.findall(r"\b(\w+)_delayed\b", c)))
    if not names:
        continue
    lines = "".join(f"    assign {n}_delayed = {n};\n" for n in names)
    cut = mod.rfind("endmodule")
    parts[i] = mod[:cut] + lines + mod[cut:]
    patched += 1

open(dst, "w").write("".join(parts))
print(f"Patched {patched} cell modules -> {dst}")
