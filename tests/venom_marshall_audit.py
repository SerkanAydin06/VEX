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
RUNTIME_TEST = ROOT / "tests/venom_marshall_runtime_test.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"

character_manifest = json.loads((ASSET / "venom_marshall_character_spritesheet_manifest.json").read_text(encoding="utf-8"))
effects_manifest = json.loads((ASSET / "venom_marshall_effects_spritesheet_manifest.json").read_text(encoding="utf-8"))
assert character_manifest["sheet_size"] == {"width": 2048, "height": 5376}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 7}
assert [row["animation"] for row in character_manifest["rows"]] == ["idle", "walk", "attack", "2nd_attack", "death", "idle_back", "walk_back"]
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 768}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 3}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "2nd_projectile", "impact"]

for import_name, uid in [
    ("venom_marshall_character_spritesheet.png.import", "uid://dcu2rdd7e43iq"),
    ("venom_marshall_effects_spritesheet.png.import", "uid://k0e1eq0x583e"),
]:
    text = (ASSET / import_name).read_text(encoding="utf-8")
    assert f'uid="{uid}"' in text, import_name
    assert "compress/mode=2" in text
    assert "mipmaps/generate=true" in text
    assert '"vram_texture": true' in text

actor = ACTOR.read_text(encoding="utf-8")
normal = NORMAL_PROJECTILE.read_text(encoding="utf-8")
buff = BUFF_PROJECTILE.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")
ability_script = ABILITY_SCRIPT.read_text(encoding="utf-8")
buff_script = BUFF_PROJECTILE_SCRIPT.read_text(encoding="utf-8")
status_script = BUFF_STATUS_SCRIPT.read_text(encoding="utf-8")
runtime_test = RUNTIME_TEST.read_text(encoding="utf-8")

for contract in [
    'enemy_id = &"venom_marshall"', "maximum_health = 155", "attack_damage = 16",
    "attack_range = 20.0", 'projectile_scene = ExtResource("3_projectile")',
    'special_ability_settings = SubResource("Resource_venom_marshall_ability")',
    '"name": &"2nd_attack"', "pixel_size = 0.0028", "billboard = 2",
]:
    assert contract in actor, contract
char_regions = re.findall(r"region = Rect2\((\d+), (\d+), 512, 768\)", actor)
assert len(char_regions) == 28
assert set(char_regions) == {(str(c * 512), str(r * 768)) for r in range(7) for c in range(4)}

for contract in [
    "class_name VexVenomMarshallAbilitySettings", "var buff_cast_range := 7.0",
    "var buff_cooldown := 11.5", "var second_attack_frame_y_offsets := PackedFloat32Array",
]:
    assert contract in ability_script, contract
for contract in [
    "var _ability: VexVenomMarshallAbilitySettings", 'animated_sprite.play(&"2nd_attack")',
    "func _deploy_buff_field() -> void:", 'projectile.call("deploy_at", global_position, self)',
]:
    assert contract in actor_script, contract

normal_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", normal)
assert len(normal_regions) == 8
assert set(normal_regions) == {(str(c * 256), "0") for c in range(4)} | {(str(c * 256), "512") for c in range(4)}
assert "pixel_size = 0.0026" in normal
assert "pixel_size = 0.0033" in normal

buff_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", buff)
assert len(buff_regions) == 12
# Both flight and the persistent field use the authored 2nd_projectile row;
# deploy impact uses the dedicated impact row.
assert buff_regions.count(("0", "256")) == 2
assert buff_regions.count(("256", "256")) == 2
assert buff_regions.count(("512", "256")) == 2
assert buff_regions.count(("768", "256")) == 2
assert {(x, y) for x, y in buff_regions if y == "512"} == {(str(c * 256), "512") for c in range(4)}
for contract in ["pixel_size = 0.0026", "pixel_size = 0.0546875", "pixel_size = 0.0068", "field_radius = 7.0", "damage_multiplier = 1.25"]:
    assert contract in buff, contract

for contract in ["func deploy_at(new_origin: Vector3, new_source: Node) -> void:", "get_overlapping_bodies()", "EnemyProjectilePool.recycle(self)"]:
    assert contract in buff_script, contract
for contract in ["class_name VexVenomMarshallBuffStatus", "func refresh_buff(", "func get_damage_multiplier() -> float:"]:
    assert contract in status_script, contract
assert "actor.special_ability_settings as VexVenomMarshallAbilitySettings" in runtime_test

level_test = LEVEL_TEST.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/venom_marshall.tscn"' in level_test
assert 'enemy_id = &"level_test_venom_marshall"' in level_test

print("Venom Marshall canonical sprite/VFX support audit passed")
