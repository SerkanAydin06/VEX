#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")
RUNTIME = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")

errors: list[str] = []


def require(source: str, token: str, label: str) -> None:
    if token not in source:
        errors.append(f"{label}: {token}")


def function_body(source: str, name: str) -> str:
    marker = f"func {name}"
    start = source.find(marker)
    if start < 0:
        errors.append(f"Eksik fonksiyon: {name}")
        return ""
    next_func = source.find("\n\nfunc ", start + len(marker))
    return source[start:] if next_func < 0 else source[start:next_func]


for token in [
    "static func has_navigation_floor(",
    "static func has_clearance_segment(",
    "static func has_reached_clearance_target(",
    "static func is_center_segment_clear(",
    "static func build_astar_graph(",
    "static func nearest_waypoint_indices(",
    "static func connect_endpoint_to_graph(",
    "static func furthest_clearance_point_toward(",
    "static func find_investigation_path(",
    "static func build_local_detour_path(",
    "static func should_refresh_path(",
    "static func active_movement_direction(",
    "static func movement_speed(",
    "static func detour_direction_from_collision_normal(",
]:
    require(RUNTIME, token, "Navigation runtime contract eksik")

for token in [
    "EnemyNavigationRuntime.has_navigation_floor(",
    "EnemyNavigationRuntime.has_clearance_segment(",
    "EnemyNavigationRuntime.has_reached_clearance_target(",
    "EnemyNavigationRuntime.is_center_segment_clear(",
    "EnemyNavigationRuntime.build_astar_graph(",
    "EnemyNavigationRuntime.nearest_waypoint_indices(",
    "EnemyNavigationRuntime.connect_endpoint_to_graph(",
    "EnemyNavigationRuntime.furthest_clearance_point_toward(",
    "EnemyNavigationRuntime.find_investigation_path(",
    "EnemyNavigationRuntime.build_local_detour_path(",
]:
    require(BASE, token, "Combatant navigation delegation eksik")

for token in [
    "EnemyNavigationRuntime.should_refresh_path(",
    "EnemyNavigationRuntime.active_movement_direction(",
    "EnemyNavigationRuntime.movement_speed(",
    "EnemyNavigationRuntime.detour_direction_from_collision_normal(",
]:
    require(LUNGE, token, "Lunge navigation delegation eksik")

for forbidden in [
    "var target_changed := (",
    "var tangent_a := Vector3(-normal.z, 0.0, normal.x)",
    "_runtime_chase_speed if use_chase_speed else _runtime_move_speed",
]:
    if forbidden in LUNGE:
        errors.append(f"Navigation hesabı hâlâ lunge base içinde: {forbidden}")

# Public/protected compatibility wrappers must remain available to subclasses.
for name in [
    "_build_local_detour_path(",
    "_has_navigation_floor(",
    "_has_reached_walkable_target(",
    "_build_astar_graph(",
    "_find_investigation_path(",
    "_furthest_walkable_point_toward(",
    "_connect_endpoint_to_graph(",
    "_nearest_waypoint_indices(",
    "_is_walk_segment_clear(",
    "_is_center_segment_clear(",
]:
    require(BASE, f"func {name}", "Combatant compatibility wrapper eksik")

# Heavy geometry/path calculations may no longer live in the orchestrator wrappers.
for name, forbidden in [
    ("_build_local_detour_path(", "for side_sign"),
    ("_has_navigation_floor(", "PhysicsRayQueryParameters3D.create("),
    ("_has_reached_walkable_target(", "PhysicsRayQueryParameters3D.create("),
    ("_build_astar_graph(", "graph.connect_points("),
    ("_find_investigation_path(", "reachable_candidates"),
    ("_furthest_walkable_point_toward(", "for _step: int in range(8)"),
    ("_connect_endpoint_to_graph(", "connected_count"),
    ("_nearest_waypoint_indices(", "distances.insert("),
    ("_is_walk_segment_clear(", "PhysicsRayQueryParameters3D.create("),
    ("_is_center_segment_clear(", "PhysicsRayQueryParameters3D.create("),
]:
    if forbidden in function_body(BASE, name):
        errors.append(f"Navigation hesabı hâlâ combatant içinde: {name} -> {forbidden}")

# Scene/state side effects and actual movement remain in the orchestrators.
for token in [
    'get_tree().get_nodes_in_group("enemy_navigation_waypoint")',
    "_shared_navigation_caches",
    "func _navigate_to(target: Vector3, delta: float) -> void:",
    "func _move_toward_point(target: Vector3, delta: float) -> void:",
    "velocity.x = move_toward(",
    "velocity.z = move_toward(",
    "move_and_slide()",
    "func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:",
]:
    require(BASE, token, "Combatant orchestrator ownership eksik")

for token in [
    "func _chase_position(delta: float, target_position: Vector3, use_chase_speed: bool = true) -> void:",
    "func _update_chase_detour() -> void:",
    "get_slide_collision_count()",
    "get_slide_collision(collision_index)",
    "velocity.x = move_toward(",
    "velocity.z = move_toward(",
    "rotation.y = atan2(",
    "move_and_slide()",
]:
    require(LUNGE, token, "Lunge orchestrator ownership eksik")

# Navigation helper must not own gameplay state-machine or CharacterBody movement.
for forbidden in [
    "GameState",
    "State.CHASE",
    "move_and_slide()",
    "velocity.x =",
    "velocity.z =",
    "get_slide_collision_count()",
    "get_slide_collision(",
    'get_nodes_in_group("enemy_navigation_waypoint")',
    "_shared_navigation_caches",
]:
    if forbidden in RUNTIME:
        errors.append(f"Navigation runtime side-effect/state ownership aldı: {forbidden}")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)

print("enemy navigation architecture audit passed")
