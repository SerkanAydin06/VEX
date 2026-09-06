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
RUNTIME_TEST = ROOT / "tests/spore_matriarch_runtime_test.gd"
LEVEL_TEST = ROOT / "scenes/levels/level_test.tscn"

for path in [ACTOR, PROJECTILE_SCENE, ACTOR_SCRIPT, PROJECTILE_SCRIPT, POISON_SCRIPT, RUNTIME_TEST]:
    assert path.exists(), path

character_manifest = json.loads((ASSET / "spore_matriarch_character_spritesheet_manifest.json").read_text(encoding="utf-8"))
effects_manifest = json.loads((ASSET / "spore_matriarch_effects_spritesheet_manifest.json").read_text(encoding="utf-8"))
assert character_manifest["sheet_size"] == {"width": 3072, "height": 3072}
assert character_manifest["frame_size"] == {"width": 768, "height": 512}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 256}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 1}
assert effects_manifest["rows"][0]["animation"] == "projectile"

for import_name, uid in [
    ("spore_matriarch_character_spritesheet.png.import", "uid://dl0orefhp7ru"),
    ("spore_matriarch_effects_spritesheet.png.import", "uid://jvbsftoxtpdf"),
]:
    text = (ASSET / import_name).read_text(encoding="utf-8")
    assert f'uid="{uid}"' in text, import_name
    assert "compress/mode=2" in text, import_name
    assert "mipmaps/generate=true" in text, import_name
    assert '"vram_texture": true' in text, import_name

actor = ACTOR.read_text(encoding="utf-8")
projectile_scene = PROJECTILE_SCENE.read_text(encoding="utf-8")
projectile_script = PROJECTILE_SCRIPT.read_text(encoding="utf-8")
poison_script = POISON_SCRIPT.read_text(encoding="utf-8")
runtime_test = RUNTIME_TEST.read_text(encoding="utf-8")
actor_script = ACTOR_SCRIPT.read_text(encoding="utf-8")

assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in actor_script
for contract in [
    'enemy_id = &"spore_matriarch"', "maximum_health = 165", "attack_damage = 12",
    "attack_range = 18.0", "attack_cooldown = 3.4", "attack_preferred_distance = 11.0",
    'projectile_scene = ExtResource("3_projectile")', "pixel_size = 0.0029970703", "billboard = 2",
]:
    assert contract in actor, contract
regions = re.findall(r"region = Rect2\((\d+), (\d+), 768, 512\)", actor)
assert len(regions) == 24
assert set(regions) == {(str(c * 768), str(r * 512)) for r in range(6) for c in range(4)}

fx_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", projectile_scene)
assert len(fx_regions) == 4
assert set(fx_regions) == {(str(c * 256), "0") for c in range(4)}
for contract in [
    "field_radius = 5.2", "field_duration = 5.8", "field_tick_interval = 0.55",
    "poison_duration = 3.4", "poison_tick_interval = 0.75",
    "pixel_size = 0.0027", "pixel_size = 0.0084", "pixel_size = 0.0072",
]:
    assert contract in projectile_scene, contract
for contract in [
    "Phase.FLIGHT", "Phase.FIELD", "func _deploy_field(", "get_overlapping_bodies()",
    "EnemyProjectilePool.recycle(self)", 'target.get_node_or_null("SporePoisonStatus")',
]:
    assert contract in projectile_script, contract
for contract in ["class_name VexSporePoisonStatus", "func refresh_poison(", "SporePoisonOverlay", "queue_free()"]:
    assert contract in poison_script, contract
assert '_count_named_children(target, "SporePoisonStatus") == 1' in runtime_test

level_test = LEVEL_TEST.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/spore_matriarch.tscn"' in level_test
assert 'enemy_id = &"level_test_spore_matriarch"' in level_test

print("Spore Matriarch support/poison audit passed")
