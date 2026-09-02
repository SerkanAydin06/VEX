from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
lunge = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")
lunge_runtime = (ROOT / "scripts/actors/enemy_lunge_runtime.gd").read_text(encoding="utf-8")
combat_runtime = (ROOT / "scripts/actors/enemy_combat_runtime.gd").read_text(encoding="utf-8")


def function_block(source: str, function_name: str) -> str:
    marker = f"func {function_name}("
    start = source.index(marker)
    end = source.find("\n\nfunc ", start + len(marker))
    return source[start:] if end < 0 else source[start:end]


assert "class_name VexEnemyLungeRuntime" in lunge_runtime
assert "extends RefCounted" in lunge_runtime
for forbidden in ("GameState", "Input.", "get_tree()", "instantiate(", "move_and_slide"):
    assert forbidden not in lunge_runtime

assert 'const EnemyLungeRuntime = preload("res://scripts/actors/enemy_lunge_runtime.gd")' in lunge
assert "EnemyLungeRuntime.attack_lunge_plan(" in lunge
assert "EnemyLungeRuntime.initial_attack_lunge_duration(" in lunge

for helper in (
    "EnemyCombatRuntime.damage_pursuit_progress(",
    "EnemyCombatRuntime.should_abandon_damage_pursuit(",
    "EnemyCombatRuntime.should_check_close_combat_visibility(",
    "EnemyCombatRuntime.should_start_attack(",
    "EnemyCombatRuntime.can_attempt_damage_handoff(",
    "EnemyCombatRuntime.should_resolve_attack_after_windup(",
    "EnemyCombatRuntime.remaining_attack_cooldown(",
):
    assert helper in lunge

assert "func should_resolve_attack_after_windup(" in combat_runtime

lunge_motion = function_block(lunge, "_update_attack_lunge")
assert "EnemyLungeRuntime.attack_lunge_plan(" in lunge_motion
assert "direction /= distance" not in lunge_motion
assert "direction.x * _runtime_attack_lunge_speed" not in lunge_motion
assert "direction.z * _runtime_attack_lunge_speed" not in lunge_motion
assert "move_toward(" in lunge_motion

attack = function_block(lunge, "_attempt_attack")
assert 'await get_tree().create_timer(_runtime_attack_windup).timeout' in attack
assert '_player.call("take_damage"' in attack
assert '_play_animation(&"attack")' in attack
assert '_play_animation(&"idle")' in attack
assert "EnemyCombatRuntime.should_resolve_attack_after_windup(" in attack
assert "EnemyCombatRuntime.remaining_attack_cooldown(" in attack
assert "_runtime_attack_cooldown - _runtime_attack_windup" not in attack

handoff = function_block(lunge, "_can_handoff_damage_pursuit_to_combat")
assert "EnemyCombatRuntime.can_attempt_damage_handoff(" in handoff
assert "_check_line_of_sight()" in handoff

physics = function_block(lunge, "_physics_process")
assert "EnemyCombatRuntime.damage_pursuit_progress(" in physics
assert "EnemyCombatRuntime.should_abandon_damage_pursuit(" in physics
assert "EnemyCombatRuntime.should_check_close_combat_visibility(" in physics
assert "move_and_slide()" in physics

print("enemy lunge combat architecture audit passed")
