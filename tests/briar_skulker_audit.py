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


scene = read("scenes/actors/briar_skulker.tscn")
projectile_scene = read("scenes/actors/briar_skulker_projectile.tscn")
script = read("scripts/actors/briar_skulker.gd")
hybrid = read("scripts/actors/enemy_hybrid_base.gd")
settings = read("scripts/actors/enemy_hybrid_ability_settings.gd")
projectile = read("scripts/actors/briar_skulker_projectile.gd")
character_manifest = json.loads(read("assets/enemies/briar_skulker/briar_skulker_character_spritesheet_manifest.json"))
effects_manifest = json.loads(read("assets/enemies/briar_skulker/briar_skulker_effects_spritesheet_manifest.json"))

assert character_manifest["sheet_size"] == {"width": 2048, "height": 5376}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "attack_close", "death", "idle_back", "walk_back",
]
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]

assert 'extends "res://scripts/actors/enemy_hybrid_base.gd"' in script
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in hybrid
assert settings.startswith("@tool\n")
for token in ["prefer_melee_when_close", "_is_player_in_melee_envelope", "_resolve_melee_hit", "_resolve_ranged_shot", "attack_close"]:
    assert token in hybrid or token in settings, token

assert 'enemy_id = &"briar_skulker"' in scene
assert 'combat_role = 1' in scene
assert 'projectile_scene = ExtResource("3_projectile")' in scene
assert "pixel_size = 0.0020833333" in scene

atlas_regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 768\)', scene)
assert len(atlas_regions) == 28, len(atlas_regions)
assert set(atlas_regions) == {(str(c * 512), str(r * 768)) for r in range(7) for c in range(4)}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {
    "idle", "walk", "attack", "attack_close", "death", "idle_back", "walk_back",
}

assert 'class_name VexBriarSkulkerProjectile' in projectile
for token in ["PhysicsRayQueryParameters3D.create", "take_damage", "flight_visual.visible = false", "impact_visual.visible = true"]:
    assert token in projectile, token
for token in [
    'path="res://assets/enemies/briar_skulker/briar_skulker_effects_spritesheet.png"',
    "pixel_size = 0.0018",
    "collision_mask = 11",
]:
    assert token in projectile_scene, token
fx_regions = re.findall(r'region = Rect2\((\d+), (\d+), 256, 256\)', projectile_scene)
assert len(fx_regions) == 8
assert set(fx_regions) == {(str(c * 256), str(r * 256)) for r in range(2) for c in range(4)}

for import_path, uid in [
    ("assets/enemies/briar_skulker/briar_skulker_character_spritesheet.png.import", "uid://d2briarsheet1"),
    ("assets/enemies/briar_skulker/briar_skulker_effects_spritesheet.png.import", "uid://dt1wxkn5dhqlp"),
]:
    metadata = read(import_path)
    assert f'uid="{uid}"' in metadata
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata
    assert '"vram_texture": true' in metadata

print("briar skulker audit passed")
