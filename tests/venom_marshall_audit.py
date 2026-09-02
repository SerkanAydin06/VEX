#!/usr/bin/env python3
from __future__ import annotations

import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/enemies/venom_marshall"
ACTOR = ROOT / "scenes/actors/venom_marshall.tscn"
NORMAL_PROJECTILE = ROOT / "scenes/actors/venom_marshall_projectile.tscn"
BUFF_PROJECTILE = ROOT / "scenes/actors/venom_marshall_buff_projectile.tscn"
ACTOR_SCRIPT = ROOT / "scripts/actors/venom_marshall.gd"
BUFF_PROJECTILE_SCRIPT = ROOT / "scripts/actors/venom_marshall_buff_projectile.gd"
BUFF_STATUS_SCRIPT = ROOT / "scripts/actors/venom_marshall_buff_status.gd"
RUNTIME_TEST = ROOT / "tests/venom_marshall_runtime_test.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"

for path in [
    ACTOR,
    NORMAL_PROJECTILE,
    BUFF_PROJECTILE,
    ACTOR_SCRIPT,
    BUFF_PROJECTILE_SCRIPT,
    BUFF_STATUS_SCRIPT,
    RUNTIME_TEST,
]:
    assert path.exists(), path

character_manifest = json.loads(
    (ASSET / "venom_marshall_character_spritesheet_manifest.json").read_text(encoding="utf-8")
)
effects_manifest = json.loads(
    (ASSET / "venom_marshall_effects_spritesheet_manifest.json").read_text(encoding="utf-8")
)
assert character_manifest["sheet_size"] == {"width": 1364, "height": 3584}
assert character_manifest["frame_size"] == {"width": 341, "height": 512}
assert character_manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "2nd_attack", "death", "idle_back", "walk_back"
]
assert effects_manifest["sheet_size"] == {"width": 2048, "height": 1536}
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 3}
assert [row["animation"] for row in effects_manifest["rows"]] == [
    "projectile", "2nd_projectile", "impact"
]

for import_name in [
    "venom_marshall_character_spritesheet.png.import",
    "venom_marshall_effects_spritesheet.png.import",
]:
    import_text = (ASSET / import_name).read_text(encoding="utf-8")
    assert "compress/mode=0" in import_text, import_name
    assert "mipmaps/generate=true" in import_text, import_name

actor = ACTOR.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
normal_projectile = NORMAL_PROJECTILE.read_text(encoding="utf-8")
buff_projectile = BUFF_PROJECTILE.read_text(encoding="utf-8")
buff_script = BUFF_PROJECTILE_SCRIPT.read_text(encoding="utf-8")
status_script = BUFF_STATUS_SCRIPT.read_text(encoding="utf-8")

for contract in [
    'enemy_id = &"venom_marshall"',
    "combat_role = 1",
    "maximum_health = 155",
    "attack_damage = 16",
    "attack_range = 20.0",
    'projectile_scene = ExtResource("3_projectile")',
    'buff_projectile_scene = ExtResource("4_buff_projectile")',
    "buff_cooldown = 11.5",
    '"name": &"2nd_attack"',
    "pixel_size = 0.0042",
    "billboard = 2",
    "shaded = true",
]:
    assert contract in actor, contract

regions = re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", actor)
assert len(regions) == 28, len(regions)
expected_regions = [
    (str(column * 341), str(row * 512), "341", "512")
    for row in range(7)
    for column in range(4)
]
assert regions == expected_regions, regions

for contract in [
    "func _select_buff_target() -> Node3D:",
    "func _buff_cluster_score(",
    'animated_sprite.play(&"2nd_attack")',
    "func _fire_buff_projectile(",
    'projectile.call("launch_to", target_position, self)',
    'animation_name == &"2nd_attack"',
]:
    assert contract in actor_script, contract

for contract in [
    "field_radius = 5.6",
    "field_duration = 7.0",
    "field_tick_interval = 1.0",
    "heal_ratio_per_tick = 0.04",
    "damage_multiplier = 1.25",
    "buff_duration = 8.0",
    'shape = SubResource("CylinderShape_buff_field")',
    'sprite_frames = SubResource("SpriteFrames_field")',
]:
    assert contract in buff_projectile, contract

for contract in [
    "enum Phase",
    "Phase.FLIGHT",
    "Phase.FIELD",
    "func launch_to(",
    "func _deploy_field(",
    "get_overlapping_bodies()",
    "func _apply_support_pulse(target: Node) -> void:",
    'target.set("health", mini(maximum, current + heal_amount))',
    'target.get_node_or_null("VenomMarshallBuffStatus")',
    'status.call("refresh_buff", buff_duration, damage_multiplier)',
    "EnemyProjectilePool.recycle(self)",
]:
    assert contract in buff_script, contract

for contract in [
    "class_name VexVenomMarshallBuffStatus",
    "func refresh_buff(",
    "current_damage - _damage_bonus",
    "func _restore_damage() -> void:",
    "func get_remaining_time() -> float:",
]:
    assert contract in status_script, contract

assert "region = Rect2(0, 0, 512, 512)" in normal_projectile
assert "region = Rect2(0, 1024, 512, 512)" in normal_projectile

level_test = LEVEL_TEST.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/venom_marshall.tscn"' in level_test
assert 'enemy_id = &"level_test_venom_marshall"' in level_test

print("Venom Marshall ranged/support audit passed")
