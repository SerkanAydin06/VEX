from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_exact(path: Path, old: str, new: str) -> None:
    text = path.read_text(encoding="utf-8")
    if old not in text:
        raise SystemExit(f"missing expected block in {path.relative_to(ROOT)}")
    if text.count(old) != 1:
        raise SystemExit(f"expected exactly one block in {path.relative_to(ROOT)}, got {text.count(old)}")
    path.write_text(text.replace(old, new, 1), encoding="utf-8")


lunge = ROOT / "scripts/actors/enemy_lunge_base.gd"

replace_exact(
    lunge,
    '''\t\tvar active_sight_range: float = (\n\t\t\t_runtime_pursuit_range\n\t\t\tif _aggro\n\t\t\telse _runtime_detection_range\n\t\t)\n\t\tif _damage_reaction_remaining > 0.0:\n\t\t\tactive_sight_range = maxf(active_sight_range, damage_reaction_range)\n''',
    '''\t\tvar active_sight_range := VexEnemyPerceptionRuntime.active_detection_range(\n\t\t\t_aggro,\n\t\t\t_runtime_detection_range,\n\t\t\t_runtime_pursuit_range,\n\t\t\t_damage_reaction_remaining,\n\t\t\tdamage_reaction_range\n\t\t)\n''',
)

replace_exact(
    lunge,
    '''func _is_player_inside_initial_view() -> bool:\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\tif initial_view_angle >= 359.9:\n\t\treturn true\n\tvar player_direction := _player.global_position - global_position\n\tplayer_direction.y = 0.0\n\tif player_direction.length_squared() <= 0.001:\n\t\treturn true\n\tplayer_direction = player_direction.normalized()\n\tvar view_threshold := cos(deg_to_rad(initial_view_angle * 0.5))\n\treturn _facing_direction.dot(player_direction) >= view_threshold\n''',
    '''func _is_player_inside_initial_view() -> bool:\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\treturn VexEnemyPerceptionRuntime.is_player_inside_initial_view(\n\t\tglobal_position,\n\t\t_facing_direction,\n\t\t_player.global_position,\n\t\tinitial_view_angle\n\t)\n''',
)

replace_exact(
    lunge,
    '''func _check_line_of_sight() -> bool:\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\tvar origin := global_position + Vector3.UP * sight_origin_height\n\tif not VexEnemyRuntimeUtils.has_visual_contact(\n\t\tget_world_3d(),\n\t\torigin,\n\t\t_player,\n\t\tsight_collision_mask,\n\t\tget_rid(),\n\t\tsight_target_height,\n\t\tvisibility_vertical_span_scale,\n\t\tvisibility_vertical_span_min,\n\t\tvisibility_vertical_span_max,\n\t\tvisibility_lateral_span_scale,\n\t\tvisibility_lateral_span_min,\n\t\tvisibility_lateral_span_max,\n\t\tvisibility_shoulder_height_ratio,\n\t\tvisibility_lower_body_ratio\n\t):\n\t\treturn false\n\n\tvar player_distance := _horizontal_distance(global_position, _player.global_position)\n\tif (\n\t\tnot _aggro\n\t\tand _player.get("is_crouching") == true\n\t\tand player_distance > crouch_guaranteed_detection_distance\n\t):\n\t\treturn randf() <= crouch_detection_chance\n\treturn true\n''',
    '''func _check_line_of_sight() -> bool:\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn false\n\tvar origin := global_position + Vector3.UP * sight_origin_height\n\tif not VexEnemyPerceptionRuntime.has_visual_contact(\n\t\tself,\n\t\t_player,\n\t\torigin,\n\t\tsight_collision_mask,\n\t\tsight_target_height,\n\t\tvisibility_vertical_span_scale,\n\t\tvisibility_vertical_span_min,\n\t\tvisibility_vertical_span_max,\n\t\tvisibility_lateral_span_scale,\n\t\tvisibility_lateral_span_min,\n\t\tvisibility_lateral_span_max,\n\t\tvisibility_shoulder_height_ratio,\n\t\tvisibility_lower_body_ratio\n\t):\n\t\treturn false\n\n\tvar player_distance := _horizontal_distance(global_position, _player.global_position)\n\treturn VexEnemyPerceptionRuntime.passes_crouch_detection(\n\t\t_aggro,\n\t\t_player.get("is_crouching") == true,\n\t\tplayer_distance,\n\t\tcrouch_guaranteed_detection_distance,\n\t\tcrouch_detection_chance\n\t)\n''',
)

replace_exact(
    lunge,
    '''func _get_crouched_sight_target_height() -> float:\n\tvar shape_node := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D\n\tif shape_node != null:\n\t\tvar capsule := shape_node.shape as CapsuleShape3D\n\t\tif capsule != null:\n\t\t\tvar top_height := shape_node.position.y + (capsule.height * 0.5)\n\t\t\treturn clampf(\n\t\t\t\ttop_height * crouched_target_height_scale,\n\t\t\t\tcrouched_target_min_height,\n\t\t\t\tsight_target_height\n\t\t\t)\n\treturn 0.0\n''',
    '''func _get_crouched_sight_target_height() -> float:\n\treturn VexEnemyPerceptionRuntime.crouched_sight_target_height(\n\t\t_player,\n\t\tsight_target_height,\n\t\tcrouched_target_height_scale,\n\t\tcrouched_target_min_height\n\t)\n''',
)

