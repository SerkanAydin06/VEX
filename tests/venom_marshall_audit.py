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
ABILITY_SCRIPT = ROOT / "scripts/actors/venom_marshall_ability_settings.gd"
BUFF_PROJECTILE_SCRIPT = ROOT / "scripts/actors/venom_marshall_buff_projectile.gd"
BUFF_STATUS_SCRIPT = ROOT / "scripts/actors/venom_marshall_buff_status.gd"
ENEMY_BASE_SCRIPT = ROOT / "scripts/actors/enemy_base.gd"
WARDEN_SCRIPT = ROOT / "scripts/actors/crucible_warden.gd"
FURNACE_SCRIPT = ROOT / "scripts/actors/furnice_carrier.gd"
HYBRID_SCRIPT = ROOT / "scripts/actors/enemy_hybrid_base.gd"
RUNTIME_TEST = ROOT / "tests/venom_marshall_runtime_test.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"

for path in [
    ACTOR,
    NORMAL_PROJECTILE,
    BUFF_PROJECTILE,
    ACTOR_SCRIPT,
    ABILITY_SCRIPT,
    BUFF_PROJECTILE_SCRIPT,
    BUFF_STATUS_SCRIPT,
    ENEMY_BASE_SCRIPT,
    WARDEN_SCRIPT,
    FURNACE_SCRIPT,
    HYBRID_SCRIPT,
    RUNTIME_TEST,
]:
    assert path.exists(), path

character_manifest = json.loads(
    (ASSET / "venom_marshall_character_spritesheet_manifest.json").read_text(encoding="utf-8")
)
effects_manifest = json.loads(
    (ASSET / "venom_marshall_effects_spritesheet_manifest.json").read_text(encoding="utf-8")
)
assert character_manifest["sheet_size"] == {"width": 2048, "height": 5376}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle", "walk", "attack", "2nd_attack", "death", "idle_back", "walk_back"
]
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 768}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 3}
assert [row["animation"] for row in effects_manifest["rows"]] == [
    "projectile", "2nd_projectile", "impact"
]

for import_name, uid in [
    ("venom_marshall_character_spritesheet.png.import", "uid://dcu2rdd7e43iq"),
    ("venom_marshall_effects_spritesheet.png.import", "uid://k0e1eq0x583e"),
]:
    import_text = (ASSET / import_name).read_text(encoding="utf-8")
    assert f'uid="{uid}"' in import_text, import_name
    assert "compress/mode=2" in import_text, import_name
    assert "mipmaps/generate=true" in import_text, import_name
    assert '"vram_texture": true' in import_text, import_name

actor = ACTOR.read_text(encoding="utf-8")
normal_projectile = NORMAL_PROJECTILE.read_text(encoding="utf-8")
buff_projectile = BUFF_PROJECTILE.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
ability_script = ABILITY_SCRIPT.read_text(encoding="utf-8")
buff_script = BUFF_PROJECTILE_SCRIPT.read_text(encoding="utf-8")
status_script = BUFF_STATUS_SCRIPT.read_text(encoding="utf-8")
enemy_base_script = ENEMY_BASE_SCRIPT.read_text(encoding="utf-8")
warden_script = WARDEN_SCRIPT.read_text(encoding="utf-8")
furnace_script = FURNACE_SCRIPT.read_text(encoding="utf-8")
hybrid_script = HYBRID_SCRIPT.read_text(encoding="utf-8")
runtime_test = RUNTIME_TEST.read_text(encoding="utf-8")

for contract in [
    'enemy_id = &"venom_marshall"',
    "combat_role = 1",
    "maximum_health = 155",
    "attack_damage = 16",
    "attack_range = 20.0",
    'projectile_scene = ExtResource("3_projectile")',
    'special_ability_settings = SubResource("Resource_venom_marshall_ability")',
    "buff_cast_range = 7.0",
    "buff_cooldown = 11.5",
    '"name": &"2nd_attack"',
    "pixel_size = 0.0028",
    "billboard = 2",
    "shaded = true",
]:
    assert contract in actor, contract

for retired_contract in [
    "buff_cluster_radius =",
    "buff_spawn_height =",
    "buff_spawn_forward_offset =",
]:
    assert retired_contract not in actor, retired_contract

char_regions = re.findall(r"region = Rect2\((\d+), (\d+), 512, 768\)", actor)
assert len(char_regions) == 28, len(char_regions)
assert char_regions == [
    (str(column * 512), str(row * 768))
    for row in range(7)
    for column in range(4)
], char_regions

for contract in [
    "class_name VexVenomMarshallAbilitySettings",
    "extends VexEnemyAbilitySettings",
    '@export_category("01 - Alan Desteği")',
    '@export_category("02 - Görsel Hizalama")',
    "var buff_cast_range := 7.0",
    "var buff_cooldown := 11.5",
    "var buff_windup := 0.65",
    "var buff_recovery := 0.80",
    "var buff_refresh_window := 1.2",
    "var second_attack_frame_y_offsets := PackedFloat32Array",
]:
    assert contract in ability_script, contract

assert "@export" not in actor_script
for contract in [
    "var _ability: VexVenomMarshallAbilitySettings",
    "_ability = special_ability_settings as VexVenomMarshallAbilitySettings",
    "func _has_buff_candidate_in_self_field() -> bool:",
    "_horizontal_distance(global_position, ally.global_position) <= _ability.buff_cast_range",
    'animated_sprite.play(&"2nd_attack")',
    "func _deploy_buff_field() -> void:",
    "EnemyProjectilePool.acquire(_ability.buff_projectile_scene, projectile_parent)",
    "projectile.global_position = global_position",
    'projectile.call("deploy_at", global_position, self)',
    'animation_name == &"2nd_attack"',
    "_ability.second_attack_frame_y_offsets",
]:
    assert contract in actor_script, contract

