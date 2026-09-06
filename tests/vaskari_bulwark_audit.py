#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import json
import re

ROOT = Path(__file__).resolve().parents[1]
SCENE = ROOT / "scenes/actors/vaskari_bulwark.tscn"
SCRIPT = ROOT / "scripts/actors/vaskari_bulwark.gd"
MANIFEST = ROOT / "assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet_manifest.json"
IMPORT = ROOT / "assets/enemies/vaskari_bulwark/vaskari_bulwark_character_spritesheet.png.import"
ANIM_ROWS = ["idle", "walk", "attack", "death", "idle_back", "walk_back"]

manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
assert manifest["sheet_size"] == {"width": 3072, "height": 4608}
assert manifest["frame_size"] == {"width": 768, "height": 768}
assert manifest["grid"] == {"columns": 4, "rows": 6}
assert [row["animation"] for row in manifest["rows"]] == ANIM_ROWS
assert all(row["frame_count"] == 4 for row in manifest["rows"])

script = SCRIPT.read_text(encoding="utf-8")
assert "class_name VexVaskariBulwark" in script
assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in script
scene = SCENE.read_text(encoding="utf-8")
for contract in [
    'enemy_id = &"vaskari_bulwark"', "maximum_health = 300", "attack_damage = 30",
    "attack_range = 2.15", "attack_cooldown = 1.55", "attack_windup = 0.40",
    "attack_lunge_speed = 6.0", "position = Vector3(0, 0.0884, 0)",
    "pixel_size = 0.0034666667", "billboard = 2",
]:
    assert contract in scene, contract

regions = re.findall(r'region = Rect2\((\d+), (\d+), 768, 768\)', scene)
assert len(regions) == 24, len(regions)
assert set(regions) == {(str(c * 768), str(r * 768)) for r in range(6) for c in range(4)}
assert set(re.findall(r'"name": &"([^"]+)"', scene)) == set(ANIM_ROWS)

import_text = IMPORT.read_text(encoding="utf-8")
assert 'uid="uid://brcm2knf8hn6k"' in import_text
assert "compress/mode=2" in import_text
assert "mipmaps/generate=true" in import_text
assert '"vram_texture": true' in import_text

# Alpha-floor validation is centralized in enemy_sprite_contact_audit.py so the
# authored 768x768 exception is validated from the real PNG rather than a fixed
# portrait assumption.
contact_audit = (ROOT / "tests/enemy_sprite_contact_audit.py").read_text(encoding="utf-8")
assert '"vaskari_bulwark": "vaskari_bulwark.tscn"' in contact_audit

print("vaskari bulwark audit passed")
