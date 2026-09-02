#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
runtime = (ROOT / "scripts/actors/enemy_combat_runtime.gd").read_text(encoding="utf-8")
base = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
enemy_base = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")

for token in [
    "class_name VexEnemyCombatRuntime",
    "extends RefCounted",
    "static func resolve_attack_target(",
    "static func should_start_attack(",
    "static func should_fire_after_windup(",
    "static func remaining_attack_cooldown(",
    "static func attack_recovery_plan(",
    "static func calculate_intercept_time(",
    "static func damage_source_approach_position(",
    "static func damage_pursuit_progress(",
    "static func should_abandon_damage_pursuit(",
    "static func can_attempt_damage_handoff(",
    "static func should_check_close_combat_visibility(",
]:
    assert token in runtime, token

for forbidden in [
    "GameState",
    "Input.",
    "get_tree(",
    ".instantiate(",
    "animated_sprite",
    "attack_audio",
    "projectile_scene",
    "move_and_slide",
    "velocity.x =",
    "rotation.y =",
]:
    assert forbidden not in runtime, forbidden

assert 'const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")' in enemy_base

for token in [
    "EnemyCombatRuntime.resolve_attack_target(",
    "EnemyCombatRuntime.should_start_attack(",
    "EnemyCombatRuntime.should_fire_after_windup(",
    "EnemyCombatRuntime.remaining_attack_cooldown(",
    "EnemyCombatRuntime.attack_recovery_plan(",
    "EnemyCombatRuntime.calculate_intercept_time(",
    "EnemyCombatRuntime.damage_source_approach_position(",
    "EnemyCombatRuntime.damage_pursuit_progress(",
    "EnemyCombatRuntime.should_abandon_damage_pursuit(",
    "EnemyCombatRuntime.can_attempt_damage_handoff(",
    "EnemyCombatRuntime.should_check_close_combat_visibility(",
]:
    assert token in base, token

# Combatant remains the side-effect owner and public/override-compatible orchestrator.
for token in [
    "func _attempt_attack() -> void:",
    "func _fire_projectile() -> void:",
    "func _move_during_attack_recovery(target: Vector3, delta: float) -> void:",
    "func _calculate_intercept_time(",
    "func _damage_source_approach_position(source_position: Vector3) -> Vector3:",
    "func _can_handoff_damage_pursuit_to_combat() -> bool:",
    "func _refresh_close_combat_visibility() -> void:",
    "await get_tree().create_timer(",
    "animated_sprite.play(&\"attack\")",
    "attack_audio.play()",
    "projectile_scene.instantiate()",
    "get_tree().current_scene.add_child(projectile)",
    'projectile.call("launch", shot_direction, self, _runtime_attack_damage)',
    "velocity.x = move_toward(",
    "rotation.y = atan2(",
    "_check_line_of_sight()",
]:
    assert token in base, token

# Pure quadratic interception and recovery vector math must not drift back into the base.
for forbidden in [
    "var quadratic_a := target_velocity.length_squared() - projectile_speed * projectile_speed",
    "var quadratic_b := 2.0 * displacement.dot(target_velocity)",
    "var right_direction := forward_direction.cross(Vector3.UP).normalized()",
    "var minimum_distance := minf(attack_minimum_distance, preferred_distance)",
]:
    assert forbidden not in base, forbidden

print("enemy combat architecture audit passed")
