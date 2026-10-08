"""Bundles src/shared/*.luau with tests/run.luau and runs it with the `luau` CLI.

Usage (from roblox-tycoon/):  python3 tests/run_tests.py [path/to/luau]
Get the CLI from https://github.com/luau-lang/luau/releases
"""
import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHARED = os.path.join(ROOT, "src", "shared")
luau = sys.argv[1] if len(sys.argv) > 1 else "luau"

parts = [
    "local Color3 = { fromRGB = function(r, g, b) return { R = r, G = g, B = b } end }",
    "local __modules, __cache = {}, {}",
    "local function __require(name)",
    "  if __cache[name] == nil then __cache[name] = __modules[name]() end",
    "  return __cache[name]",
    "end",
]
ENGINE_ONLY = {"CharacterKit.luau", "CharacterRegistry.luau"}  # need Roblox Instances
for filename in sorted(os.listdir(SHARED)):
    if filename.endswith(".luau") and filename not in ENGINE_ONLY:
        name = filename[:-5]
        with open(os.path.join(SHARED, filename), encoding="utf-8") as f:
            source = f.read()
        source = re.sub(r"require\(script\.Parent\.(\w+)\)", r'__require("\1")', source)
        parts.append(f'__modules["{name}"] = function()\n{source}\nend')

with open(os.path.join(ROOT, "tests", "run.luau"), encoding="utf-8") as f:
    test_source = f.read()
parts.append(f"(function(...)\n{test_source}\nend)(__require)")

with tempfile.NamedTemporaryFile("w", suffix=".luau", delete=False, encoding="utf-8") as bundle:
    bundle.write("\n".join(parts))
try:
    sys.exit(subprocess.call([luau, bundle.name]))
finally:
    os.unlink(bundle.name)
