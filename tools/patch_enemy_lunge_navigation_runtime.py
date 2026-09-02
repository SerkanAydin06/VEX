from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
NAV = ROOT / "scripts/actors/enemy_navigation_runtime.gd"
LUNGE = ROOT / "scripts/actors/enemy_lunge_base.gd"
TEST = ROOT / "tests/enemy_navigation_runtime_test.gd"
AUDIT = ROOT / "tests/enemy_navigation_architecture_audit.py"


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected 1 match, got {count}")
    return text.replace(old, new, 1)


nav = NAV.read_text(encoding="utf-8")
if "static func should_refresh_path(" in nav:
    raise SystemExit("navigation helpers already present")
nav += '''\n\nstatic func should_refresh_path(\n    has_navigation_target: bool,\n    navigation_refresh_remaining: float,\n    navigation_target: Vector3,\n    resolved_target: Vector3,\n    target_change_distance: float\n) -> bool:\n    if not has_navigation_target or navigation_refresh_remaining <= 0.0:\n        return true\n    return _horizontal_distance(navigation_target, resolved_target) > target_change_distance\n\n\nstatic func active_movement_direction(\n    current_position: Vector3,\n    movement_point: Vector3,\n    detour_remaining: float,\n    detour_direction: Vector3\n) -> Vector3:\n    var direction := movement_point - current_position\n    direction.y = 0.0\n    if direction.length_squared() <= 0.001:\n        return Vector3.ZERO\n    direction = direction.normalized()\n    if detour_remaining > 0.0 and detour_direction.length_squared() > 0.001:\n        return detour_direction\n    return direction\n\n\nstatic func movement_speed(\n    use_chase_speed: bool,\n    runtime_move_speed: float,\n    runtime_chase_speed: float\n) -> float:\n    return runtime_chase_speed if use_chase_speed else runtime_move_speed\n\n\nstatic func detour_direction_from_collision_normal(\n    collision_normal: Vector3,\n    current_position: Vector3,\n    movement_target: Vector3,\n    wall_normal_y_threshold: float\n) -> Vector3:\n    var normal := collision_normal\n    if absf(normal.y) >= wall_normal_y_threshold:\n        return Vector3.ZERO\n    normal.y = 0.0\n    if normal.length_squared() <= 0.001:\n        return Vector3.ZERO\n    normal = normal.normalized()\n    var tangent_a := Vector3(-normal.z, 0.0, normal.x)\n    var tangent_b: Vector3 = -tangent_a\n    var target_direction := movement_target - current_position\n    target_direction.y = 0.0\n    if target_direction.length_squared() > 0.001:\n        target_direction = target_direction.normalized()\n    return (\n        tangent_a\n        if tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)\n        else tangent_b\n    )\n'''
NAV.write_text(nav, encoding="utf-8")

