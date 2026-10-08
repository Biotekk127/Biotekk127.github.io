#!/usr/bin/env python3
"""Validate + render every character in src/shared/Characters and print a summary.

    python3 tools/charlab/check_all.py --luau path/to/luau --out previews/

Also checks that every dropper in src/shared/Items.luau points at an existing character
file whose Id matches its file name. Exit code 1 if anything has errors.
"""
import argparse
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
CHARS = os.path.join(ROOT, "src", "shared", "Characters")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--luau", default="luau")
    ap.add_argument("--out", required=True)
    args = ap.parse_args()
    os.makedirs(args.out, exist_ok=True)

    with open(os.path.join(ROOT, "src", "shared", "Items.luau"), encoding="utf-8") as f:
        wanted = re.findall(r'Character = "(\w+)"', f.read())
    files = sorted(n[:-5] for n in os.listdir(CHARS) if n.endswith(".luau"))
    failed = False
    for cid in wanted:
        if cid not in files:
            print(f"MISSING  {cid}: referenced by Items.luau but no file")
            failed = True

    print(f"{'Character':28} {'rarity':10} {'parts':>5} {'anim':>4} {'mini':>4}  result")
    for cid in files:
        path = os.path.join(CHARS, cid + ".luau")
        with open(path, encoding="utf-8") as f:
            src = f.read()
        m = re.search(r'Id\s*=\s*"(\w+)"', src)
        rarity = re.search(r'Rarity\s*=\s*"(\w+)"', src)
        proc = subprocess.run([sys.executable, os.path.join(HERE, "charlab.py"), path,
                               "--out", os.path.join(args.out, cid + ".png"), "--luau", args.luau],
                              capture_output=True, text=True)
        out = proc.stdout
        full = re.search(r"Full: (\d+) parts, (\d+) animated", out)
        mini = re.search(r"Mini: (\d+) parts", out)
        errors = [l.strip() for l in out.splitlines() if "[ERROR]" in l]
        warnings = [l.strip() for l in out.splitlines() if "[WARNING]" in l]
        if not m or m.group(1) != cid:
            errors.append(f"Id {m.group(1) if m else '?'} does not match file name {cid}")
        status = "OK" if not errors else f"{len(errors)} ERROR(S)"
        if warnings:
            status += f", {len(warnings)} warning(s)"
        print(f"{cid:28} {(rarity.group(1) if rarity else '?'):10} {full.group(1) if full else '-':>5} "
              f"{full.group(2) if full else '-':>4} {mini.group(1) if mini else '-':>4}  {status}")
        for line in errors + warnings:
            print("      " + line)
        failed |= bool(errors)
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
