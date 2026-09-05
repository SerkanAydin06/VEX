#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
PLAYER_LAYER_BIT = 1 << 1
ENEMY_LAYER_BIT = 1 << 2

DIRECT_PROJECTILE_SCENES = [
    "ravager_projectile.tscn",
    "basalt_juggernaut_projectile.tscn",
    "cinder_spitter_projectile.tscn",
    "coil_lancer_projectile.tscn",
    "veilmaw_projectile.tscn",
    "voidweaver_projectile.tscn",
    "husk_leech_projectile.tscn",
    "venom_marshall_projectile.tscn",
    "briar_skulker_projectile.tscn",
    "furnice_carrier_projectile.tscn",
    "crucible_warden_heatwave_projectile.tscn",
]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


def root_collision_mask(scene_source: str, scene_name: str) -> int:
    root = re.search(
        r'^\[node name="[^"]+" type="Area3D"[^\n]*\]\n(.*?)(?=^\[node |\Z)',
        scene_source,
        re.M | re.S,
    )
    assert root is not None, (scene_name, "Area3D root missing")
    match = re.search(r"^collision_mask\s*=\s*(\d+)\s*$", root.group(1), re.M)
    assert match is not None, (scene_name, "explicit collision_mask missing")
    return int(match.group(1))


# Layer names are a project contract: bit 2 is player, bit 3 is enemy.
project = read("project.godot")
assert '3d_physics/layer_2="player"' in project
assert '3d_physics/layer_3="enemy"' in project

# Hostile direct projectiles must be able to hit the player but never collide
# with the enemy layer. World/interaction bits may vary by projectile family.
for scene_name in DIRECT_PROJECTILE_SCENES:
    source = read(f"scenes/actors/{scene_name}")
    mask = root_collision_mask(source, scene_name)
    assert mask & PLAYER_LAYER_BIT, (scene_name, "cannot collide with player", mask)
    assert not mask & ENEMY_LAYER_BIT, (scene_name, "enemy friendly-fire mask enabled", mask)

# Shared anti-tunneling projectile excludes a live source from both ray and body
# paths. If the shooter dies while the projectile is in flight, the stale Node
# reference is cleared and null is forwarded to the eventual damage call.
ravager_projectile = read("scripts/actors/ravager_projectile.gd")
for contract in [
    "source = new_source if is_instance_valid(new_source) else null",
    "var damage_source := _valid_source()",
    "exclusions.append((damage_source as CollisionObject3D).get_rid())",
    "if body == damage_source:",
    'damage_target.call("take_damage", damage, global_position, damage_source)',
    "func _valid_source() -> Node:",
    "if is_instance_valid(source):",
    "source = null",
]:
    assert contract in ravager_projectile, contract
for retired_contract in [
    "exclusions.append((source as CollisionObject3D).get_rid())",
    "if not _active or body == source:",
    'damage_target.call("take_damage", damage, global_position, source)',
]:
    assert retired_contract not in ravager_projectile, retired_contract

# Custom direct projectiles follow the same lifetime rule instead of forwarding
# raw shooter references after the shooter has already left the tree.
briar = read("scripts/actors/briar_skulker_projectile.gd")
for contract in [
    "source = new_source if is_instance_valid(new_source) else null",
    "var damage_source := _valid_source()",
    "func _valid_source() -> Node:",
    'damage_target.call("take_damage", damage, global_position, _valid_source())',
]:
    assert contract in briar, contract
assert 'damage_target.call("take_damage", damage, global_position, source)' not in briar

furnace = read("scripts/actors/furnice_carrier_projectile.gd")
for contract in [
    "_source = source if is_instance_valid(source) else null",
    "var damage_source := _valid_source()",
    "func _valid_source() -> Node:",
    'damage_target.call("take_damage", _direct_damage, hit_position, _valid_source())',
    'decal.call("configure", _decal_tick_damage, damage_source)',
]:
    assert contract in furnace, contract
for retired_contract in [
    'damage_target.call("take_damage", _direct_damage, hit_position, _source)',
    'decal.call("configure", _decal_tick_damage, _source)',
]:
    assert retired_contract not in furnace, retired_contract

furnace_decal = read("scripts/effects/furnice_carrier_decal.gd")
for contract in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    'player.call("take_damage", damage_per_tick, player.global_position, _valid_source())',
]:
    assert contract in furnace_decal, contract
assert 'player.call("take_damage", damage_per_tick, player.global_position, _source)' not in furnace_decal

warden_heatwave = read("scripts/actors/crucible_warden_heatwave_projectile.gd")
for contract in [
    "_source = source if is_instance_valid(source) else null",
    "var damage_source := _valid_source()",
    "func _valid_source() -> Node:",
    'damage_target.call("take_damage", _damage, global_position, damage_source)',
]:
    assert contract in warden_heatwave, contract
assert 'damage_target.call("take_damage", _damage, global_position, _source)' not in warden_heatwave

# Spore projectile controls its masks in code because it changes from flight to
# field phase. Flight sees world+player; the deployed field monitors player only.
spore = read("scripts/actors/spore_matriarch_projectile.gd")
assert "flight_collision_mask := 1 | 2" in spore
assert "field_collision_mask := 2" in spore
assert "collision_mask = field_collision_mask" in spore
assert "exclusions.append((damage_source as CollisionObject3D).get_rid())" in spore
assert "func _valid_source() -> Node:" in spore

print("enemy projectile collision audit passed")
