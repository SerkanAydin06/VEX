#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def first_sphere_radius(relative: str) -> float:
    source = read(relative)
    match = re.search(
        r'\[sub_resource type="SphereShape3D"[^\]]*\]\s*radius = ([0-9.]+)',
        source,
    )
    assert match is not None, relative
    return float(match.group(1))


common_script = read("scripts/actors/ravager_projectile.gd")
assert "player_impact_surface_offset := 0.04" in common_script
assert 'target.is_in_group("player")' in common_script
assert "_impact_offset_for_target(damage_target)" in common_script

common_projectiles = {
    "scenes/actors/ravager_projectile.tscn": 0.20,
    "scenes/actors/voidweaver_projectile.tscn": 0.18,
    "scenes/actors/basalt_juggernaut_projectile.tscn": 0.24,
    "scenes/actors/veilmaw_projectile.tscn": 0.18,
    "scenes/actors/cinder_spitter_projectile.tscn": 0.18,
    "scenes/actors/coil_lancer_projectile.tscn": 0.18,
    "scenes/actors/venom_marshall_projectile.tscn": 0.18,
    "scenes/actors/husk_leech_projectile.tscn": 0.18,
}

for scene_path, expected_radius in common_projectiles.items():
    scene = read(scene_path)
    assert abs(first_sphere_radius(scene_path) - expected_radius) < 0.0001, scene_path
    assert "player_impact_surface_offset = 0.04" in scene, scene_path

assert abs(first_sphere_radius("scenes/actors/briar_skulker_projectile.tscn") - 0.20) < 0.0001

warden_scene = read("scenes/actors/crucible_warden_heatwave_projectile.tscn")
assert abs(first_sphere_radius("scenes/actors/crucible_warden_heatwave_projectile.tscn") - 0.20) < 0.0001
assert "collision_radius = 0.20" in warden_scene
assert "collision_radius := 0.20" in read("scripts/actors/crucible_warden_heatwave_projectile.gd")

furnice_scene = read("scenes/actors/furnice_carrier_projectile.tscn")
assert abs(first_sphere_radius("scenes/actors/furnice_carrier_projectile.tscn") - 0.18) < 0.0001
assert "collision_radius = 0.18" in furnice_scene
assert "collision_radius := 0.18" in read("scripts/actors/furnice_carrier_projectile.gd")

print("enemy projectile contact fairness audit passed")
