#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSET_EXTENSIONS = {".png", ".wav", ".mp3", ".ttf"}
MAX_SINGLE_ASSET_BYTES = 12 * 1024 * 1024
MAX_BINARY_TREE_BYTES = 280 * 1024 * 1024
ERRORS: list[str] = []


def main() -> int:
    assets = [
        path for path in ROOT.rglob("*")
        if path.is_file() and path.suffix.lower() in ASSET_EXTENSIONS
        and ".godot" not in path.parts
    ]
    total = sum(path.stat().st_size for path in assets)
    for path in assets:
        size = path.stat().st_size
        if size > MAX_SINGLE_ASSET_BYTES:
            ERRORS.append(
                f"Tek asset sınırı aşıldı: {path.relative_to(ROOT)} "
                f"({size / 1024 / 1024:.1f} MiB > 12 MiB)"
            )
    if total > MAX_BINARY_TREE_BYTES:
        ERRORS.append(
            f"Binary çalışma ağacı sınırı aşıldı: "
            f"{total / 1024 / 1024:.1f} MiB > 280 MiB"
        )
    for message in ERRORS:
        print("ERROR:", message)
    print(
        f"BINARY ASSET VALIDATOR: {len(assets)} dosya, "
        f"{total / 1024 / 1024:.1f} MiB, {len(ERRORS)} hata"
    )
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
