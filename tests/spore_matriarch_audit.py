#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/enemies/spore_matriarch"
ACTOR = ROOT / "scenes/actors/spore_matriarch.tscn"
PROJECTILE_SCENE = ROOT / "scenes/actors/spore_matriarch_projectile.tscn"
ACTOR_SCRIPT = ROOT / "scripts/actors/spore_matriarch.gd"
PROJECTILE_SCRIPT = ROOT / "scripts/actors/spore_matriarch_projectile.gd"
POISON_SCRIPT = ROOT / "scripts/actors/spore_poison_status.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"

for path in [ACTOR, PROJECTILE_SCENE, ACTOR_SCRIPT, PROJECTILE_SCRIPT, POISON_SCRIPT]:
    assert path.exists(), path

character_manifest = json.loads(
    (ASSET / "spore_matriarch_character_spritesheet_manifest.json").read_text(encoding="utf-8")
)
effects_manifest = json.loads(
    (ASSET / "spore_matriarch_effects_spritesheet_manifest.json").read_text(encoding="utf-8")
)
assert character_manifest["sheet_size"] == {"width": 2048, "height": 2046}
assert character_manifest["frame_size"] == {"width": 512, "height": 341}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "death", "idle_back", "walk_back"
]
assert effects_manifest["sheet_size"] == {"width": 2048, "height": 512}
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 1}
assert effects_manifest["rows"][0]["animation"] == "projectile"

for import_name in [
    "spore_matriarch_character_spritesheet.png.import",
    "spore_matriarch_effects_spritesheet.png.import",
]:
    import_text = (ASSET / import_name).read_text(encoding="utf-8")
    assert "compress/mode=2" in import_text, import_name
    assert "mipmaps/generate=true" in import_text, import_name
    assert '"vram_texture": true' in import_text, import_name

actor = ACTOR.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
projectile_scene = PROJECTILE_SCENE.read_text(encoding="utf-8")
projectile_script = PROJECTILE_SCRIPT.read_text(encoding="utf-8")
poison_script = POISON_SCRIPT.read_text(encoding="utf-8")

assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in actor_script
for contract in [
    'enemy_id = &"spore_matriarch"',
    "combat_role = 1",
    "maximum_health = 165",
    "attack_damage = 12",
    "attack_range = 18.0",
    "attack_cooldown = 3.4",
    "attack_preferred_distance = 11.0",
    'projectile_scene = ExtResource("3_projectile")',
    "pixel_size = 0.0045",
    "billboard = 2",
    "shaded = true",
]:
    assert contract in actor, contract
assert "material_override" not in re.search(
    r'^\[node name="AnimatedSprite3D".*?(?=^\[node |\Z)', actor, re.M | re.S
).group(0)

regions = re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", actor)
assert len(regions) == 24, len(regions)
expected_regions = [
    (str(column * 512), str(row * 341), "512", "341")
    for row in range(6)
    for column in range(4)
]
assert regions == expected_regions, regions

for contract in [
    "field_radius = 5.2",
    "field_duration = 5.8",
    "field_tick_interval = 0.55",
    "poison_duration = 3.4",
    "poison_tick_interval = 0.75",
    'shape = SubResource("CylinderShape_poison_field")',
    "radius = 5.2",
    "height = 2.4",
]:
    assert contract in projectile_scene, contract

for contract in [
    "enum Phase",
    "Phase.FLIGHT",
    "Phase.FIELD",
    "func _deploy_field(",
    "get_overlapping_bodies()",
    'target.call("take_damage", damage, global_position, source)',
    'target.get_node_or_null("SporePoisonStatus")',
    'status.call(',
    '"refresh_poison"',
    "EnemyProjectilePool.recycle(self)",
]:
    assert contract in projectile_script, contract

for contract in [
    "class_name VexSporePoisonStatus",
    "func refresh_poison(",
    'target.call("take_damage"' if False else '_target.call("take_damage"',
    'SporePoisonOverlay',
    "queue_free()",
]:
    assert contract in poison_script, contract

level_test = LEVEL_TEST.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/spore_matriarch.tscn"' in level_test
assert 'enemy_id = &"level_test_spore_matriarch"' in level_test

print("Spore Matriarch support/poison audit passed")
