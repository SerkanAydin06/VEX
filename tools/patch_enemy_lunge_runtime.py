from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def read(path: str) -> str:
    return (ROOT / path).read_text(encoding="utf-8")


def write(path: str, content: str) -> None:
    (ROOT / path).write_text(content, encoding="utf-8")


def replace_once(source: str, old: str, new: str, label: str) -> str:
    count = source.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected exactly one match, found {count}")
    return source.replace(old, new, 1)


def replace_function(source: str, function_name: str, new_block: str) -> str:
    marker = f"func {function_name}("
    start = source.find(marker)
    if start < 0:
        raise RuntimeError(f"missing function {function_name}")
    end = source.find("\n\nfunc ", start + len(marker))
    if end < 0:
        end = len(source)
    return source[:start] + new_block.rstrip() + source[end:]


combat_path = "scripts/actors/enemy_combat_runtime.gd"
combat = read(combat_path)
combat = replace_once(
    combat,
    '''static func should_start_attack(distance_to_target: float, attack_range: float) -> bool:\n\treturn distance_to_target <= attack_range\n''',
    '''static func is_within_attack_range(\n\tdistance_to_target: float,\n\tattack_range: float,\n\tattack_range_tolerance: float = 0.0\n) -> bool:\n\treturn distance_to_target <= attack_range + attack_range_tolerance\n\n\nstatic func should_start_attack(distance_to_target: float, attack_range: float) -> bool:\n\treturn is_within_attack_range(distance_to_target, attack_range)\n''',
    "generic attack range helper",
)
combat = replace_once(
    combat,
    '''static func should_fire_after_windup(\n\tdistance_to_player: float,\n\tattack_range: float,\n\tattack_range_tolerance: float,\n\thas_line_of_sight: bool\n) -> bool:\n\treturn (\n\t\tdistance_to_player <= attack_range + attack_range_tolerance\n\t\tand has_line_of_sight\n\t)\n''',
    '''static func should_resolve_attack_after_windup(\n\tdistance_to_player: float,\n\tattack_range: float,\n\tattack_range_tolerance: float,\n\thas_line_of_sight: bool\n) -> bool:\n\treturn (\n\t\tis_within_attack_range(\n\t\t\tdistance_to_player,\n\t\t\tattack_range,\n\t\t\tattack_range_tolerance\n\t\t)\n\t\tand has_line_of_sight\n\t)\n\n\nstatic func should_fire_after_windup(\n\tdistance_to_player: float,\n\tattack_range: float,\n\tattack_range_tolerance: float,\n\thas_line_of_sight: bool\n) -> bool:\n\treturn should_resolve_attack_after_windup(\n\t\tdistance_to_player,\n\t\tattack_range,\n\t\tattack_range_tolerance,\n\t\thas_line_of_sight\n\t)\n''',
    "generic windup resolution helper",
)
write(combat_path, combat)

