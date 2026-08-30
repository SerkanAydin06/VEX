#!/usr/bin/env python3
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parents[1]
COMBATANT = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")


def function_body(source: str, function_name: str) -> str:
    match = re.search(
        rf"(?ms)^func {re.escape(function_name)}\([^\n]*\) -> void:\n(.*?)(?=^func |\Z)",
        source,
    )
    assert match is not None, function_name
    return match.group(1)


combatant_idle = function_body(COMBATANT, "_patrol")
assert "state = State.IDLE" in combatant_idle
assert "_clear_path()" in combatant_idle
assert "_stop_horizontal_motion()" in combatant_idle

lunge_idle = function_body(LUNGE, "_hold_idle_position")
assert '_play_animation(&"idle")' in lunge_idle
assert "_reset_navigation_path()" in lunge_idle
assert "move_and_slide()" in lunge_idle

for source in (COMBATANT, LUNGE):
    assert "EnemyNavigationRuntime.choose_idle_wander_target(" not in source
    assert "_facing_direction.rotated(Vector3.UP, delta * idle_turn_speed)" not in source
    for legacy in (
        "patrol_offset", "idle_wander_radius", "idle_wander_attempts",
        "idle_wander_min_radius_ratio", "idle_pause_min", "idle_pause_max",
        "idle_turn_speed", "idle_target_min_distance",
    ):
        assert re.search(rf"@export_storage var {legacy}\b", source), legacy
        assert not re.search(rf"@export_range[^\n]*\bvar {legacy}\b", source), legacy
        assert not re.search(rf"@export var {legacy}\b", source), legacy

assert "@export_storage var patrol_pause_duration" in LUNGE
assert "02 - Hareket ve Sabit Bekleme" in COMBATANT
assert "02 - Hareket ve Sabit Bekleme" in LUNGE

print("enemy stationary idle audit passed")
