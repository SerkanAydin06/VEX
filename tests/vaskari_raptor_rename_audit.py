#!/usr/bin/env python3
from collections import Counter
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]

required_files = [
    "scripts/actors/vaskari_raptor.gd",
    "scripts/actors/vaskari_raptor.gd.uid",
    "scenes/actors/vaskari_raptor.tscn",
    "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png",
    "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png.import",
    "scripts/actors/vaskari_ravager.gd",
    "scripts/actors/vaskari_ravager.gd.uid",
    "scenes/actors/vaskari_ravager.tscn",
    "assets/enemies/vaskari_ravager/vaskari_ravager_spritesheet.png",
    "assets/enemies/vaskari_ravager/vaskari_ravager_spritesheet.png.import",
    "assets/audio/vaskari_predator_attack.wav",
    "assets/audio/vaskari_predator_attack.wav.import",
    "assets/audio/vaskari_predator_hurt.wav",
    "assets/audio/vaskari_predator_hurt.wav.import",
    "assets/audio/vaskari_predator_death.wav",
    "assets/audio/vaskari_predator_death.wav.import",
]
for relative in required_files:
    assert (ROOT / relative).is_file(), relative

raptor_script = (ROOT / "scripts/actors/vaskari_raptor.gd").read_text(encoding="utf-8")
raptor_uid = (ROOT / "scripts/actors/vaskari_raptor.gd.uid").read_text(encoding="utf-8").strip()
raptor_scene = (ROOT / "scenes/actors/vaskari_raptor.tscn").read_text(encoding="utf-8")
raptor_import = (ROOT / "assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png.import").read_text(encoding="utf-8")
ravager_script = (ROOT / "scripts/actors/vaskari_ravager.gd").read_text(encoding="utf-8")
ravager_uid = (ROOT / "scripts/actors/vaskari_ravager.gd.uid").read_text(encoding="utf-8").strip()
ravager_scene = (ROOT / "scenes/actors/vaskari_ravager.tscn").read_text(encoding="utf-8")

assert "class_name VexVaskariRaptor" in raptor_script
assert raptor_uid == "uid://b7pixtku56b8v"
assert raptor_scene.startswith('[gd_scene format=3 uid="uid://d0if1xpxh6no2"]')
assert 'uid="uid://b7pixtku56b8v" path="res://scripts/actors/vaskari_raptor.gd"' in raptor_scene
assert 'uid="uid://bmbm2fkwpryrx" path="res://assets/enemies/vaskari_raptor/vaskari_raptor_character_spritesheet.png"' in raptor_scene
assert '[node name="VaskariRaptor" type="CharacterBody3D"' in raptor_scene
assert 'enemy_id = &"vaskari_raptor"' in raptor_scene
assert 'uid="uid://bmbm2fkwpryrx"' in raptor_import

assert "class_name VexVaskariRavager" in ravager_script
assert ravager_uid == "uid://j3botxbwdehj"
assert ravager_scene.startswith('[gd_scene format=3 uid="uid://dnj5rfyxbcvek"]')
assert 'path="res://scripts/actors/vaskari_ravager.gd"' in ravager_scene
assert 'path="res://assets/enemies/vaskari_ravager/vaskari_ravager_spritesheet.png"' in ravager_scene
assert '[node name="VaskariRavager" type="CharacterBody3D"' in ravager_scene
assert 'enemy_id = &"vaskari_ravager"' in ravager_scene

for scene in (raptor_scene, ravager_scene):
    for sound in ("attack", "hurt", "death"):
        assert f'path="res://assets/audio/vaskari_predator_{sound}.wav"' in scene

regions = Counter(
    tuple(map(int, match))
    for match in re.findall(r"region = Rect2\((\d+), (\d+), (\d+), (\d+)\)", raptor_scene)
)
expected_regions = Counter(
    (x, y, 341, 512)
    for y in (0, 512, 1024, 1536, 2048, 2560)
    for x in (0, 341, 682, 1023)
)
assert regions == expected_regions, (regions, expected_regions)
assert "Rect2(1364," not in raptor_scene
assert "Rect2(1705," not in raptor_scene

animation_specs = {
    "attack": (0, "8.0"),
    "death": (0, "6.0"),
    "idle": (1, "3.2"),
    "idle_back": (1, "3.2"),
    "walk": (1, "7.0"),
    "walk_back": (1, "7.0"),
}
for name, (loop, speed) in animation_specs.items():
    marker = f'"loop": {loop},\n"name": &"{name}",\n"speed": {speed}'
    assert marker in raptor_scene, name

# Raptor gameplay tuning intentionally remains identical during the visual/name migration.
for marker in (
    "maximum_health = 140",
    "move_speed = 3.2",
    "chase_speed = 6.4",
    "attack_range = 2.05",
    "attack_damage = 22",
    "attack_cooldown = 0.9",
    "attack_windup = 0.24",
    "attack_lunge_speed = 10.4",
    "attack_lunge_acceleration = 46.0",
    "attack_lunge_duration = 0.24",
    "attack_lunge_stop_distance = 1.0",
):
    assert marker in raptor_scene, marker

# Ravager gameplay tuning also remains unchanged; only its canonical identity/path changes.
for marker in (
    "maximum_health = 190",
    "move_speed = 3.0",
    "chase_speed = 6.8",
    "attack_range = 2.25",
    "attack_damage = 28",
    "attack_cooldown = 0.95",
    "attack_windup = 0.25",
    "attack_lunge_speed = 11.4",
    "attack_lunge_acceleration = 52.0",
    "attack_lunge_duration = 0.25",
    "attack_lunge_stop_distance = 1.05",
):
    assert marker in ravager_scene, marker

for level_path in (
    "scenes/levels/level_02.tscn",
    "scenes/levels/level_03.tscn",
    "scenes/levels/level_test.tscn",
):
    level = (ROOT / level_path).read_text(encoding="utf-8")
    assert 'path="res://scenes/actors/vaskari_raptor.tscn"' in level, level_path

level_02 = (ROOT / "scenes/levels/level_02.tscn").read_text(encoding="utf-8")
assert 'enemy_id = &"v2_vaskari_ravager_final_guard"' in level_02
assert 'required_enemy_id = &"v2_vaskari_ravager_final_guard"' in level_02

enemies_doc = (ROOT / "Enemies_VEX.md").read_text(encoding="utf-8")
assert "Vaskari Raptor" in enemies_doc
assert "Vaskari Ravager" in enemies_doc
assert "- **Görsel dil:** Koyu mor, siyah, kemiksi biyozırh, yılanımsı hatlar, keskin yüzeyler." in enemies_doc

# The retired identity must never re-enter a tracked path or tracked text file.
red = "red"
viper = "viper"
legacy_needles = (
    red + viper,
    red + "_" + viper,
    red + "-" + viper,
    red + " " + viper,
)
tracked = subprocess.check_output(["git", "ls-files", "-z"], cwd=ROOT).decode().split("\0")
for relative in tracked:
    if not relative:
        continue
    lowered_path = relative.lower()
    assert not any(needle in lowered_path for needle in legacy_needles), relative
    data = (ROOT / relative).read_bytes()
    if b"\0" in data:
        continue
    try:
        text = data.decode("utf-8").lower()
    except UnicodeDecodeError:
        continue
    assert not any(needle in text for needle in legacy_needles), relative

print("vaskari raptor/ravager rename audit passed")
