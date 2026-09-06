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
player = read("scripts/player/player.gd")
level_test = read("scenes/levels/level_test.tscn")
manifest = json.loads(read("assets/enemies/gorehorn/gorehorn_character_spritesheet_manifest.json"))

assert manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert manifest["frame_size"] == {"width": 512, "height": 768}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
assert all(row["frame_count"] == 4 for row in manifest["rows"])

assert 'extends "res://scripts/actors/enemy_lunge_base.gd"' in script
assert 'return &"charge"' in script
assert settings.startswith("@tool\n")
for token in [
    "_charge_direction = _player.global_position - global_position", "func _resolve_charge_contact()",
    "func _apply_charge_hit(", '"apply_external_impulse"', '"request_camera_shake"',
    '"request_impact_shock"', "blocked_recovery_duration",
]:
    assert token in script, token
for token in ["func apply_external_impulse(", "func request_camera_shake(", "func request_impact_shock("]:
    assert token in player, token

for token in [
    'enemy_id = &"gorehorn"', "maximum_health = 180", "attack_range = 12.0",
    "attack_lunge_speed = 18.0", "attack_lunge_duration = 0.82",
    "knockback_horizontal_speed = 13.5", "impact_shake_strength = 0.135",
    "impact_shock_peak_alpha = 0.38", "pixel_size = 0.0034666667", "billboard = 2",
]:
    assert token in scene, token

regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 768\)', scene)
assert len(regions) == 24
assert set(regions) == {(str(c * 512), str(r * 768)) for r in range(6) for c in range(4)}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == {"idle", "walk", "attack", "death", "idle_back", "walk_back"}

assert 'path="res://scenes/actors/gorehorn.tscn"' in level_test
assert 'enemy_id = &"level_test_gorehorn"' in level_test
import_metadata = read("assets/enemies/gorehorn/gorehorn_character_spritesheet.png.import")
assert 'uid="uid://de8pocibc4fol"' in import_metadata
assert "compress/mode=2" in import_metadata
assert "mipmaps/generate=true" in import_metadata
assert '"vram_texture": true' in import_metadata

print("gorehorn audit passed")
