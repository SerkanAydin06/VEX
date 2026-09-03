#!/usr/bin/env python3
from pathlib import Path

path = Path("scripts/actors/enemy_combatant_base.gd")
text = path.read_text(encoding="utf-8")
replacements = {
    "@export_range(0.0, 3.0, 0.05) var local_detour_duration := 0.90":
        "var local_detour_duration := 0.90",
    "@export_range(0.5, 4.0, 0.05) var local_detour_clearance_multiplier := 1.45":
        "var local_detour_clearance_multiplier := 1.45",
    "@export_range(0.1, 3.0, 0.05) var local_detour_min_step := 0.90":
        "var local_detour_min_step := 0.90",
    "@export var local_detour_lateral_multipliers := PackedFloat32Array([1.0, 1.8, 2.8, 4.0])":
        "var local_detour_lateral_multipliers := PackedFloat32Array([1.0, 1.8, 2.8, 4.0])",
    "@export var local_detour_forward_multipliers := PackedFloat32Array([0.0, 0.75, 1.5])":
        "var local_detour_forward_multipliers := PackedFloat32Array([0.0, 0.75, 1.5])",
}
for old, new in replacements.items():
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"expected one match for {old!r}, found {count}")
    text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8")
