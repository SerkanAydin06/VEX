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
manifest = json.loads(read("assets/enemies/briar_skulker/spritesheet_manifest.json"))

assert manifest["sheet_size"] == {"width": 1364, "height": 3584}
assert manifest["frame_size"] == {"width": 341, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in manifest["rows"]] == [
    "idle", "walk", "attack", "attack_close", "death", "idle_back",
    "walk_back",
]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

assert not script.startswith("@tool\n")
assert not hybrid.startswith("@tool\n")
assert 'extends "res://scripts/actors/enemy_hybrid_base.gd"' in script
assert 'extends "res://scripts/actors/enemy_combatant_base.gd"' in hybrid
assert 'return &"hybrid"' in hybrid
assert "@export" not in hybrid
assert settings.startswith("@tool\n")

for token in [
    "prefer_melee_when_close", "_is_player_in_melee_envelope",
    "_resolve_melee_hit", "_resolve_ranged_shot", "attack_close",
]:
    assert token in hybrid or token in settings, token

for obsolete in [
    "DirectionalView", "mirror_opposite_directions", "source_frames_face_right",
    "front_diagonal_limit_degrees", "idle_front_side", "walk_front_side",
    "idle_side", "walk_side",
]:
    assert obsolete not in hybrid + settings + scene, obsolete

assert hybrid.index("prefer_melee_when_close") < hybrid.index("_begin_hybrid_attack(use_melee)")
assert 'special_ability_settings = SubResource("Resource_hybrid_settings")' in scene
assert 'projectile_scene = ExtResource("3_projectile")' in scene
assert 'enemy_id = &"briar_skulker"' in scene
assert 'combat_role = 1' in scene

atlas_regions = re.findall(
    r'\[sub_resource type="AtlasTexture" id="Atlas_[^"]+"\]\n'
    r'atlas = ExtResource\("2_sheet"\)\n'
    r'region = Rect2\((\d+), (\d+), 341, 512\)',
    scene,
)
assert len(atlas_regions) == 28, len(atlas_regions)
assert set(atlas_regions) == {
    (str(column * 341), str(row * 512))
    for row in range(7)
    for column in range(4)
}

animation_names = set(re.findall(r'"name": &"([^"]+)"', scene))
assert animation_names == {
    "idle", "walk", "attack", "attack_close", "death",
    "idle_back", "walk_back",
}

assert 'class_name VexBriarSkulkerProjectile' in projectile
for token in ["func launch(", "PhysicsRayQueryParameters3D.create", "take_damage", "source"]:
    assert token in projectile, token
assert 'collision_layer = 0' in projectile_scene
assert 'collision_mask = 11' in projectile_scene
assert 'shape = SubResource("SphereShape_projectile")' in projectile_scene

import_metadata = read(
    "assets/enemies/briar_skulker/briar_skulker_character_spritesheet.png.import"
)
assert 'uid="uid://d2briarsheet1"' in import_metadata
assert 'compress/mode=2' in import_metadata
assert 'mipmaps/generate=true' in import_metadata

print("briar skulker audit passed")
