#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

for path in sorted(ROOT.rglob("*.tscn")):
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue

    match = re.search(r'^\[node\s+[^\]]+\]$', text, re.M)
    if match is None:
        errors.append(f"Sahne root node içermiyor: {path.relative_to(ROOT)}")
        continue

    root_header = match.group(0)
    if re.search(r'\bparent\s*=', root_header):
        errors.append(
            f"Geçersiz sahne root parent tanımı: {path.relative_to(ROOT)} -> {root_header}"
        )

for message in errors:
    print("ERROR:", message)

print(f"SCENE SYNTAX VALIDATOR: {len(errors)} hata")
sys.exit(1 if errors else 0)
