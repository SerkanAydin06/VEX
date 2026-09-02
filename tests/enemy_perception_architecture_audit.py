#!/usr/bin/env python3
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "scripts" / "actors" / "enemy_combatant_base.gd"
RUNTIME = ROOT / "scripts" / "actors" / "enemy_perception_runtime.gd"

errors: list[str] = []


def read(path: Path) -> str:
    if not path.exists():
        errors.append(f"Eksik dosya: {path.relative_to(ROOT)}")
        return ""
    return path.read_text(encoding="utf-8")


def function_body(source: str, name: str) -> str:
    marker = f"func {name}"
    start = source.find(marker)
    if start < 0:
        errors.append(f"Eksik fonksiyon: {name}")
        return ""
    next_func = source.find("\n\nfunc ", start + len(marker))
    return source[start:] if next_func < 0 else source[start:next_func]


base = read(BASE)
runtime = read(RUNTIME)

for contract in [
    "VexEnemyPerceptionRuntime.active_detection_range(",
    "VexEnemyPerceptionRuntime.is_player_inside_initial_view(",
    "VexEnemyPerceptionRuntime.passes_crouch_detection(",
    "VexEnemyPerceptionRuntime.has_visual_contact(",
    "VexEnemyPerceptionRuntime.ranged_visibility_ratio_from(",
    "VexEnemyPerceptionRuntime.crouched_sight_target_height(",
    "VexEnemyPerceptionRuntime.is_player_collider(",
]:
    if contract not in base:
        errors.append(f"Combatant perception delegation eksik: {contract}")

for contract in [
    "class_name VexEnemyPerceptionRuntime",
    "func active_detection_range(",
    "func is_player_inside_initial_view(",
    "func passes_crouch_detection(",
    "VexEnemyRuntimeUtils.has_visual_contact(",
    "func ranged_visibility_ratio_from(",
    "PhysicsRayQueryParameters3D.create(",
    "var visible_samples := 0",
    "func is_player_collider(",
]:
    if contract not in runtime:
        errors.append(f"Perception runtime contract eksik: {contract}")

can_see = function_body(base, "_can_see_player(")
initial_view = function_body(base, "_is_player_inside_initial_view(")
line_of_sight = function_body(base, "_check_line_of_sight(")
ranged_ratio = function_body(base, "_ranged_visibility_ratio_from(")
player_collider = function_body(base, "_is_player_collider(")

if "randf()" in can_see:
    errors.append("Crouch detection RNG hâlâ combatant base içinde")
if "cos(deg_to_rad" in initial_view:
    errors.append("Initial view cone hesabı hâlâ combatant base içinde")
if "VexEnemyRuntimeUtils.has_visual_contact(" in line_of_sight:
    errors.append("Visual contact çözümü hâlâ combatant base içinde")
if "visible_samples" in ranged_ratio or "PhysicsRayQueryParameters3D.create(" in ranged_ratio:
    errors.append("Ranged visibility sampling hâlâ combatant base içinde")
if "while current != null" in player_collider:
    errors.append("Player collider ancestry çözümü hâlâ combatant base içinde")

if errors:
    for error in errors:
        print(f"ERROR: {error}")
    raise SystemExit(1)

print("enemy perception architecture audit passed")
