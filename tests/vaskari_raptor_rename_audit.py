#!/usr/bin/env python3
from collections import Counter
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

required_files = [
    "scripts/actors/vaskari_raptor.gd", "scripts/actors/vaskari_raptor.gd.uid",
    "scenes/actors/vaskari_raptor.tscn",
    "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png",
    "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png.import",
    "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet_manifest.json",
    "scripts/actors/vaskari_ravager.gd", "scenes/actors/vaskari_ravager.tscn",
]
for relative in required_files:
    assert (ROOT / relative).is_file(), relative

script = (ROOT / "scripts/actors/vaskari_raptor.gd").read_text(encoding="utf-8")
scene = (ROOT / "scenes/actors/vaskari_raptor.tscn").read_text(encoding="utf-8")
import_text = (ROOT / "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png.import").read_text(encoding="utf-8")
manifest_text = (ROOT / "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet_manifest.json").read_text(encoding="utf-8")

assert "class_name VexVaskariRaptor" in script
assert 'uid="uid://bmbm2fkwpryrx" path="res://assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png"' in scene
assert 'enemy_id = &"vaskari_raptor"' in scene
assert "maximum_health = 140" in scene
assert "attack_damage = 22" in scene
assert "attack_lunge_speed = 10.4" in scene
assert "pixel_size = 0.0023438087" in scene
assert 'uid="uid://bmbm2fkwpryrx"' in import_text
assert "compress/mode=2" in import_text
assert "mipmaps/generate=true" in import_text
assert '"vram_texture": true' in import_text
assert '"width": 2048' in manifest_text and '"height": 4608' in manifest_text
assert manifest_text.count('"width": 512') >= 1 and manifest_text.count('"height": 768') >= 1

regions = Counter(tuple(map(int, m)) for m in re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", scene))
expected = Counter((c * 512, r * 768, 512, 768) for r in range(6) for c in range(4))
assert regions == expected, (regions, expected)

for name, loop, speed in [
    ("attack", 0, "8.0"), ("death", 0, "6.0"), ("idle", 1, "3.2"),
    ("idle_back", 1, "3.2"), ("walk", 1, "7.0"), ("walk_back", 1, "7.0"),
]:
    assert f'"loop": {loop},\n"name": &"{name}",\n"speed": {speed}' in scene, name

for level_path in ("scenes/levels/level_02.tscn", "scenes/levels/level_03.tscn", "scenes/levels/level_test.tscn"):
    level = (ROOT / level_path).read_text(encoding="utf-8")
    assert 'path="res://scenes/actors/vaskari_raptor.tscn"' in level, level_path

# Keep the historical rename contract intact.
retired_needles = ("redviper", "red_viper", "red-viper", "red viper")
tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
for relative in tracked:
    if not relative:
        continue
    assert not any(n in relative.lower() for n in retired_needles), relative
    data = (ROOT / relative).read_bytes()
    if b"\0" in data:
        continue
    try:
        text = data.decode("utf-8").lower()
    except UnicodeDecodeError:
        continue
    assert not any(n in text for n in retired_needles), relative

print("vaskari raptor/ravager rename audit passed")
