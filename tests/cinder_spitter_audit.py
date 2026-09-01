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


scene = read("scenes/actors/cinder_spitter.tscn")
projectile = read("scenes/actors/cinder_spitter_projectile.tscn")
script = read("scripts/actors/cinder_spitter.gd")
character_manifest = json.loads(read("assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet_manifest.json"))
effects_manifest = json.loads(read("assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet_manifest.json"))

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

assert "class_name VexCinderSpitter" in script
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in script
assert "@export" not in script

for token in [
    'path="res://assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet.png"',
    'path="res://scenes/actors/cinder_spitter_projectile.tscn"',
    'enemy_id = &"cinder_spitter"',
    "combat_role = 1",
    "maximum_health = 95",
    "attack_damage = 15",
    "attack_range = 14.0",
    "attack_minimum_distance = 4.0",
    "attack_preferred_distance = 8.0",
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
    'path="res://assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet.png"',
    'path="res://scripts/actors/ravager_projectile.gd"',
    "speed = 15.5",
    "collision_mask = 11",
    "impact_light_energy = 5.0",
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
    "assets/enemies/cinder_spitter/cinder_spitter_character_spritesheet.png.import",
    "assets/enemies/cinder_spitter/cinder_spitter_effects_spritesheet.png.import",
]:
    metadata = read(import_path)
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata

print("cinder spitter audit passed")
