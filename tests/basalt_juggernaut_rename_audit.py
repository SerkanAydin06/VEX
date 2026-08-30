#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
OLD_PATTERN = re.compile("hell" + r"[_\s-]?" + "magma", re.IGNORECASE)

required_files = [
    "scripts/actors/basalt_juggernaut.gd",
    "scripts/actors/basalt_juggernaut.gd.uid",
    "scenes/actors/basalt_juggernaut.tscn",
    "scenes/actors/basalt_juggernaut_projectile.tscn",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_spritesheet.png",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_spritesheet.png.import",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_projectile_sheet.png",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_projectile_sheet.png.import",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_impact_sheet.png",
    "assets/enemies/basalt_juggernaut/basalt_juggernaut_impact_sheet.png.import",
    "assets/audio/basalt_juggernaut_attack.wav",
    "assets/audio/basalt_juggernaut_attack.wav.import",
    "assets/audio/basalt_juggernaut_hurt.wav",
    "assets/audio/basalt_juggernaut_hurt.wav.import",
    "assets/audio/basalt_juggernaut_death.wav",
    "assets/audio/basalt_juggernaut_death.wav.import",
]
for relative in required_files:
    assert (ROOT / relative).is_file(), relative

text_suffixes = {".gd", ".godot", ".import", ".md", ".py", ".tres", ".tscn", ".txt", ".uid", ".csv"}
for path in ROOT.rglob("*"):
    if not path.is_file() or path == Path(__file__) or path.suffix not in text_suffixes:
        continue
    source = path.read_text(encoding="utf-8")
    assert OLD_PATTERN.search(source) is None, path.relative_to(ROOT)

scene = (ROOT / "scenes/actors/basalt_juggernaut.tscn").read_text(encoding="utf-8")
script = (ROOT / "scripts/actors/basalt_juggernaut.gd").read_text(encoding="utf-8")
level_02 = (ROOT / "scenes/levels/level_02.tscn").read_text(encoding="utf-8")
assert "class_name VexBasaltJuggernaut" in script
assert '[node name="BasaltJuggernaut" type="CharacterBody3D"' in scene
assert 'enemy_id = &"basalt_juggernaut"' in scene
assert 'path="res://scenes/actors/basalt_juggernaut_projectile.tscn"' in scene
assert '[node name="BasaltJuggernaut_19"' in level_02
assert 'enemy_id = &"v2_basalt_juggernaut_19"' in level_02

print("basalt juggernaut rename audit passed")
