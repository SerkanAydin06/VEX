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


scene = read("scenes/actors/coil_lancer.tscn")
projectile = read("scenes/actors/coil_lancer_projectile.tscn")
script = read("scripts/actors/coil_lancer.gd")
character_manifest = json.loads(read("assets/enemies/coil_lancer/coil_lancer_character_spritesheet_manifest.json"))
effects_manifest = json.loads(read("assets/enemies/coil_lancer/coil_lancer_effects_spritesheet_manifest.json"))

assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]

assert "class_name VexCoilLancer" in script
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in script
for token in [
    'enemy_id = &"coil_lancer"', "maximum_health = 105", "attack_damage = 24",
    "attack_range = 22.0", "attack_minimum_distance = 7.0", "attack_preferred_distance = 13.0",
    "projectile_lead_factor = 0.78", "pixel_size = 0.0026", "billboard = 2",
]:
    assert token in scene, token

character_regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 768\)', scene)
assert len(character_regions) == 24
assert set(character_regions) == {(str(c * 512), str(r * 768)) for r in range(6) for c in range(4)}

for token in [
    'path="res://assets/enemies/coil_lancer/coil_lancer_effects_spritesheet.png"',
    "speed = 28.0", "collision_mask = 11", "impact_light_energy = 6.0",
    "pixel_size = 0.0021", "pixel_size = 0.0026",
]:
    assert token in projectile, token
fx_regions = re.findall(r'region = Rect2\((\d+), (\d+), 256, 256\)', projectile)
assert len(fx_regions) == 8
assert set(fx_regions) == {(str(c * 256), str(r * 256)) for r in range(2) for c in range(4)}

for import_path, uid in [
    ("assets/enemies/coil_lancer/coil_lancer_character_spritesheet.png.import", "uid://bpujgbnli8o57"),
    ("assets/enemies/coil_lancer/coil_lancer_effects_spritesheet.png.import", "uid://deik72rcf51cx"),
]:
    metadata = read(import_path)
    assert f'uid="{uid}"' in metadata
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata
    assert '"vram_texture": true' in metadata

print("coil lancer audit passed")