# Buff attack timing must keep following the scene-authored difficulty profile.
for contract in [
    "var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)",
    "var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)",
    "_ability.buff_cooldown * cooldown_scale",
    "var runtime_recovery := maxf(0.0, _ability.buff_recovery * cooldown_scale)",
    "create_timer(runtime_recovery)",
]:
    assert contract in actor_script, contract

for retired_contract in [
    "func _select_buff_target() -> Node3D:",
    "func _buff_cluster_score(",
    "func _fire_buff_projectile(",
    'projectile.call("launch_to", target_position, self)',
    "buff_cluster_radius",
    "buff_spawn_height",
    "buff_spawn_forward_offset",
    '@export_category("10 - Venom Marshall Alan Desteği")',
]:
    assert retired_contract not in actor_script, retired_contract

normal_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", normal_projectile)
assert len(normal_regions) == 8
assert set(normal_regions) == (
    {(str(column * 256), "0") for column in range(4)}
    | {(str(column * 256), "512") for column in range(4)}
)
assert "pixel_size = 0.0026" in normal_projectile
assert "pixel_size = 0.0033" in normal_projectile

buff_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", buff_projectile)
assert len(buff_regions) == 12
# Flight and persistent field intentionally share the authored 2nd_projectile
# row; deploy impact uses the dedicated impact row.
for x in ("0", "256", "512", "768"):
    assert buff_regions.count((x, "256")) == 2, (x, buff_regions)
assert {(x, y) for x, y in buff_regions if y == "512"} == {
    (str(column * 256), "512") for column in range(4)
}
for contract in [
    "field_radius = 7.0",
    "field_duration = 7.0",
    "field_tick_interval = 1.0",
    "heal_ratio_per_tick = 0.04",
    "damage_multiplier = 1.25",
    "buff_duration = 8.0",
    "radius = 7.0",
    "top_radius = 7.0",
    "bottom_radius = 7.0",
    "pixel_size = 0.0026",
    "pixel_size = 0.0546875",
    "pixel_size = 0.0068",
    "omni_range = 8.0",
    'shape = SubResource("CylinderShape_buff_field")',
    'sprite_frames = SubResource("SpriteFrames_field")',
]:
    assert contract in buff_projectile, contract

for contract in [
    "enum Phase",
    "Phase.FLIGHT",
    "Phase.FIELD",
    "func launch_to(",
    "func deploy_at(new_origin: Vector3, new_source: Node) -> void:",
    "global_position = new_origin",
    "_deploy_field(new_origin)",
    "func _deploy_field(",
    "get_overlapping_bodies()",
    "func _apply_support_pulse(target: Node) -> void:",
    'target.set("health", mini(maximum, current + heal_amount))',
    'target.get_node_or_null("VenomMarshallBuffStatus")',
    'status.call("refresh_buff", buff_duration, damage_multiplier)',
    'ground_field_visual.sprite_frames.get_frame_texture(&"default", 0)',
    "ground_field_visual.pixel_size = field_radius * 2.0 / field_frame_width",
    "EnemyProjectilePool.recycle(self)",
]:
    assert contract in buff_script, contract

# The field is ally-only and may never buff its own Marshall source.
for contract in [
    "field_collision_mask := 4",
    "if target == null or target == _valid_source():",
    'current.is_in_group("enemy")',
]:
    assert contract in buff_script, contract

for contract in [
    "class_name VexVenomMarshallBuffStatus",
    "func refresh_buff(",
    "current_damage - _damage_bonus",
    "var _damage_multiplier := 1.0",
    "_damage_multiplier = maxf(damage_multiplier, 1.0)",
    "func get_damage_multiplier() -> float:",
    "return _damage_multiplier",
    "func _restore_damage() -> void:",
    "func get_remaining_time() -> float:",
]:
    assert contract in status_script, contract

# Normal attacks are already buffed through _runtime_attack_damage. Special
# attacks have their own authored base damage, so all of them must use the same
# support multiplier after optional difficulty scaling.
for contract in [
    "func _apply_active_damage_support(damage_value: int) -> int:",
    'get_node_or_null("VenomMarshallBuffStatus")',
    'has_method("get_damage_multiplier")',
    'call("get_damage_multiplier")',
]:
    assert contract in enemy_base_script, contract

for script_name, source, function_name in [
    ("crucible_warden.gd", warden_script, "_scaled_special_damage"),
    ("furnice_carrier.gd", furnace_script, "_scaled_special_damage"),
    ("enemy_hybrid_base.gd", hybrid_script, "_scaled_hybrid_damage"),
]:
    assert f"func {function_name}(" in source, script_name
    assert "if apply_difficulty_scaling:" in source, script_name
    assert "_scene_difficulty_multiplier(difficulty_damage_multipliers)" in source, script_name
    assert "return _apply_active_damage_support(scaled_damage)" in source, script_name

for contract in [
    "actor.special_ability_settings as VexVenomMarshallAbilitySettings",
    "ability.buff_cast_range, 7.0",
    'actor.call("_has_buff_candidate_in_self_field")',
    "projectile.field_radius, 7.0",
    "ground_visual.pixel_size, 14.0 / 256.0",
    "projectile.deploy_at(actor.global_position, actor)",
    "projectile.global_position.x, actor.global_position.x",
    "projectile.global_position.z, actor.global_position.z",
    "status.get_damage_multiplier(), 1.25",
]:
    assert contract in runtime_test, contract

level_test = LEVEL_TEST.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/venom_marshall.tscn"' in level_test
assert 'enemy_id = &"level_test_venom_marshall"' in level_test

print("Venom Marshall canonical sprite/VFX and support audit passed")