replace_exact(
    lunge,
    '''\tvar distance := _horizontal_distance(global_position, noise_position)\n\tvar effective_range := hearing_radius * maxf(loudness * hearing_loudness_scale, 0.1)\n\tif distance > effective_range:\n\t\treturn\n''',
    '''\tif not VexEnemyPerceptionRuntime.should_hear_noise(\n\t\tglobal_position,\n\t\tnoise_position,\n\t\thearing_radius,\n\t\tloudness,\n\t\thearing_loudness_scale\n\t):\n\t\treturn\n''',
)

replace_exact(
    lunge,
    '''\tif loudness >= loud_noise_alert_threshold:\n\t\t_alert_nearby_allies(noise_position)\n''',
    '''\tif VexEnemyPerceptionRuntime.should_broadcast_noise_alert(\n\t\tloudness, loud_noise_alert_threshold\n\t):\n\t\t_alert_nearby_allies(noise_position)\n''',
)

# Existing awareness audit should now validate the shared perception facade.
detection = ROOT / "tests/enemy_detection_audit.py"
replace_exact(
    detection,
    '''for needle in [\n    "search_probe_radius := 2.0",\n    "VexEnemyRuntimeUtils.has_visual_contact(",\n    "func _investigate_last_seen(delta: float)",\n''',
    '''for needle in [\n    "search_probe_radius := 2.0",\n    "VexEnemyPerceptionRuntime.has_visual_contact(",\n    "func _investigate_last_seen(delta: float)",\n''',
)

# Extend perception architecture ownership checks to lunge without changing its
# family-specific cache cadence or 3D ally broadcast distance semantics.
audit = ROOT / "tests/enemy_perception_architecture_audit.py"
text = audit.read_text(encoding="utf-8")
text = text.replace(
    'BASE = ROOT / "scripts" / "actors" / "enemy_combatant_base.gd"\nRUNTIME = ROOT / "scripts" / "actors" / "enemy_perception_runtime.gd"\n',
    'BASE = ROOT / "scripts" / "actors" / "enemy_combatant_base.gd"\nLUNGE = ROOT / "scripts" / "actors" / "enemy_lunge_base.gd"\nRUNTIME = ROOT / "scripts" / "actors" / "enemy_perception_runtime.gd"\n',
    1,
)
text = text.replace(
    'base = read(BASE)\nruntime = read(RUNTIME)\n',
    'base = read(BASE)\nlunge = read(LUNGE)\nruntime = read(RUNTIME)\n',
    1,
)
anchor = '''for contract in [\n    "class_name VexEnemyPerceptionRuntime",\n'''
insert = '''for contract in [\n    "VexEnemyPerceptionRuntime.active_detection_range(",\n    "VexEnemyPerceptionRuntime.is_player_inside_initial_view(",\n    "VexEnemyPerceptionRuntime.passes_crouch_detection(",\n    "VexEnemyPerceptionRuntime.has_visual_contact(",\n    "VexEnemyPerceptionRuntime.crouched_sight_target_height(",\n    "VexEnemyPerceptionRuntime.should_hear_noise(",\n    "VexEnemyPerceptionRuntime.should_broadcast_noise_alert(",\n]:\n    if contract not in lunge:\n        errors.append(f"Lunge perception delegation eksik: {contract}")\n\n''' + anchor
if anchor not in text:
    raise SystemExit("missing architecture runtime anchor")
text = text.replace(anchor, insert, 1)
anchor2 = '''can_see = function_body(base, "_can_see_player(")\n'''
insert2 = '''lunge_initial_view = function_body(lunge, "_is_player_inside_initial_view(")\nlunge_line_of_sight = function_body(lunge, "_check_line_of_sight(")\nlunge_crouched_height = function_body(lunge, "_get_crouched_sight_target_height(")\nlunge_noise_handler = function_body(lunge, "_on_noise_emitted(")\n\n''' + anchor2
if anchor2 not in text:
    raise SystemExit("missing architecture function anchor")
text = text.replace(anchor2, insert2, 1)
anchor3 = '''if "hearing_radius * maxf(" in noise_handler:\n'''
insert3 = '''if "cos(deg_to_rad" in lunge_initial_view:\n    errors.append("Initial view cone hesabı hâlâ lunge base içinde")\nif "VexEnemyRuntimeUtils.has_visual_contact(" in lunge_line_of_sight:\n    errors.append("Visual contact çözümü hâlâ lunge base içinde")\nif "randf()" in lunge_line_of_sight:\n    errors.append("Crouch detection RNG hâlâ lunge base içinde")\nif 'get_node_or_null("CollisionShape3D")' in lunge_crouched_height:\n    errors.append("Crouched target-height çözümü hâlâ lunge base içinde")\nif "hearing_radius * maxf(" in lunge_noise_handler:\n    errors.append("Hearing effective-range hesabı hâlâ lunge base içinde")\nif "loudness >= loud_noise_alert_threshold" in lunge_noise_handler:\n    errors.append("Noise ally-alert threshold kararı hâlâ lunge base içinde")\n\n''' + anchor3
if anchor3 not in text:
    raise SystemExit("missing architecture duplicate-math anchor")
text = text.replace(anchor3, insert3, 1)
audit.write_text(text, encoding="utf-8")
