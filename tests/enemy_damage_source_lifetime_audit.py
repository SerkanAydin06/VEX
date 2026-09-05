#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


# Shared direct projectile family. A shooter may die while its projectile is in
# flight; every later collision/damage path must resolve a live source or null.
shared = read("scripts/actors/ravager_projectile.gd")
for token in [
    "source = new_source if is_instance_valid(new_source) else null",
    "func _valid_source() -> Node:",
    "var damage_source := _valid_source()",
    'damage_target.call("take_damage", damage, global_position, damage_source)',
]:
    assert token in shared, token
assert 'take_damage", damage, global_position, source' not in shared

# Briar owns its projectile implementation instead of inheriting the shared one.
briar = read("scripts/actors/briar_skulker_projectile.gd")
for token in [
    "source = new_source if is_instance_valid(new_source) else null",
    "func _valid_source() -> Node:",
    'damage_target.call("take_damage", damage, global_position, _valid_source())',
]:
    assert token in briar, token
assert 'take_damage", damage, global_position, source' not in briar

# Furnace carries the shooter through projectile -> decal and projectile ->
# delayed Thermal Burst. Each stage validates independently because the source
# can disappear after the previous stage has already been created.
furnace_projectile = read("scripts/actors/furnice_carrier_projectile.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    'damage_target.call("take_damage", _direct_damage, hit_position, _valid_source())',
    'decal.call("configure", _decal_tick_damage, damage_source)',
]:
    assert token in furnace_projectile, token
assert 'take_damage", _direct_damage, hit_position, _source' not in furnace_projectile
assert 'decal.call("configure", _decal_tick_damage, _source)' not in furnace_projectile

furnace_decal = read("scripts/effects/furnice_carrier_decal.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    'player.call("take_damage", damage_per_tick, player.global_position, _valid_source())',
]:
    assert token in furnace_decal, token
assert 'take_damage", damage_per_tick, player.global_position, _source' not in furnace_decal

furnace_shockwave = read("scripts/effects/furnice_carrier_shockwave.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    "var damage_source := _valid_source()",
    'player.call("take_damage", burst_damage, player.global_position, _valid_source())',
]:
    assert token in furnace_shockwave, token
assert 'take_damage", burst_damage, player.global_position, _source' not in furnace_shockwave

# Warden has two delayed damage objects: the radial Heatwave projectile and the
# Ground Slam scene resolved on a deferred call.
warden_heatwave = read("scripts/actors/crucible_warden_heatwave_projectile.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    "var damage_source := _valid_source()",
    'damage_target.call("take_damage", _damage, global_position, damage_source)',
]:
    assert token in warden_heatwave, token
assert 'take_damage", _damage, global_position, _source' not in warden_heatwave

warden_slam = read("scripts/effects/crucible_warden_ground_slam.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "func _valid_source() -> Node:",
    "var damage_source := _valid_source()",
    'player.call("take_damage", damage, player.global_position, _valid_source())',
]:
    assert token in warden_slam, token
assert 'take_damage", damage, player.global_position, _source' not in warden_slam

# Spore already uses the same lifetime contract for flight, field impact and its
# poison status. Poison itself also validates the source before each later tick.
spore_projectile = read("scripts/actors/spore_matriarch_projectile.gd")
for token in [
    "source = new_source if is_instance_valid(new_source) else null",
    "func _valid_source() -> Node:",
    "var damage_source := _valid_source()",
    'status.call(',
    "_valid_source()",
]:
    assert token in spore_projectile, token

spore_status = read("scripts/actors/spore_poison_status.gd")
for token in [
    "_source = source if is_instance_valid(source) else null",
    "if is_instance_valid(_source):",
    "damage_source = _source",
    '_target.call("take_damage", _tick_damage, hit_position, damage_source)',
]:
    assert token in spore_status, token

# Venom's support field is non-hostile but still keeps a source reference for
# self-exclusion. It must also clear stale sources while the field persists.
venom_field = read("scripts/actors/venom_marshall_buff_projectile.gd")
for token in [
    "source = new_source if is_instance_valid(new_source) else null",
    "func _valid_source() -> Node:",
    "if target == null or target == _valid_source():",
]:
    assert token in venom_field, token

print("enemy damage source lifetime audit passed")