lunge = LUNGE.read_text(encoding="utf-8")
lunge = replace_once(
    lunge,
    '''\tvar target_changed := (\n\t\tnot _has_navigation_target\n\t\tor _horizontal_distance(_navigation_target, resolved_target) > path_target_change_distance\n\t)\n\tif _navigation_refresh_remaining <= 0.0 or target_changed:\n''',
    '''\tif EnemyNavigationRuntime.should_refresh_path(\n\t\t_has_navigation_target,\n\t\t_navigation_refresh_remaining,\n\t\t_navigation_target,\n\t\tresolved_target,\n\t\tpath_target_change_distance\n\t):\n''',
    "path refresh",
)
lunge = replace_once(
    lunge,
    '''\tvar direction: Vector3 = movement_point - global_position\n\tdirection.y = 0.0\n\tif direction.length_squared() <= 0.001:\n\t\tvelocity.x = 0.0\n\t\tvelocity.z = 0.0\n\t\t_play_animation(&"idle")\n\t\treturn\n\tdirection = direction.normalized()\n\n\t# Collision tangent is now only a fallback when the shared global path is\n\t# temporarily obstructed by a moving body/door.\n\tif _detour_remaining > 0.0 and _detour_direction.length_squared() > 0.001:\n\t\tdirection = _detour_direction\n\n\t_facing_direction = direction\n\tvar desired_speed := _runtime_chase_speed if use_chase_speed else _runtime_move_speed\n''',
    '''\tvar direction := EnemyNavigationRuntime.active_movement_direction(\n\t\tglobal_position,\n\t\tmovement_point,\n\t\t_detour_remaining,\n\t\t_detour_direction\n\t)\n\tif direction.length_squared() <= 0.001:\n\t\tvelocity.x = 0.0\n\t\tvelocity.z = 0.0\n\t\t_play_animation(&"idle")\n\t\treturn\n\n\t_facing_direction = direction\n\tvar desired_speed := EnemyNavigationRuntime.movement_speed(\n\t\tuse_chase_speed,\n\t\t_runtime_move_speed,\n\t\t_runtime_chase_speed\n\t)\n''',
    "movement direction",
)
lunge = replace_once(
    lunge,
    '''\t\tvar normal := collision.get_normal()\n\t\tif absf(normal.y) >= wall_normal_y_threshold:\n\t\t\tcontinue\n\t\tnormal.y = 0.0\n\t\tif normal.length_squared() <= 0.001:\n\t\t\tcontinue\n\t\tnormal = normal.normalized()\n\t\tvar tangent_a := Vector3(-normal.z, 0.0, normal.x)\n\t\tvar tangent_b: Vector3 = -tangent_a\n\t\tvar target_direction := _movement_target - global_position\n\t\ttarget_direction.y = 0.0\n\t\tif target_direction.length_squared() > 0.001:\n\t\t\ttarget_direction = target_direction.normalized()\n\t\t_detour_direction = (\n\t\t\ttangent_a\n\t\t\tif tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)\n\t\t\telse tangent_b\n\t\t)\n\t\t_detour_remaining = detour_duration\n\t\treturn\n''',
    '''\t\tvar detour_direction := EnemyNavigationRuntime.detour_direction_from_collision_normal(\n\t\t\tcollision.get_normal(),\n\t\t\tglobal_position,\n\t\t\t_movement_target,\n\t\t\twall_normal_y_threshold\n\t\t)\n\t\tif detour_direction.length_squared() <= 0.001:\n\t\t\tcontinue\n\t\t_detour_direction = detour_direction\n\t\t_detour_remaining = detour_duration\n\t\treturn\n''',
    "detour tangent",
)
LUNGE.write_text(lunge, encoding="utf-8")

test = TEST.read_text(encoding="utf-8")
test = replace_once(
    test,
    '''\t_test_investigation_helpers(host)\n\t_test_local_detour(host)\n''',
    '''\t_test_investigation_helpers(host)\n\t_test_local_detour(host)\n\t_test_path_motion_helpers()\n''',
    "test call",
)
if "func _test_path_motion_helpers()" in test:
    raise SystemExit("path motion test already present")
