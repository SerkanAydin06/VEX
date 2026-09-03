from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = (ROOT / "scripts/actors/enemy_base.gd").read_text(encoding="utf-8")
COMBATANT = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
LUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

errors: list[str] = []

if "func _is_player_inside_initial_view(initial_view_angle_value: float) -> bool:" not in BASE:
    errors.append("enemy_base.gd must own parameterized initial-view helper")
if "func _is_observer_behind_enemy(back_view_threshold_value: float) -> bool:" not in BASE:
    errors.append("enemy_base.gd must own parameterized observer-direction helper")
if "const EnemyPerceptionRuntime = preload(" not in BASE:
    errors.append("enemy_base.gd must explicitly preload the perception runtime")

for name, source in (("combatant", COMBATANT), ("lunge", LUNGE)):
    if "func _is_player_inside_initial_view() -> bool:" in source:
        errors.append(f"{name} must not redeclare _is_player_inside_initial_view")
    if "func _is_observer_behind_enemy() -> bool:" in source:
        errors.append(f"{name} must not redeclare _is_observer_behind_enemy")
    if "_is_player_inside_initial_view(initial_view_angle)" not in source:
        errors.append(f"{name} must pass scene-owned initial_view_angle to the parent helper")
    if "_is_observer_behind_enemy(back_view_threshold)" not in source:
        errors.append(f"{name} must pass scene-owned back_view_threshold to the parent helper")

if errors:
    raise SystemExit("\n".join(errors))

print("Enemy common perception helper architecture audit passed")