lunge_path = "scripts/actors/enemy_lunge_base.gd"
lunge = read(lunge_path)
lunge = replace_once(
    lunge,
    '''class_name VexEnemyLungeBase\nextends "res://scripts/actors/enemy_base.gd"\n''',
    '''class_name VexEnemyLungeBase\nextends "res://scripts/actors/enemy_base.gd"\n\nconst EnemyLungeRuntime = preload("res://scripts/actors/enemy_lunge_runtime.gd")\n''',
    "lunge runtime preload",
)
lunge = replace_once(
    lunge,
    '''\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\t\tif forced_distance < _forced_damage_best_distance - damage_pursuit_min_progress:\n\t\t\t\t_forced_damage_best_distance = forced_distance\n\t\t\t\t_forced_damage_stall_remaining = damage_pursuit_stall_timeout\n\t\t\telse:\n\t\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)\n''',
    '''\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)\n\t\t\tvar pursuit_progress := EnemyCombatRuntime.damage_pursuit_progress(\n\t\t\t\tforced_distance,\n\t\t\t\t_forced_damage_best_distance,\n\t\t\t\tdamage_pursuit_min_progress,\n\t\t\t\t_forced_damage_stall_remaining,\n\t\t\t\tdamage_pursuit_stall_timeout,\n\t\t\t\tdelta\n\t\t\t)\n\t\t\t_forced_damage_best_distance = float(\n\t\t\t\tpursuit_progress.get("best_distance", _forced_damage_best_distance)\n\t\t\t)\n\t\t\t_forced_damage_stall_remaining = float(\n\t\t\t\tpursuit_progress.get("stall_remaining", _forced_damage_stall_remaining)\n\t\t\t)\n''',
    "damage pursuit progress delegation",
)
lunge = replace_once(
    lunge,
    '''\t\t\t\tif (\n\t\t\t\t\t_forced_damage_stall_remaining <= 0.0\n\t\t\t\t\tand (_navigation_path.is_empty() or _navigation_path_index >= _navigation_path.size())\n\t\t\t\t):\n''',
    '''\t\t\t\tif EnemyCombatRuntime.should_abandon_damage_pursuit(\n\t\t\t\t\t_forced_damage_stall_remaining,\n\t\t\t\t\t_navigation_path.is_empty(),\n\t\t\t\t\t_navigation_path_index,\n\t\t\t\t\t_navigation_path.size()\n\t\t\t\t):\n''',
    "damage pursuit abandon delegation",
)
lunge = replace_once(
    lunge,
    '''\t\tif (\n\t\t\tcombat_role == EnemyCombatProfiles.Role.CLOSE\n\t\t\tand player_distance <= attack_range + attack_range_tolerance\n\t\t):\n''',
    '''\t\tif EnemyCombatRuntime.should_check_close_combat_visibility(\n\t\t\tcombat_role == EnemyCombatProfiles.Role.CLOSE,\n\t\t\ttrue,\n\t\t\tplayer_distance,\n\t\t\tattack_range,\n\t\t\tattack_range_tolerance\n\t\t):\n''',
    "close combat visibility delegation",
)
lunge = replace_once(
    lunge,
    '''\t\t\tif player_distance <= attack_range:\n\t\t\t\t_face_player()\n\t\t\t\t_attempt_attack()\n''',
    '''\t\t\tif EnemyCombatRuntime.should_start_attack(player_distance, attack_range):\n\t\t\t\t_face_player()\n\t\t\t\t_attempt_attack()\n''',
    "attack start delegation",
)

lunge = replace_function(
    lunge,
    "_can_handoff_damage_pursuit_to_combat",
    '''func _can_handoff_damage_pursuit_to_combat() -> bool:\n\tvar player_valid := _player != null and is_instance_valid(_player)\n\tvar player_distance := INF\n\tif player_valid:\n\t\tplayer_distance = _horizontal_distance(global_position, _player.global_position)\n\tif not EnemyCombatRuntime.can_attempt_damage_handoff(\n\t\t_forced_damage_commit_remaining,\n\t\tplayer_valid,\n\t\tplayer_distance,\n\t\tattack_range,\n\t\tattack_range_tolerance\n\t):\n\t\treturn false\n\tif not _check_line_of_sight():\n\t\treturn false\n\t_aggro = true\n\t_cached_player_visible = true\n\t_sight_check_remaining = near_sight_interval\n\t_last_seen_position = _player.global_position\n\t_last_seen_position.y = global_position.y\n\t_lost_sight_remaining = lost_sight_timeout\n\t_search_remaining = search_duration\n\treturn true\n''',
)

lunge = replace_function(
    lunge,
    "_update_attack_lunge",
    '''func _update_attack_lunge(delta: float) -> void:\n\tvar player_valid := _player != null and is_instance_valid(_player)\n\tvar player_position := _player.global_position if player_valid else Vector3.ZERO\n\tvar plan := EnemyLungeRuntime.attack_lunge_plan(\n\t\tglobal_position,\n\t\tplayer_position,\n\t\tplayer_valid,\n\t\t_attack_lunge_remaining,\n\t\t_runtime_attack_lunge_speed,\n\t\tattack_lunge_stop_distance,\n\t\tdelta\n\t)\n\t_attack_lunge_remaining = float(plan.get("remaining", 0.0))\n\tvar mode := int(plan.get("mode", EnemyLungeRuntime.MODE_BRAKE))\n\tmatch mode:\n\t\tEnemyLungeRuntime.MODE_STOP:\n\t\t\tvelocity.x = 0.0\n\t\t\tvelocity.z = 0.0\n\t\tEnemyLungeRuntime.MODE_MOVE:\n\t\t\tvar facing_direction: Vector3 = plan.get("facing_direction", Vector3.ZERO)\n\t\t\tvar desired_velocity: Vector3 = plan.get("desired_velocity", Vector3.ZERO)\n\t\t\t_facing_direction = facing_direction\n\t\t\trotation.y = atan2(-facing_direction.x, -facing_direction.z)\n\t\t\tvelocity.x = move_toward(\n\t\t\t\tvelocity.x,\n\t\t\t\tdesired_velocity.x,\n\t\t\t\tdelta * attack_lunge_acceleration\n\t\t\t)\n\t\t\tvelocity.z = move_toward(\n\t\t\t\tvelocity.z,\n\t\t\t\tdesired_velocity.z,\n\t\t\t\tdelta * attack_lunge_acceleration\n\t\t\t)\n\t\t_:\n\t\t\tvelocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)\n\t\t\tvelocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)\n''',
)

