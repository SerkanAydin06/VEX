#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


manifest = json.loads(read("assets/enemies/rift_reaver/rift_reaver_character_spritesheet_manifest.json"))
scene = read("scenes/actors/rift_reaver.tscn")
script = read("scripts/actors/rift_reaver.gd")
metadata = read("assets/enemies/rift_reaver/rift_reaver_character_spritesheet.png.import")

assert manifest["sheet_size"] == {"width": 1364, "height": 3072}
assert manifest["frame_size"] == {"width": 341, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == [
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

assert "class_name VexRiftReaver" in script
assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in script
assert "@export" not in script

for token in [
    'path="res://assets/enemies/rift_reaver/rift_reaver_character_spritesheet.png"',
    'enemy_id = &"rift_reaver"',
    "combat_role = 0",
    "maximum_health = 135",
    "move_speed = 3.4",
    "chase_speed = 6.6",
    "attack_range = 2.0",
    "attack_damage = 22",
    "attack_cooldown = 1.05",
    "attack_windup = 0.22",
    "attack_lunge_speed = 10.6",
    "billboard = 2",
    "render_priority = -2",
    "offset = Vector2(0, 16)",
]:
    assert token in scene, token

regions = re.findall(r'region = Rect2\((\d+), (\d+), 341, 512\)', scene)
assert len(regions) == 24, len(regions)
assert set(regions) == {
    (str(column * 341), str(row * 512))
    for row in range(6)
    for column in range(4)
}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
}

assert "radius = 0.46" in scene
assert "height = 1.9" in scene
assert "compress/mode=2" in metadata
assert "mipmaps/generate=true" in metadata
assert "detect_3d/compress_to=0" in metadata

print("rift reaver audit passed")
