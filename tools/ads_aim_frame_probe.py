#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

from tools.ads_sprite_probe import ROOT, WEAPONS, alignment_offset, detect_sight, load_png


for weapon_id in WEAPONS:
    print(f"=== {weapon_id.upper()} ADS FRAMES ===")
    for frame_name in ["zoom", "aim_fire_1", "aim_fire_2", "aim_fire_3", "aim_fire_4"]:
        path = ROOT / f"assets/weapons/{weapon_id}/{weapon_id}_{frame_name}.png"
        width, height, pixels = load_png(path)
        kind, sight_x, sight_y, detail = detect_sight(width, height, pixels)
        off_x, off_y = alignment_offset(width, height, sight_x, sight_y)
        print(
            f"{frame_name}: kind={kind} sight=({sight_x:.1f},{sight_y:.1f}) "
            f"offset=({round(off_x)},{round(off_y)}) raw=({off_x:.2f},{off_y:.2f}) {detail}"
        )
    print()
