from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BASE = ROOT / "scripts/actors/enemy_base.gd"
CHILDREN = [
    ROOT / "scripts/actors/enemy_combatant_base.gd",
    ROOT / "scripts/actors/enemy_lunge_base.gd",
]


def remove_local_function(source: str, signature: str) -> str:
    lines = source.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith(signature)]
    if not starts:
        return source
    if len(starts) != 1:
        raise SystemExit(f"expected one {signature!r}, found {len(starts)}")
    start = starts[0]
    end = next((i for i in range(start + 1, len(lines)) if lines[i].startswith("func ")), len(lines))
    del lines[start:end]
    return "".join(lines)


base = BASE.read_text(encoding="utf-8")
perception_const = 'const EnemyPerceptionRuntime = preload("res://scripts/actors/enemy_perception_runtime.gd")\n'
if perception_const not in base:
    anchor = 'const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")\n'
    if anchor not in base:
        raise SystemExit("enemy_base.gd combat runtime preload anchor not found")
    base = base.replace(anchor, anchor + perception_const, 1)

helpers = '''func _is_player_inside_initial_view(initial_view_angle_value: float) -> bool:
\tif _player == null or not is_instance_valid(_player):
\t\treturn false
\treturn EnemyPerceptionRuntime.is_player_inside_initial_view(
\t\tglobal_position,
\t\t_facing_direction,
\t\t_player.global_position,
\t\tinitial_view_angle_value
\t)


func _is_observer_behind_enemy(back_view_threshold_value: float) -> bool:
\tvar observer_position := Vector3.ZERO
\tvar camera := get_viewport().get_camera_3d()
\tif camera != null:
\t\tobserver_position = camera.global_position
\telif _player != null and is_instance_valid(_player):
\t\tobserver_position = _player.global_position
\telse:
\t\treturn false

\tvar direction_to_observer := observer_position - global_position
\tdirection_to_observer.y = 0.0
\tif direction_to_observer.length_squared() <= 0.001:
\t\treturn false
\treturn (
\t\t_facing_direction.dot(direction_to_observer.normalized())
\t\t< back_view_threshold_value
\t)


'''
helper_anchor = "func _trigger_damage_shake(\n"
if "func _is_player_inside_initial_view(initial_view_angle_value: float) -> bool:" not in base:
    if helper_anchor not in base:
        raise SystemExit("enemy_base.gd helper insertion anchor not found")
    base = base.replace(helper_anchor, helpers + helper_anchor, 1)
BASE.write_text(base, encoding="utf-8")

for path in CHILDREN:
    text = path.read_text(encoding="utf-8")
    text = remove_local_function(text, "func _is_player_inside_initial_view() -> bool:")
    text = remove_local_function(text, "func _is_observer_behind_enemy() -> bool:")
    text = text.replace(
        "_is_player_inside_initial_view()",
        "_is_player_inside_initial_view(initial_view_angle)",
    )
    text = text.replace(
        "_is_observer_behind_enemy()",
        "_is_observer_behind_enemy(back_view_threshold)",
    )
    path.write_text(text, encoding="utf-8")

AUDIT = ROOT / "tests/enemy_common_perception_helper_architecture_audit.py"
AUDIT.write_text(
    '''from pathlib import Path

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
    raise SystemExit("\\n".join(errors))

print("Enemy common perception helper architecture audit passed")
''',
    encoding="utf-8",
)
