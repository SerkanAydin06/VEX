#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
ACTORS = ROOT / "scripts" / "actors"
SCENES = ROOT / "scenes" / "actors"


def read(path: Path) -> str:
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


def resource_block(scene: str, resource_id: str) -> str:
    match = re.search(
        rf'^\[sub_resource type="Resource" id="{re.escape(resource_id)}"\]\n(.*?)(?=^\[|\Z)',
        scene,
        re.M | re.S,
    )
    assert match is not None, resource_id
    return match.group(1)


helper = read(ACTORS / "enemy_projectile_fire_runtime.gd")
ravager = read(ACTORS / "ravager.gd")
cinder = read(ACTORS / "cinder_spitter.gd")
veilmaw = read(ACTORS / "veilmaw.gd")
voidweaver = read(ACTORS / "voidweaver.gd")

ravager_scene = read(SCENES / "ravager.tscn")
cinder_scene = read(SCENES / "cinder_spitter.tscn")
veilmaw_scene = read(SCENES / "veilmaw.tscn")
voidweaver_scene = read(SCENES / "voidweaver.tscn")

# Özel projectile imzaları ortak launch/lead hesabını tek helper'da paylaşır.
for token in [
    'const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")',
    "EnemyCombatRuntime.calculate_intercept_time",
    'projectile.set("speed", projectile_speed)',
    'projectile.call("launch", shot_direction, source, maxi(1, damage))',
]:
    assert token in helper, token

# Creature scriptleri yalnız davranışı uygular; tuning doğrudan burada export edilmez.
for script_name, source, type_name in [
    ("ravager.gd", ravager, "VexRavagerAbilitySettings"),
    ("cinder_spitter.gd", cinder, "VexCinderSpitterAbilitySettings"),
    ("veilmaw.gd", veilmaw, "VexVeilmawAbilitySettings"),
    ("voidweaver.gd", voidweaver, "VexVoidweaverAbilitySettings"),
]:
    assert "@export" not in source, script_name
    assert f"var _ability: {type_name}" in source, (script_name, type_name)

# Ravager: tek, uzun menzilli ve normal projectile'dan daha hızlı precision shot.
ravager_ability = resource_block(ravager_scene, "Resource_ravager_ability")
assert "precision_projectile_speed_scale = 1.18" in ravager_ability
assert "_ability.precision_projectile_speed_scale" in ravager
assert "ProjectileFireRuntime.fire(" in ravager
assert re.search(r"^attack_range = 20\.0$", ravager_scene, re.M)
assert re.search(r"^projectile_lead_factor = 0\.95$", ravager_scene, re.M)
assert 'special_ability_settings = SubResource("Resource_ravager_ability")' in ravager_scene

# Cinder Spitter: tek attack komutunda iki düşük hasarlı projectile'lık kısa seri.
cinder_ability = resource_block(cinder_scene, "Resource_cinder_spitter_ability")
assert "burst_shot_count = 2" in cinder_ability
assert "burst_interval = 0.12" in cinder_ability
assert "burst_damage_scale = 0.6" in cinder_ability
for token in [
    "_ability.burst_shot_count",
    "_ability.burst_interval",
    "_ability.burst_damage_scale",
    "timer.timeout.connect(_fire_burst_followup.bind(combat_generation))",
]:
    assert token in cinder, token
assert re.search(r"^attack_range = 14\.0$", cinder_scene, re.M)
assert 'special_ability_settings = SubResource("Resource_cinder_spitter_ability")' in cinder_scene

# Veilmaw: her atıştan sonra yeni görüş açısı arayan harrier.
veilmaw_ability = resource_block(veilmaw_scene, "Resource_veilmaw_ability")
assert "post_shot_reposition_duration = 0.65" in veilmaw_ability
assert "_ability.post_shot_reposition_duration" in veilmaw
assert "_has_ranged_reposition_target = false" in veilmaw
assert "_reposition_for_clear_shot(delta)" in veilmaw
assert re.search(r"^attack_range = 12\.0$", veilmaw_scene, re.M)
assert 'special_ability_settings = SubResource("Resource_veilmaw_ability")' in veilmaw_scene

# Voidweaver: merkez tam hasar + düşük hasarlı, daha geniş yan kollardan oluşan enerji fanı.
void_ability = resource_block(voidweaver_scene, "Resource_voidweaver_ability")
assert "weave_projectile_count = 3" in void_ability
assert "weave_half_angle_degrees = 7.0" in void_ability
assert "weave_side_damage_scale = 0.45" in void_ability
for token in [
    "_ability.weave_projectile_count",
    "_ability.weave_half_angle_degrees",
    "_ability.weave_side_damage_scale",
    "lerpf(",
]:
    assert token in voidweaver, token
assert re.search(r"^attack_range = 13\.5$", voidweaver_scene, re.M)
assert "accepts_weapon_hit" in voidweaver
assert 'special_ability_settings = SubResource("Resource_voidweaver_ability")' in voidweaver_scene

print("ranged enemy identity audit passed")
