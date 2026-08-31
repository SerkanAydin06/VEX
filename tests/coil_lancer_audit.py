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

assert character_manifest["sheet_size"] == {"width": 1364, "height": 3072}
assert character_manifest["frame_size"] == {"width": 341, "height": 512}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
]
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])

assert effects_manifest["sheet_size"] == {"width": 2048, "height": 1024}
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]
assert all(row["frame_count"] == 4 for row in effects_manifest["rows"])

assert "class_name VexCoilLancer" in script
assert 'extends "res://scripts/actors/enemy_combatant_base.gd"' in script
assert "@export" not in script

for token in [
    'path="res://assets/enemies/coil_lancer/coil_lancer_character_spritesheet.png"',
    'path="res://scenes/actors/coil_lancer_projectile.tscn"',
    'enemy_id = &"coil_lancer"',
    "combat_role = 2",
    "maximum_health = 105",
    "attack_damage = 24",
    "attack_range = 22.0",
    "attack_minimum_distance = 7.0",
    "attack_preferred_distance = 13.0",
    "projectile_lead_factor = 0.78",
    "damage_pursuit_commit_time = 0.2",
    "ranged_cover_visibility_threshold = 0.65",
    "path_target_change_distance = 2.4",
    "runtime_grid_step = 1.02",
    "runtime_grid_max_nodes = 2200",
    "runtime_grid_search_margin = 15.0",
    "billboard = 2",
    "render_priority = -2",
    "offset = Vector2(0, 16)",
]:
    assert token in scene, token

character_regions = re.findall(
    r'region = Rect2\((\d+), (\d+), 341, 512\)', scene
)
assert len(character_regions) == 24, len(character_regions)
assert set(character_regions) == {
    (str(column * 341), str(row * 512))
    for row in range(6)
    for column in range(4)
}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
}
assert '&"hurt"' not in scene

for token in [
    'path="res://assets/enemies/coil_lancer/coil_lancer_effects_spritesheet.png"',
    'path="res://scripts/actors/ravager_projectile.gd"',
    "speed = 28.0",
    "collision_mask = 11",
    "impact_light_energy = 6.0",
]:
    assert token in projectile, token

effect_regions = re.findall(
    r'region = Rect2\((\d+), (\d+), 512, 512\)', projectile
)
assert len(effect_regions) == 8, len(effect_regions)
assert set(effect_regions) == {
    (str(column * 512), str(row * 512))
    for row in range(2)
    for column in range(4)
}

for import_path in [
    "assets/enemies/coil_lancer/coil_lancer_character_spritesheet.png.import",
    "assets/enemies/coil_lancer/coil_lancer_effects_spritesheet.png.import",
]:
    metadata = read(import_path)
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata

print("coil lancer audit passed")
