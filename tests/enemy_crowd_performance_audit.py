#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    path = ROOT / relative
    assert path.exists(), path
    return path.read_text(encoding="utf-8")


project = read("project.godot")
manager = read("scripts/autoload/enemy_performance_manager.gd")
runtime = read("scripts/actors/enemy_performance_runtime.gd")
combatant_perf = read("scripts/actors/enemy_combatant_performance_base.gd")
lunge_perf = read("scripts/actors/enemy_lunge_performance_base.gd")
pool = read("scripts/actors/enemy_projectile_pool.gd")
projectile = read("scripts/actors/ravager_projectile.gd")
hybrid = read("scripts/actors/enemy_hybrid_base.gd")

assert 'EnemyPerformance="*res://scripts/autoload/enemy_performance_manager.gd"' in project

# Global crowd LOD is runtime-only and must not lower authored visual resolution.
for token in [
    "const UPDATE_INTERVAL := 0.10",
    "const NEAR_DISTANCE := 14.0",
    "const MID_DISTANCE := 28.0",
    "const CROWD_START := 16.0",
    "const CROWD_FULL := 48.0",
    'enemy.set_physics_process(false)',
    'sprite.speed_scale = 0.0',
    'enemy.set_physics_process(true)',
    'family == &"charge"',
]:
    assert token in manager, token
for forbidden in [
    "pixel_size =",
    '.set("pixel_size"',
    '.set("texture"',
    ".texture =",
    ".scale =",
]:
    assert forbidden not in manager, ("visual quality mutation", forbidden)

# Expensive LOS/path/cover work is distributed across physics frames.
for token in [
    "Engine.get_physics_frames()",
    "try_claim_sight",
    "try_claim_path",
    "try_claim_cover",
    "NEAR_SIGHT_CLAIMS_PER_FRAME",
    "FAR_PATH_CLAIMS_PER_FRAME",
    "DOOR_CACHE_REFRESH_FRAMES",
    'get_nodes_in_group("enemy_navigation_door")',
    "_door_refresh_frame",
    "_door_nodes",
]:
    assert token in runtime, token

assert 'extends "res://scripts/actors/enemy_combatant_base.gd"' in combatant_perf
assert 'extends "res://scripts/actors/enemy_lunge_base.gd"' in lunge_perf
assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in hybrid
for source in (combatant_perf, lunge_perf):
    assert "func _check_line_of_sight()" in source
    assert "EnemyPerformanceRuntime.try_claim_sight" in source
    assert "EnemyPerformanceRuntime.try_claim_path" in source
assert "EnemyPerformanceRuntime.try_claim_cover" in combatant_perf
assert "resolve_enemy_door_step_cached" in combatant_perf
assert "resolve_enemy_door_step_cached" in lunge_perf
assert "EnemyProjectilePool.acquire" in combatant_perf

# Standard combatants/lungers use the performance wrapper without moving tuning
# out of their scenes. Special large state machines remain on core bases and are
# still handled by the global manager.
for enemy in [
    "ravager", "basalt_juggernaut", "veilmaw", "voidweaver",
    "cinder_spitter", "coil_lancer",
]:
    source = read(f"scripts/actors/{enemy}.gd")
    assert 'extends "res://scripts/actors/enemy_combatant_performance_base.gd"' in source, enemy
for enemy in ["vaskari_raptor", "badredviper", "cinderhound", "vaskari_bulwark"]:
    source = read(f"scripts/actors/{enemy}.gd")
    assert 'extends "res://scripts/actors/enemy_lunge_performance_base.gd"' in source, enemy

# Projectile/effect nodes are recycled with lifecycle guards so old timers cannot
# retire a reused projectile.
for token in [
    "MAX_POOLED_PER_SCENE",
    "static func acquire",
    "static func recycle",
    'vex_projectile_pool_key',
]:
    assert token in pool, token
for token in [
    "func activate_from_pool()",
    "func deactivate_for_pool()",
    "_lifecycle_generation",
    "EnemyProjectilePool.recycle(self)",
    "generation == _lifecycle_generation",
    "set_physics_process(false)",
]:
    assert token in projectile, token

print("enemy crowd performance audit passed")