lunge = replace_function(
    lunge,
    "_attempt_attack",
    '''func _attempt_attack() -> void:\n\tif _attack_locked or _dead:\n\t\treturn\n\tif _player == null or not is_instance_valid(_player):\n\t\treturn\n\tvar player_distance := _horizontal_distance(global_position, _player.global_position)\n\tif not EnemyCombatRuntime.should_start_attack(player_distance, attack_range):\n\t\treturn\n\tif not _check_line_of_sight():\n\t\treturn\n\n\t_attack_generation += 1\n\tvar attack_generation := _attack_generation\n\t_attack_locked = true\n\t_attack_lunge_remaining = EnemyLungeRuntime.initial_attack_lunge_duration(\n\t\tattack_lunge_duration,\n\t\t_runtime_attack_windup\n\t)\n\t_play_animation(&"attack")\n\tif attack_audio.stream != null:\n\t\tattack_audio.play()\n\n\t# 8 FPS'lik 4 kare saldırının 3. karesine yaklaşırken darbe uygulanır.\n\tawait get_tree().create_timer(_runtime_attack_windup).timeout\n\tif not is_inside_tree() or _dead or attack_generation != _attack_generation:\n\t\treturn\n\t_attack_lunge_remaining = 0.0\n\tvelocity.x = 0.0\n\tvelocity.z = 0.0\n\n\tif _player != null and is_instance_valid(_player):\n\t\tplayer_distance = _horizontal_distance(global_position, _player.global_position)\n\t\tif EnemyCombatRuntime.is_within_attack_range(\n\t\t\tplayer_distance,\n\t\t\tattack_range,\n\t\t\tattack_range_tolerance\n\t\t):\n\t\t\tvar has_line_of_sight := _check_line_of_sight()\n\t\t\tif (\n\t\t\t\tEnemyCombatRuntime.should_resolve_attack_after_windup(\n\t\t\t\t\tplayer_distance,\n\t\t\t\t\tattack_range,\n\t\t\t\t\tattack_range_tolerance,\n\t\t\t\t\thas_line_of_sight\n\t\t\t\t)\n\t\t\t\tand _player.has_method("take_damage")\n\t\t\t):\n\t\t\t\t_player.call("take_damage", _runtime_attack_damage, global_position, self)\n\n\t# Darbe penceresi bittiğinde saldırı karesini cooldown boyunca dondurma.\n\t# Lunge ailesi toparlanma sırasında yerinde beklediği için nötr idle pozu kullanır.\n\t_play_animation(&"idle")\n\n\tvar remaining := EnemyCombatRuntime.remaining_attack_cooldown(\n\t\t_runtime_attack_cooldown,\n\t\t_runtime_attack_windup\n\t)\n\tawait get_tree().create_timer(remaining).timeout\n\tif not is_inside_tree() or _dead or attack_generation != _attack_generation:\n\t\treturn\n\t_attack_locked = false\n\n\tif _player != null and is_instance_valid(_player):\n\t\tplayer_distance = _horizontal_distance(global_position, _player.global_position)\n\t\tif EnemyCombatRuntime.should_start_attack(player_distance, attack_range):\n\t\t\t_face_player()\n\t\t\t_play_animation(&"idle")\n\t\t\treturn\n\t_play_animation(&"walk")\n''',
)
write(lunge_path, lunge)

audit_path = "tests/enemy_attack_handoff_audit.py"
audit = read(audit_path)
audit = replace_once(
    audit,
    '''assert "EnemyCombatRuntime.can_attempt_damage_handoff(" in ravager\nassert "EnemyCombatRuntime.should_check_close_combat_visibility(" in ravager\nassert "attack_range + attack_range_tolerance" in ravager\nassert "attack_range + attack_range_tolerance" in combat\nassert "attack_range + attack_range_tolerance" in red\n''',
    '''for source in (ravager, red):\n    assert "EnemyCombatRuntime.can_attempt_damage_handoff(" in source\n    assert "EnemyCombatRuntime.should_check_close_combat_visibility(" in source\nassert "attack_range + attack_range_tolerance" in combat\n''',
    "handoff audit runtime ownership",
)
write(audit_path, audit)

print("enemy lunge runtime integration patch applied")
