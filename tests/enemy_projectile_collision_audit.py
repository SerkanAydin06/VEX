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

# Custom projectile implementations keep the same source-exclusion contract.
for script_name in [
    "briar_skulker_projectile.gd",
    "furnice_carrier_projectile.gd",
]:
    source = read(f"scripts/actors/{script_name}")
    assert "get_rid()" in source, script_name
    assert "source" in source or "_source" in source, script_name

# Spore projectile controls its masks in code because it changes from flight to
# field phase. Flight sees world+player; the deployed field monitors player only.
spore = read("scripts/actors/spore_matriarch_projectile.gd")
assert "flight_collision_mask := 1 | 2" in spore
assert "field_collision_mask := 2" in spore
assert "collision_mask = field_collision_mask" in spore
assert "exclusions.append((damage_source as CollisionObject3D).get_rid())" in spore
assert "func _valid_source() -> Node:" in spore

print("enemy projectile collision audit passed")
