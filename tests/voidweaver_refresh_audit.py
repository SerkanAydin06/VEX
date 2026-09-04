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
EFFECTS = ASSETS / "voidweaver_effects_spritesheet.png"
EFFECTS_MANIFEST = ASSETS / "voidweaver_effects_spritesheet_manifest.json"
ACTOR_SCENE = ROOT / "scenes" / "actors" / "voidweaver.tscn"
PROJECTILE_SCENE = ROOT / "scenes" / "actors" / "voidweaver_projectile.tscn"

CHARACTER_UID = "uid://deg8cp3y18u0g"
EFFECTS_UID = "uid://dpug1hsf0de33"


def png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()[:24]
    assert data[:8] == b"\x89PNG\r\n\x1a\n", path
    assert data[12:16] == b"IHDR", path
    return struct.unpack(">II", data[16:24])


character_manifest = json.loads(CHARACTER_MANIFEST.read_text(encoding="utf-8"))
effects_manifest = json.loads(EFFECTS_MANIFEST.read_text(encoding="utf-8"))

assert png_size(CHARACTER) == (1364, 3072)
assert character_manifest["sheet_size"] == {"width": 1364, "height": 3072}
assert character_manifest["frame_size"] == {"width": 341, "height": 512}
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

assert png_size(EFFECTS) == (2048, 1024)
assert effects_manifest["sheet_size"] == {"width": 2048, "height": 1024}
assert effects_manifest["frame_size"] == {"width": 512, "height": 512}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]
assert all(row["frame_count"] == 4 for row in effects_manifest["rows"])

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
    for match in re.findall(r"region = Rect2\((\d+), (\d+), 341, 512\)", actor)
}
assert character_regions == {
    (column * 341, row * 512)
    for row in range(6)
    for column in range(4)
}
for animation in ["idle", "walk", "attack", "death", "idle_back", "walk_back"]:
    assert f'"name": &"{animation}"' in actor, animation

assert re.search(r'^radius = 0\.45$', actor, re.M)
assert re.search(r'^height = 1\.9$', actor, re.M)
assert re.search(r'^pixel_size = 0\.0041$', actor, re.M)
assert re.search(r'^position = Vector3\(0, 0\.45, 0\)$', actor, re.M)
assert re.search(r'^sight_origin_height = 1\.2$', actor, re.M)
assert re.search(r'^projectile_spawn_height = 0\.55$', actor, re.M)
assert '0, -0.93, 0)' in actor
assert re.search(r'^combat_role = 1$', actor, re.M)
assert re.search(r'^maximum_health = 120$', actor, re.M)
assert re.search(r'^attack_range = 13\.5$', actor, re.M)
assert re.search(r'^attack_preferred_distance = 8\.5$', actor, re.M)

assert (
    f'[ext_resource type="Texture2D" uid="{EFFECTS_UID}" '
    'path="res://assets/enemies/voidweaver/voidweaver_effects_spritesheet.png" id="2_effects_sheet"]'
    in projectile
)
assert "voidweaver_projectile_sheet.png" not in projectile
assert "voidweaver_impact_sheet.png" not in projectile
effect_regions = re.findall(r"region = Rect2\((\d+), (\d+), 512, 512\)", projectile)
assert len(effect_regions) == 8, len(effect_regions)
assert {tuple(map(int, region)) for region in effect_regions} == {
    (column * 512, row * 512)
    for row in range(2)
    for column in range(4)
}
assert 'sprite_frames = SubResource("SpriteFrames_projectile")' in projectile
assert 'sprite_frames = SubResource("SpriteFrames_impact")' in projectile
assert re.search(r'^speed = 18\.5$', projectile, re.M)
assert re.search(r'^radius = 0\.18$', projectile, re.M)

print("voidweaver refresh audit passed")
