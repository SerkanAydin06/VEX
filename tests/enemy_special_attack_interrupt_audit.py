#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), relative
    return path.read_text(encoding="utf-8")


base = read("scripts/actors/enemy_combatant_base.gd")
cinder = read("scripts/actors/cinder_spitter.gd")
furnace = read("scripts/actors/furnice_carrier.gd")
warden = read("scripts/actors/crucible_warden.gd")
venom = read("scripts/actors/venom_marshall.gd")
gorehorn = read("scripts/actors/gorehorn.gd")

# Canonical combatant windup/cooldown awaits are generation guarded. Special
# combatants should preserve the same death/interrupt semantics.
for token in [
    "var combat_generation := _combat_interrupt_generation",
    "await get_tree().create_timer(_runtime_attack_windup).timeout",
    "combat_generation != _combat_interrupt_generation",
    "state == State.DEAD",
]:
    assert token in base, token

# Cinder Spitter schedules follow-up burst shots with Timer signals rather than
# awaiting inside the main attack coroutine. Every follow-up carries the combat
# generation captured by the first shot and revalidates player/range/LOS.
for token in [
    "var combat_generation := _combat_interrupt_generation",
    "timer.timeout.connect(_fire_burst_followup.bind(combat_generation))",
    "func _fire_burst_followup(combat_generation: int) -> void:",
    "state == State.DEAD",
    "combat_generation != _combat_interrupt_generation",
    "player_distance > attack_range + attack_range_tolerance",
    "if not _check_line_of_sight():",
]:
    assert token in cinder, token

# Furnace has one windup and one remaining-cooldown await. Both must reject an
# interrupted/dead actor before spawning damage or unlocking stale state.
assert "var combat_generation := _combat_interrupt_generation" in furnace
assert furnace.count("combat_generation != _combat_interrupt_generation") >= 2
assert furnace.count("state == State.DEAD") >= 2
assert furnace.count("not is_inside_tree()") >= 2

# Warden owns two separate attack coroutines (Ground Slam and Heatwave), each
# with windup and recovery awaits. Every await boundary is generation guarded.
for function_name in ["_begin_ground_slam_attack", "_begin_heatwave_attack"]:
    assert f"func {function_name}() -> void:" in warden, function_name
assert warden.count("var combat_generation := _combat_interrupt_generation") >= 2
assert warden.count("combat_generation != _combat_interrupt_generation") >= 4
assert warden.count("state == State.DEAD") >= 4

# Venom support deployment has the same windup/recovery contract; a dead
# Marshall cannot deploy a late field or unlock a newer attack coroutine.
for token in [
    "func _begin_buff_attack() -> void:",
    "var combat_generation := _combat_interrupt_generation",
    "await get_tree().create_timer(runtime_windup).timeout",
    "combat_generation != _combat_interrupt_generation",
    "state == State.DEAD",
]:
    assert token in venom, token
assert venom.count("combat_generation != _combat_interrupt_generation") >= 2

# Gorehorn has a longer custom charge lifecycle and therefore owns a dedicated
# generation counter. Player loss, death and a superseding charge all invalidate
# pending windup/physics/recovery/cooldown continuation.
for token in [
    "_attack_generation += 1",
    "var attack_generation := _attack_generation",
    "if not _is_current_charge_attack(attack_generation):",
    "while _is_current_charge_attack(attack_generation) and _charge_active:",
    "func _cancel_charge_attack() -> void:",
    "func _is_current_charge_attack(generation: int) -> bool:",
    "and not _dead",
    "and generation == _attack_generation",
    "func _die() -> void:",
    "_stop_charge_motion(false)",
]:
    assert token in gorehorn, token

print("enemy special attack interruption audit passed")
