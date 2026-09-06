#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


def png_size(relative: str) -> tuple[int, int]:
    data = (ROOT / relative).read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n"
    assert data[12:16] == b"IHDR"
    return struct.unpack(">II", data[16:24])


scene = read("scenes/actors/cinder_spitter.tscn")
projectile = read("scenes/actors/cinder_spitter_projectile.tscn")
script = read("scripts/actors/cinder_spitter.gd")
character_manifest = json.loads(read("assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet_manifest.json"))
effects_manifest = json.loads(read("assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet_manifest.json"))

assert png_size("assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet.png") == (2048, 4608)
assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
]
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])

assert png_size("assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet.png") == (1024, 512)
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]
assert all(row["frame_count"] == 4 for row in effects_manifest["rows"])

assert "class_name VexCinderSpitter" in script
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in script
assert "@export" not in script

for token in [
    'uid="uid://bcindspittex1"',
    'path="res://assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet.png"',
    'path="res://scenes/actors/cinder_spitter_projectile.tscn"',
    'enemy_id = &"cinder_spitter"',
    "combat_role = 1",
    "maximum_health = 95",
    "attack_damage = 15",
    "attack_range = 14.0",
    "attack_windup = 0.35",
    "attack_minimum_distance = 4.0",
    "attack_preferred_distance = 8.0",
    "projectile_spawn_height = -0.05",
    "projectile_spawn_forward_offset = 0.20",
    "projectile_lead_factor = 0.45",
    "ranged_cover_visibility_threshold = 0.55",
    "runtime_grid_step = 0.92",
    "runtime_grid_max_nodes = 2300",
    "runtime_grid_search_margin = 15.0",
    "billboard = 2",
    "render_priority = -2",
    "offset = Vector2(0, 16)",
]:
    assert token in scene, token

character_regions = re.findall(r"region = Rect2\((\d+), (\d+), 512, 768\)", scene)
assert len(character_regions) == 24, len(character_regions)
assert set(character_regions) == {
    (str(column * 512), str(row * 768)) for row in range(6) for column in range(4)
}
assert re.search(r"^pixel_size = 0\.0024666667$", scene, re.M)
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
}
assert '&"hurt"' not in scene

for token in [
    'uid="uid://bcindspitefx1"',
    'path="res://assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet.png"',
    'path="res://scripts/actors/ravager_projectile.gd"',
    "speed = 15.5",
    "collision_mask = 11",
    "impact_light_energy = 5.0",
]:
    assert token in projectile, token

effect_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", projectile)
assert len(effect_regions) == 8, len(effect_regions)
assert set(effect_regions) == {
    (str(column * 256), str(row * 256)) for row in range(2) for column in range(4)
}
assert re.search(r"^pixel_size = 0\.0023$", projectile, re.M)
assert re.search(r"^pixel_size = 0\.0027$", projectile, re.M)

for import_path, uid in [
    ("assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet.png.import", "uid://bcindspittex1"),
    ("assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet.png.import", "uid://bcindspitefx1"),
]:
    metadata = read(import_path)
    assert f'uid="{uid}"' in metadata
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata
    assert "detect_3d/compress_to=0" in metadata

print("cinder spitter canonical spritesheet audit passed")
