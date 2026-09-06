#!/usr/bin/env python3
from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]

character_sheet = ROOT / "assets/enemies/veilmaw/veilmaw_character_spritesheet.png"
effects_sheet = ROOT / "assets/enemies/veilmaw/veilmaw_effects_spritesheet.png"
character_manifest_path = ROOT / "assets/enemies/veilmaw/veilmaw_character_spritesheet_manifest.json"
effects_manifest_path = ROOT / "assets/enemies/veilmaw/veilmaw_effects_spritesheet_manifest.json"
actor_scene = ROOT / "scenes/actors/veilmaw.tscn"
projectile_scene = ROOT / "scenes/actors/veilmaw_projectile.tscn"

for path in (
    character_sheet,
    effects_sheet,
    character_manifest_path,
    effects_manifest_path,
    actor_scene,
    projectile_scene,
    Path(f"{character_sheet}.import"),
    Path(f"{effects_sheet}.import"),
):
    assert path.is_file(), path

character_manifest = json.loads(character_manifest_path.read_text(encoding="utf-8"))
effects_manifest = json.loads(effects_manifest_path.read_text(encoding="utf-8"))

assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [(row["animation"], row["row_index"], row["frame_count"]) for row in character_manifest["rows"]] == [
    ("idle", 0, 4),
    ("walk", 1, 4),
    ("attack", 2, 4),
    ("death", 3, 4),
    ("idle_back", 4, 4),
    ("walk_back", 5, 4),
]

assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [(row["animation"], row["row_index"], row["frame_count"]) for row in effects_manifest["rows"]] == [
    ("projectile", 0, 4),
    ("impact", 1, 4),
]

scene_source = actor_scene.read_text(encoding="utf-8")
assert 'path="res://assets/enemies/veilmaw/veilmaw_character_spritesheet.png"' in scene_source
assert 'enemy_id = &"veilmaw"' in scene_source
assert "maximum_health = 105" in scene_source
assert "attack_damage = 16" in scene_source
assert "attack_range = 12.0" in scene_source
assert "attack_cooldown = 1.25" in scene_source
assert "attack_windup = 0.36" in scene_source
assert "projectile_spawn_height = 0.58" in scene_source
assert "projectile_spawn_forward_offset = 0.18" in scene_source
assert "projectile_target_height = 0.5" in scene_source
assert "pixel_size = 0.0027333333" in scene_source

regions = [
    tuple(map(int, match))
    for match in re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", scene_source)
]
expected_regions = [
    (x, y, 512, 768)
    for y in (1536, 2304, 0, 3072, 768, 3840)
    for x in (0, 512, 1024, 1536)
]
# Scene subresources are ordered attack, death, idle, idle_back, walk, walk_back.
assert regions == expected_regions, (regions, expected_regions)

for needle in (
    "idle_frame_y_offsets = PackedFloat32Array(0.0707, 0.1035, 0.0953, 0.0994)",
    "idle_back_frame_y_offsets = PackedFloat32Array(0.0953, 0.0953, 0.0953, 0.0953)",
    "walk_frame_y_offsets = PackedFloat32Array(0.0994, 0.1035, 0.1076, 0.1035)",
    "walk_back_frame_y_offsets = PackedFloat32Array(0.0789, 0.0871, 0.083, 0.0871)",
    "attack_frame_y_offsets = PackedFloat32Array(0.0994, 0.0953, 0.0912, 0.0953)",
    "death_frame_y_offsets = PackedFloat32Array(0.1035, 0.0953, 0.0953, 0.0871)",
):
    assert needle in scene_source

projectile_source = projectile_scene.read_text(encoding="utf-8")
assert 'path="res://assets/enemies/veilmaw/veilmaw_effects_spritesheet.png"' in projectile_source
for x in (0, 256, 512, 768):
    assert f"region = Rect2({x}, 0, 256, 256)" in projectile_source
    assert f"region = Rect2({x}, 256, 256, 256)" in projectile_source
assert "pixel_size = 0.0017" in projectile_source
assert "pixel_size = 0.0021" in projectile_source
assert "speed = 16.0" in projectile_source
assert "collision_mask = 11" in projectile_source

character_import = Path(f"{character_sheet}.import").read_text(encoding="utf-8")
effects_import = Path(f"{effects_sheet}.import").read_text(encoding="utf-8")
for import_source in (character_import, effects_import):
    assert 'compress/mode=2' in import_source
    assert 'mipmaps/generate=true' in import_source
    assert '"vram_texture": true' in import_source

print("veilmaw canonical spritesheet audit passed")
