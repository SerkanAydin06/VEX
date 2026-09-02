#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def function_block(source: str, function_name: str) -> str:
    marker = f"func {function_name}("
    start = source.index(marker)
    end = source.find("\n\nfunc ", start + len(marker))
    return source[start:] if end < 0 else source[start:end]


def assert_order(block: str, *tokens: str) -> None:
    positions = [block.index(token) for token in tokens]
    assert positions == sorted(positions), (tokens, positions)


lunge = function_block(read("scripts/actors/enemy_lunge_base.gd"), "_attempt_attack")
assert_order(
    lunge,
    '_player.call("take_damage"',
    '_play_animation(&"idle")',
    "var remaining: float",
)

combatant = function_block(read("scripts/actors/enemy_combatant_base.gd"), "_attempt_attack")
assert_order(
    combatant,
    "_fire_projectile()",
    '_play_directional_animation(&"idle", &"idle_back")',
    "var remaining := EnemyCombatRuntime.remaining_attack_cooldown(",
)

hybrid = function_block(read("scripts/actors/enemy_hybrid_base.gd"), "_begin_hybrid_attack")
assert_order(
    hybrid,
    "_resolve_ranged_shot()",
    '_play_directional_animation(&"idle", &"idle_back")',
    "var recovery := maxf(",
)

carrier = function_block(read("scripts/actors/furnice_carrier.gd"), "_attempt_attack")
assert_order(
    carrier,
    "_fire_furnice_projectile()",
    '_play_directional_animation(&"idle", &"idle_back")',
    "var runtime_attack_cooldown :=",
)

warden_source = read("scripts/actors/crucible_warden.gd")
for function_name, impact_token in [
    ("_begin_ground_slam_attack", "_emit_ground_slam()"),
    ("_begin_heatwave_attack", "_emit_heatwave()"),
]:
    block = function_block(warden_source, function_name)
    assert_order(
        block,
        impact_token,
        '_play_directional_animation(&"idle", &"idle_back")',
        "var recovery := maxf(",
    )

gorehorn = function_block(read("scripts/actors/gorehorn.gd"), "_attempt_attack")
charge_end = gorehorn.index("_stop_charge_motion(false)")
recovery_pose = gorehorn.index('_play_animation(&"idle")', charge_end)
recovery_timer = gorehorn.index("var recovery :=", recovery_pose)
assert charge_end < recovery_pose < recovery_timer

print("enemy attack recovery animation audit passed")
