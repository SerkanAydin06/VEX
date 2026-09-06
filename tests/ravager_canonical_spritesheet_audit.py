#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
ASSET = ROOT / "assets/enemies/ravager"
SCENE = ROOT / "scenes/actors/ravager.tscn"
PROJECTILE = ROOT / "scenes/actors/ravager_projectile.tscn"

character_manifest = json.loads((ASSET / "ravager_character_spritesheet_manifest.json").read_text(encoding="utf-8"))
effects_manifest = json.loads((ASSET / "ravager_effects_spritesheet_manifest.json").read_text(encoding="utf-8"))
assert character_manifest["sheet_size"] == {"width": 2048, "height": 4608}
assert character_manifest["frame_size"] == {"width": 512, "height": 768}
assert character_manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in character_manifest["rows"]] == ["idle", "walk", "attack", "death", "idle_back", "walk_back"]
assert effects_manifest["sheet_size"] == {"width": 1024, "height": 512}
assert effects_manifest["frame_size"] == {"width": 256, "height": 256}
assert effects_manifest["grid"] == {"columns": 4, "rows": 2}
assert [row["animation"] for row in effects_manifest["rows"]] == ["projectile", "impact"]

scene = SCENE.read_text(encoding="utf-8")
projectile = PROJECTILE.read_text(encoding="utf-8")
for contract in [
    'path="res://assets/enemies/ravager/ravager_character_spritesheet.png"',
    'enemy_id = &"ravager"', "combat_role = 2", "attack_damage = 14",
    "attack_range = 20.0", "projectile_spawn_height = -0.16",
    "projectile_spawn_side_offset = -0.45", "pixel_size = 0.00235",
]:
    assert contract in scene, contract
assert "ravager_spritesheet.png" not in scene
regions = re.findall(r'region = Rect2\((\d+), (\d+), 512, 768\)', scene)
assert len(regions) == 24
assert set(regions) == {(str(c * 512), str(r * 768)) for r in range(6) for c in range(4)}

assert 'path="res://assets/enemies/ravager/ravager_effects_spritesheet.png"' in projectile
assert "ravager_projectile_sheet.png" not in projectile
assert "ravager_impact_sheet.png" not in projectile
fx_regions = re.findall(r'region = Rect2\((\d+), (\d+), 256, 256\)', projectile)
assert len(fx_regions) == 8
assert set(fx_regions) == {(str(c * 256), str(r * 256)) for r in range(2) for c in range(4)}
assert projectile.count("pixel_size = 0.00195") == 2

for import_name, uid in [
    ("ravager_character_spritesheet.png.import", "uid://cd067ng1bxgx7"),
    ("ravager_effects_spritesheet.png.import", "uid://pj8pitnfjxbf"),
]:
    text = (ASSET / import_name).read_text(encoding="utf-8")
    assert f'uid="{uid}"' in text, import_name
    assert "compress/mode=2" in text
    assert "mipmaps/generate=true" in text
    assert '"vram_texture": true' in text

print("ravager canonical spritesheet audit passed")