test += '''\n\nfunc _test_path_motion_helpers() -> void:\n\t_expect(\n\t\tVexEnemyNavigationRuntime.should_refresh_path(\n\t\t\tfalse, 1.0, Vector3.ZERO, Vector3.ZERO, 1.2\n\t\t),\n\t\t"Missing navigation target no longer refreshes path"\n\t)\n\t_expect(\n\t\tnot VexEnemyNavigationRuntime.should_refresh_path(\n\t\t\ttrue, 0.2, Vector3.ZERO, Vector3(0.5, 5.0, 0.0), 1.2\n\t\t),\n\t\t"Small horizontal target change refreshes path early"\n\t)\n\t_expect(\n\t\tVexEnemyNavigationRuntime.should_refresh_path(\n\t\t\ttrue, 0.2, Vector3.ZERO, Vector3(2.0, 0.0, 0.0), 1.2\n\t\t),\n\t\t"Large target change no longer refreshes path"\n\t)\n\t_expect(\n\t\tVexEnemyNavigationRuntime.should_refresh_path(\n\t\t\ttrue, 0.0, Vector3.ZERO, Vector3.ZERO, 1.2\n\t\t),\n\t\t"Expired refresh timer no longer rebuilds path"\n\t)\n\n\tvar direct := VexEnemyNavigationRuntime.active_movement_direction(\n\t\tVector3.ZERO, Vector3(4.0, 9.0, 0.0), 0.0, Vector3.ZERO\n\t)\n\t_expect(direct.is_equal_approx(Vector3.RIGHT), "Direct movement direction changed")\n\tvar detour := VexEnemyNavigationRuntime.active_movement_direction(\n\t\tVector3.ZERO, Vector3(4.0, 0.0, 0.0), 0.5, Vector3(0.0, 0.0, 1.0)\n\t)\n\t_expect(detour.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Active detour direction ignored")\n\t_expect(\n\t\tis_zero_approx(\n\t\t\tVexEnemyNavigationRuntime.active_movement_direction(\n\t\t\t\tVector3.ZERO, Vector3(0.01, 5.0, 0.01), 0.0, Vector3.ZERO\n\t\t\t).length()\n\t\t),\n\t\t"Near-zero movement target no longer stops"\n\t)\n\t_expect(\n\t\tis_equal_approx(VexEnemyNavigationRuntime.movement_speed(true, 2.0, 5.0), 5.0),\n\t\t"Chase movement speed selection changed"\n\t)\n\t_expect(\n\t\tis_equal_approx(VexEnemyNavigationRuntime.movement_speed(false, 2.0, 5.0), 2.0),\n\t\t"Normal movement speed selection changed"\n\t)\n\n\tvar tangent := VexEnemyNavigationRuntime.detour_direction_from_collision_normal(\n\t\tVector3.RIGHT, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), 0.55\n\t)\n\t_expect(tangent.is_equal_approx(Vector3(0.0, 0.0, 1.0)), "Detour tangent selection changed")\n\tvar floor_normal := VexEnemyNavigationRuntime.detour_direction_from_collision_normal(\n\t\tVector3.UP, Vector3.ZERO, Vector3(0.0, 0.0, 5.0), 0.55\n\t)\n\t_expect(floor_normal.is_equal_approx(Vector3.ZERO), "Floor-like collision now creates detour")\n'''
TEST.write_text(test, encoding="utf-8")

audit = AUDIT.read_text(encoding="utf-8")
audit = replace_once(
    audit,
    'BASE = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")\nRUNTIME = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")\n',
    'BASE = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")\nLUNGE = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")\nRUNTIME = (ROOT / "scripts/actors/enemy_navigation_runtime.gd").read_text(encoding="utf-8")\n',
    "audit lunge source",
)
audit = replace_once(
    audit,
    '    "static func build_local_detour_path(",\n]:\n',
    '    "static func build_local_detour_path(",\n    "static func should_refresh_path(",\n    "static func active_movement_direction(",\n    "static func movement_speed(",\n    "static func detour_direction_from_collision_normal(",\n]:\n',
    "audit runtime contracts",
)
insert_marker = '# Public/protected compatibility wrappers must remain available to subclasses.\n'
if insert_marker not in audit:
    raise SystemExit("audit insert marker missing")
audit = audit.replace(
    insert_marker,
    '''for token in [\n    "EnemyNavigationRuntime.should_refresh_path(",\n    "EnemyNavigationRuntime.active_movement_direction(",\n    "EnemyNavigationRuntime.movement_speed(",\n    "EnemyNavigationRuntime.detour_direction_from_collision_normal(",\n]:\n    require(LUNGE, token, "Lunge navigation delegation eksik")\n\nfor forbidden in [\n    "var target_changed := (",\n    "var tangent_a := Vector3(-normal.z, 0.0, normal.x)",\n    "_runtime_chase_speed if use_chase_speed else _runtime_move_speed",\n]:\n    if forbidden in LUNGE:\n        errors.append(f"Navigation hesabı hâlâ lunge base içinde: {forbidden}")\n\n''' + insert_marker,
    1,
)
AUDIT.write_text(audit, encoding="utf-8")

print("lunge navigation runtime patch applied")
