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


scene = read("scenes/actors/gorehorn.tscn")
script = read("scripts/actors/gorehorn.gd")
settings = read("scripts/actors/gorehorn_charge_settings.gd")
lunge_base = read("scripts/actors/enemy_lunge_base.gd")
player = read("scripts/player/player.gd")
level_test = read("scenes/levels/level_test.tscn")
standard = read("STANDART.txt")
enemy_guide = read("Enemies_VEX.md")
manifest = json.loads(read("assets/enemies/gorehorn/spritesheet_manifest.json"))

assert (ROOT / "assets/enemies/gorehorn/gorehorn_character_spritesheet.png").exists()
assert manifest["sheet_size"] == {"width": 1364, "height": 3072}
assert manifest["frame_size"] == {"width": 341, "height": 512}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == [
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

assert not script.startswith("@tool\n")
assert '@export' not in script
assert 'extends "res://scripts/actors/enemy_lunge_base.gd"' in script
assert 'return &"charge"' in script
assert settings.startswith("@tool\n")
assert "class_name VexGorehornChargeSettings" in settings
assert "extends VexEnemyAbilitySettings" in settings
assert "vertical_hit_tolerance" in settings
assert "special_ability_settings: VexEnemyAbilitySettings" in lunge_base
assert "@export_range(0.5, 16.0, 0.05) var attack_range" in lunge_base

for token in [
    "_charge_direction = _player.global_position - global_position",
    "await get_tree().physics_frame",
    "func _resolve_charge_contact()",
    "func _is_player_within_charge_hit_volume(",
    "settings.vertical_hit_tolerance",
    "func _cancel_charge_attack()",
    "func _has_valid_player()",
    "_attack_generation += 1",
    "func _apply_charge_hit(",
    '"apply_external_impulse"',
    '"request_camera_shake"',
    '"request_impact_shock"',
    "_charge_hit_player",
    "blocked_recovery_duration",
]:
    assert token in script, token

current_attack = script[script.index("func _is_current_charge_attack("):]
current_attack = current_attack[:current_attack.index("\n\nfunc ", 5)]
assert "_player" not in current_attack, current_attack

for token in [
    "func apply_external_impulse(",
    "func request_camera_shake(",
    "func request_impact_shock(",
    "func _ensure_impact_shock_overlay(",
    "ImpactShockOverlay",
    "SettingsManager.screen_shake",
    "_update_impact_camera_shake(delta)",
]:
    assert token in player, token

assert 'enemy_id = &"gorehorn"' in scene
assert "combat_role = 0" in scene
assert "maximum_health = 180" in scene
assert "attack_range = 12.0" in scene
assert "attack_lunge_speed = 18.0" in scene
assert "attack_lunge_duration = 0.82" in scene
assert "knockback_horizontal_speed = 13.5" in scene
assert "knockback_duration = 0.44" in scene
assert "impact_shake_strength = 0.135" in scene
assert "impact_shock_peak_alpha = 0.38" in scene
assert "impact_shock_duration = 0.24" in scene
assert 'special_ability_settings = SubResource("Resource_gorehorn_charge")' in scene
assert 'billboard = 2' in scene
assert 'offset = Vector2(0, 16)' in scene
assert 'render_priority = -2' in scene

atlas_regions = re.findall(
    r'\[sub_resource type="AtlasTexture" id="Atlas_[^"]+"\]\n'
    r'atlas = ExtResource\("2_sheet"\)\n'
    r'region = Rect2\((\d+), (\d+), 341, 512\)',
    scene,
)
assert len(atlas_regions) == 24, len(atlas_regions)
assert set(atlas_regions) == {
    (str(column * 341), str(row * 512))
    for row in range(6)
    for column in range(4)
}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {
    "idle", "walk", "attack", "death", "idle_back", "walk_back",
}
assert '&"hurt"' not in scene

assert 'path="res://scenes/actors/gorehorn.tscn"' in level_test
assert '[node name="Gorehorn" parent="Enemies"' in level_test
assert 'enemy_id = &"level_test_gorehorn"' in level_test

import_metadata = read(
    "assets/enemies/gorehorn/gorehorn_character_spritesheet.png.import"
)
assert 'uid="uid://de8pocibc4fol"' in import_metadata
assert 'compress/mode=2' in import_metadata
assert 'mipmaps/generate=true' in import_metadata
assert "Gorehorn şarj saldırısı standardı" in standard
assert "### 3. Gorehorn\n\n**Durum:** Mevcut" in enemy_guide

print("gorehorn audit passed")
