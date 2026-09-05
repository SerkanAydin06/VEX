#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


combatant = read("scripts/actors/enemy_combatant_base.gd")
projectile_fire = read("scripts/actors/enemy_projectile_fire_runtime.gd")
ravager = read("scripts/actors/ravager.gd")
cinder = read("scripts/actors/cinder_spitter.gd")
voidweaver = read("scripts/actors/voidweaver.gd")
furnace = read("scripts/actors/furnice_carrier.gd")
hybrid = read("scripts/actors/enemy_hybrid_base.gd")
veilmaw = read("scripts/actors/veilmaw.gd")
spore_actor = read("scripts/actors/spore_matriarch.gd")
ravager_projectile = read("scripts/actors/ravager_projectile.gd")
briar_projectile = read("scripts/actors/briar_skulker_projectile.gd")
spore_projectile = read("scripts/actors/spore_matriarch_projectile.gd")
furnace_projectile = read("scripts/actors/furnice_carrier_projectile.gd")

# Generic combatant attacks must pass the already difficulty-scaled damage into
# projectiles. Most ranged enemies inherit this path unchanged.
assert 'projectile.call("launch", shot_direction, self, _runtime_attack_damage)' in combatant

# Shared projectile helper must preserve its caller-provided damage rather than
# reaching back to an authored/raw actor attack_damage property.
assert 'projectile.call("launch", shot_direction, source, maxi(1, damage))' in projectile_fire
assert "attack_damage" not in projectile_fire

# Ravager precision shot, Cinder burst and Voidweaver fan all derive from the
# runtime-scaled normal attack damage.
assert "ProjectileFireRuntime.fire(" in ravager
assert "_runtime_attack_damage" in ravager
assert "float(_runtime_attack_damage) * _ability.burst_damage_scale" in cinder
assert "float(_runtime_attack_damage) * damage_scale" in voidweaver

# Furnace Carrier has two secondary damage channels. Direct projectile damage
# uses runtime attack damage, while the lingering decal tick has its own base
# value but must receive the same difficulty damage multiplier.
assert "_scaled_special_damage(_ability.projectile_decal_tick_damage)" in furnace
assert 'projectile.call("launch", shot_direction, self, _runtime_attack_damage, decal_damage)' in furnace
assert "_direct_damage = maxi(1, direct_damage)" in furnace_projectile
assert "_decal_tick_damage = maxi(1, decal_tick_damage)" in furnace_projectile
assert 'decal.call("configure", _decal_tick_damage, _source)' in furnace_projectile

# Hybrid ranged attacks use the generic combatant projectile path; Veilmaw adds
# reposition behavior but must still delegate projectile creation to its parent.
assert "_fire_projectile()" in hybrid
assert "super._fire_projectile()" in veilmaw

# Spore Matriarch deliberately uses the generic combatant launch path. Once the
# scaled damage reaches its projectile, impact, field ticks and poison derive
# from that same value instead of a second raw actor stat.
assert "func _fire_projectile" not in spore_actor
assert "damage = maxi(1, new_damage)" in spore_projectile
assert "float(damage) * impact_damage_ratio" in spore_projectile
assert 'target.call("take_damage", damage, global_position, damage_source)' in spore_projectile
assert "float(damage) * poison_damage_ratio" in spore_projectile

# Shared/simple projectile implementations may own harmless fallback defaults,
# but launch() must overwrite them from the scaled caller value before impact.
for script_name, source in [
    ("ravager_projectile.gd", ravager_projectile),
    ("briar_skulker_projectile.gd", briar_projectile),
]:
    assert "func launch(" in source, script_name
    assert "new_damage: int" in source, script_name
    assert "damage = new_damage" in source or "damage = maxi(1, new_damage)" in source, script_name
    assert 'take_damage", damage' in source, script_name

print("enemy projectile damage scaling audit passed")
