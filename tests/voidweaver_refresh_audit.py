#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re
import struct

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets" / "enemies" / "voidweaver"
CHARACTER = ASSETS / "voidweaver_character_spritesheet.png"
CHARACTER_MANIFEST = ASSETS / "voidweaver_character_spritesheet_manifest.json"
CHARACTER_IMPORT = ASSETS / "voidweaver_character_spritesheet.png.import"
EFFECTS = ASSETS / "voidweaver_effects_spritesheet.png"
EFFECTS_MANIFEST = ASSETS / "voidweaver_effects_spritesheet_manifest.json"
EFFECTS_IMPORT = ASSETS / "voidweaver_effects_spritesheet.png.import"
ACTOR_SCENE = ROOT / "scenes" / "actors" / "voidweaver.tscn"
PROJECTILE_SCENE = ROOT / "scenes" / "actors" / "voidweaver_projectile.tscn"

CHARACTER_UID = "uid://deg8cp3y18u0g"
EFFECTS_UID = "uid://dpug1hsf0de33"
CHARACTER_FRAME = (512, 768)
CHARACTER_SHEET = (2048, 4608)
EFFECT_FRAME = (256, 256)
EFFECT_SHEET = (1024, 512)
CHARACTER_PIXEL_SIZE = 0.0027333333
PROJECTILE_PIXEL_SIZE = 0.00235
IMPACT_PIXEL_SIZE = 0.00245


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    assert data[12:16] == b"IHDR", path
    return struct.unpack(">II", data[16:24])


character_manifest = json.loads(CHARACTER_MANIFEST.read_text(encoding="utf-8"))
effects_manifest = json.loads(EFFECTS_MANIFEST.read_text(encoding="utf-8"))
character_import = CHARACTER_IMPORT.read_text(encoding="utf-8")
effects_import = EFFECTS_IMPORT.read_text(encoding="utf-8")

assert png_size(CHARACTER) == CHARACTER_SHEET
assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == [
    "idle",
    "walk",
    "attack",
    "death",
    "idle_back",
    "walk_back",
]
assert all(row["frame_count"] == 4 for row in character_manifest["rows"])

assert png_size(EFFECTS) == EFFECT_SHEET
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]
assert all(row["frame_count"] == 4 for row in effects_manifest["rows"])

for metadata, uid in ((character_import, CHARACTER_UID), (effects_import, EFFECTS_UID)):
    assert f'uid="{uid}"' in metadata
    assert "compress/mode=2" in metadata
    assert "mipmaps/generate=true" in metadata
    assert "detect_3d/compress_to=0" in metadata
    assert '"vram_texture": true' in metadata

actor = ACTOR_SCENE.read_text(encoding="utf-8")
projectile = PROJECTILE_SCENE.read_text(encoding="utf-8")

assert (
    f'[ext_resource type="Texture2D" uid="{CHARACTER_UID}" '
    'path="res://assets/enemies/voidweaver/voidweaver_character_spritesheet.png" id="2_sheet"]'
    in actor
)
assert "voidweaver_spritesheet.png" not in actor
character_regions = {
    tuple(map(int, match))
    for match in re.findall(r"region = Rect2\((\d+), (\d+), 512, 768\)", actor)
}
assert character_regions == {
    (column * CHARACTER_FRAME[0], row * CHARACTER_FRAME[1])
    for row in range(6)
    for column in range(4)
}
for animation in ["idle", "walk", "attack", "death", "idle_back", "walk_back"]:
    assert f'"name": &"{animation}"' in actor, animation

assert re.search(r'^radius = 0\.45$', actor, re.M)
assert re.search(r'^height = 1\.9$', actor, re.M)
assert re.search(r'^pixel_size = 0\.0027333333$', actor, re.M)
assert re.search(r'^position = Vector3\(0, 0\.45, 0\)$', actor, re.M)
assert re.search(r'^sight_origin_height = 1\.2$', actor, re.M)
assert re.search(r'^projectile_spawn_height = 0\.71$', actor, re.M)
assert '0, -0.93, 0)' in actor
assert re.search(r'^combat_role = 1$', actor, re.M)
assert re.search(r'^maximum_health = 120$', actor, re.M)
assert re.search(r'^attack_range = 13\.5$', actor, re.M)
assert re.search(r'^attack_preferred_distance = 8\.5$', actor, re.M)
assert re.search(r'^weave_projectile_count = 3$', actor, re.M)
assert re.search(r'^weave_half_angle_degrees = 7\.0$', actor, re.M)
assert re.search(r'^weave_side_damage_scale = 0\.45$', actor, re.M)

assert (
    f'[ext_resource type="Texture2D" uid="{EFFECTS_UID}" '
    'path="res://assets/enemies/voidweaver/voidweaver_effects_spritesheet.png" id="2_effects_sheet"]'
    in projectile
)
assert "voidweaver_projectile_sheet.png" not in projectile
assert "voidweaver_impact_sheet.png" not in projectile
effect_regions = re.findall(r"region = Rect2\((\d+), (\d+), 256, 256\)", projectile)
assert len(effect_regions) == 8, len(effect_regions)
assert {tuple(map(int, region)) for region in effect_regions} == {
    (column * EFFECT_FRAME[0], row * EFFECT_FRAME[1])
    for row in range(2)
    for column in range(4)
}
assert 'sprite_frames = SubResource("SpriteFrames_projectile")' in projectile
assert 'sprite_frames = SubResource("SpriteFrames_impact")' in projectile
assert re.search(r'^pixel_size = 0\.00235$', projectile, re.M)
assert re.search(r'^pixel_size = 0\.00245$', projectile, re.M)
assert re.search(r'^speed = 18\.5$', projectile, re.M)
assert re.search(r'^radius = 0\.18$', projectile, re.M)

print("voidweaver refresh audit passed")
