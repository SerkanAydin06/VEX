#!/usr/bin/env python3
from pathlib import Path
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
SHEET = ROOT / "assets/enemies/magma_mauler/magma_mauler_character_spritesheet.png"
SCENE = ROOT / "scenes/experimental/magma_mauler.tscn"
SCRIPT = ROOT / "scripts/actors/magma_mauler.gd"
LEVEL = ROOT / "scripts/levels/level_test.gd"
IMPORT = ROOT / "assets/enemies/magma_mauler/magma_mauler_character_spritesheet.png.import"

assert SHEET.exists(), SHEET
raw = SHEET.read_bytes()
assert raw[:8] == b"\x89PNG\r\n\x1a\n"
width, height = struct.unpack(">II", raw[16:24])
assert (width, height) == (1364, 3072), (width, height)

scene = SCENE.read_text(encoding="utf-8")
script = SCRIPT.read_text(encoding="utf-8")
level = LEVEL.read_text(encoding="utf-8")
import_text = IMPORT.read_text(encoding="utf-8")

assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in script
assert 'enemy_id = &"magma_mauler"' in scene
assert "combat_role = 0" in scene
assert "maximum_health = 220" in scene
assert "attack_damage = 24" in scene
assert "pixel_size = 0.005" in scene
assert "billboard = 2" in scene
assert "shaded = true" in scene
assert "material_override" not in scene
assert "ShaderMaterial" not in scene
assert "radius = 0.72" in scene
assert "height = 2.4" in scene
assert "render_priority = -2" in scene
assert "0, -1.18, 0" in scene
assert "mipmaps/generate=true" in import_text

regions = re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", scene)
assert len(regions) == 24, len(regions)
expected = []
for row in range(6):
    for column in range(4):
        expected.append((str(column * 341), str(row * 512), "341", "512"))
assert regions == expected, regions

for animation in ["idle", "walk", "attack", "death", "idle_back", "walk_back"]:
    assert f'"name": &"{animation}"' in scene, animation

for property_name in [
    "idle_frame_y_offsets", "walk_frame_y_offsets", "attack_frame_y_offsets",
    "death_frame_y_offsets", "idle_back_frame_y_offsets", "walk_back_frame_y_offsets",
]:
    assert f"{property_name} = PackedFloat32Array(0.048, 0.048, 0.048, 0.048)" in scene

assert 'preload("res://scenes/experimental/magma_mauler.tscn")' in level
assert 'mauler.name = "MagmaMaulerPilot"' in level
assert 'mauler.position = Vector3(0.0, 1.22, -10.0)' in level
assert 'mauler.set("enemy_id", &"level_test_magma_mauler")' in level
assert "_spawn_magma_mauler_pilot()" in level
assert level.index("_spawn_magma_mauler_pilot()") < level.index("super._ready()")

print("Magma Mauler pilot audit passed")
