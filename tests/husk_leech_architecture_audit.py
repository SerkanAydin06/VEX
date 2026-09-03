#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]

actor_script = ROOT / "scripts/actors/husk_leech.gd"
projectile_script = ROOT / "scripts/actors/husk_leech_projectile.gd"
overlay_script = ROOT / "scripts/effects/husk_leech_venom_overlay.gd"
actor_scene = ROOT / "scenes/actors/husk_leech.tscn"
projectile_scene = ROOT / "scenes/actors/husk_leech_projectile.tscn"
canonical_test_scene = ROOT / "scenes/levels/level_test.tscn"
test_scene = ROOT / "scenes/levels/husk_leech_test.tscn"

for path in (
    actor_script,
    projectile_script,
    overlay_script,
    actor_scene,
    projectile_scene,
    canonical_test_scene,
    test_scene,
):
    assert path.is_file(), path

character_manifest = json.loads(
    (ROOT / "assets/enemies/husk_leech/husk_leech_character_spritesheet_manifest.json").read_text(encoding="utf-8")
)
projectile_manifest = json.loads(
    (ROOT / "assets/enemies/husk_leech/husk_leech_projectile_spritesheet_manifest.json").read_text(encoding="utf-8")
)
decal_manifest = json.loads(
    (ROOT / "assets/enemies/husk_leech/husk_leech_decal_spritesheet_manifest.json").read_text(encoding="utf-8")
)

assert character_manifest["sheet_size"] == {"width": 4096, "height": 3072}
assert character_manifest["frame_size"] == {"width": 512, "height": 512}
assert character_manifest["grid"] == {"columns": 8, "rows": 6}
assert [(row["animation"], row["frame_count"]) for row in character_manifest["rows"]] == [
    ("idle", 8),
    ("walk", 4),
    ("attack", 4),
    ("death", 4),
    ("idle_back", 4),
    ("walk_back", 4),
]

assert projectile_manifest["sheet_size"] == {"width": 5016, "height": 1254}
assert projectile_manifest["frame_size"] == {"width": 1254, "height": 1254}
assert projectile_manifest["grid"] == {"columns": 4, "rows": 1}

assert decal_manifest["sheet_size"] == {"width": 3344, "height": 235}
assert decal_manifest["frame_size"] == {"width": 418, "height": 235}
assert decal_manifest["grid"] == {"columns": 8, "rows": 1}

actor_source = actor_script.read_text(encoding="utf-8")
assert "class_name VexHuskLeech" in actor_source
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in actor_source
assert "@export" not in actor_source

scene_source = actor_scene.read_text(encoding="utf-8")
assert 'path="res://assets/enemies/husk_leech/husk_leech_character_spritesheet.png"' in scene_source
assert 'path="res://scenes/actors/husk_leech_projectile.tscn"' in scene_source
assert 'enemy_id = &"husk_leech"' in scene_source
assert "combat_role = 1" in scene_source
assert "maximum_health = 90" in scene_source
assert "attack_damage = 13" in scene_source
assert "attack_range = 16.0" in scene_source
assert "attack_cooldown = 2.0" in scene_source
assert "sight_origin_height = 1.25" in scene_source
assert "projectile_spawn_height = 1.15" in scene_source
assert "position = Vector3(0, 0.65, 0)" in scene_source

regions = [
    tuple(map(int, match))
    for match in re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", scene_source)
]
expected_regions = (
    [(x, 0, 512, 512) for x in range(0, 4096, 512)]
    + [(x, y, 512, 512) for y in (512, 1024, 1536, 2048, 2560) for x in range(0, 2048, 512)]
)
assert regions == expected_regions, (regions, expected_regions)

projectile_source = projectile_script.read_text(encoding="utf-8")
assert 'extends "res://scripts/actors/ravager_projectile.gd"' in projectile_source
assert 'preload("res://scripts/effects/husk_leech_venom_overlay.gd")' in projectile_source
assert 'target.is_in_group("player")' in projectile_source
assert "VenomOverlay.apply_to" in projectile_source

projectile_scene_source = projectile_scene.read_text(encoding="utf-8")
assert 'path="res://assets/enemies/husk_leech/husk_leech_projectile_spritesheet.png"' in projectile_scene_source
assert "venom_overlay_duration = 5.0" in projectile_scene_source
assert "venom_overlay_peak_alpha = 0.95" in projectile_scene_source
for x in (0, 1254, 2508, 3762):
    assert f"region = Rect2({x}, 0, 1254, 1254)" in projectile_scene_source

overlay_source = overlay_script.read_text(encoding="utf-8")
assert 'preload("res://assets/enemies/husk_leech/husk_leech_decal_spritesheet.png")' in overlay_source
assert "const FRAME_SIZE := Vector2i(418, 235)" in overlay_source
assert "const FRAME_COUNT := 8" in overlay_source
assert "const FIRST_PHASE_FRAME_COUNT := 4" in overlay_source
assert "const FIRST_PHASE_DURATION := 3.0" in overlay_source
assert "const SECOND_PHASE_DURATION := 2.0" in overlay_source
assert 'target.get_node_or_null(NODE_NAME)' in overlay_source
assert "refresh_effect(duration, peak_alpha)" in overlay_source
assert "STRETCH_KEEP_ASPECT_COVERED" in overlay_source
assert "mouse_filter = Control.MOUSE_FILTER_IGNORE" in overlay_source

canonical_test_source = canonical_test_scene.read_text(encoding="utf-8")
assert 'path="res://scenes/actors/husk_leech.tscn"' in canonical_test_source
assert '[node name="HuskLeech" parent="Enemies" instance=ExtResource("46_husk_leech")]' in canonical_test_source
assert 'enemy_id = &"level_test_husk_leech"' in canonical_test_source

test_source = test_scene.read_text(encoding="utf-8")
assert 'path="res://scenes/levels/level_test.tscn"' in test_source
assert 'path="res://scenes/actors/husk_leech.tscn"' not in test_source
assert '[node name="HuskLeech" parent="Enemies"]' in test_source
assert "maximum_health = 500" in test_source

print("husk leech architecture audit passed")
