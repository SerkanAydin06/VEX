#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
ASSET_EXTENSIONS = {".png", ".wav", ".mp3", ".ttf"}
MAX_SINGLE_ASSET_BYTES = 12 * 1024 * 1024
MAX_BINARY_TREE_BYTES = 330 * 1024 * 1024
SINGLE_ASSET_OVERRIDES = {
    Path("assets/enemies/husk_leech/husk_leech_character_spritesheet.png"): 13 * 1024 * 1024,
    # Refreshed character sheets intentionally retain the authored transparent
    # canvas at runtime resolution. Keep the global limit strict and allow only
    # these reviewed canonical sheets extra headroom.
    Path("assets/enemies/briar_skulker/briar_skulker_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/gorehorn/gorehorn_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/ravager/ravager_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/spore_matriarch/spore_matriarch_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/coil_lancer/coil_lancer_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png"): 20 * 1024 * 1024,
    Path("assets/enemies/venom_marshall/venom_marshall_character_spritesheet.png"): 20 * 1024 * 1024,
}
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
        relative = path.relative_to(ROOT)
        limit = SINGLE_ASSET_OVERRIDES.get(relative, MAX_SINGLE_ASSET_BYTES)
        if size > limit:
            ERRORS.append(
                f"Tek asset sınırı aşıldı: {relative} "
                f"({size / 1024 / 1024:.1f} MiB > {limit / 1024 / 1024:.0f} MiB)"
            )
    if total > MAX_BINARY_TREE_BYTES:
        ERRORS.append(
            f"Binary çalışma ağacı sınırı aşıldı: "
            f"{total / 1024 / 1024:.1f} MiB > {MAX_BINARY_TREE_BYTES / 1024 / 1024:.0f} MiB"
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
