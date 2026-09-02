from pathlib import Path


def replace_once(text: str, old: str, new: str, label: str) -> str:
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{label}: expected exactly one match, found {count}")
    return text.replace(old, new, 1)


def replace_function(text: str, name: str, replacement: str) -> str:
    marker = f"func {name}("
    start = text.find(marker)
    if start < 0:
        raise SystemExit(f"Missing function: {name}")
    next_func = text.find("\n\nfunc ", start + len(marker))
    end = len(text) if next_func < 0 else next_func + 2
    return text[:start] + replacement.rstrip() + "\n\n" + text[end:]


base_path = Path("scripts/actors/enemy_base.gd")
base = base_path.read_text(encoding="utf-8")
base = replace_once(
    base,
    'const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")\n',
    'const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")\n'
    'const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")\n',
    "enemy base combat preload",
)
base_path.write_text(base, encoding="utf-8")


path = Path("scripts/actors/enemy_combatant_base.gd")
text = path.read_text(encoding="utf-8")

text = replace_once(
    text,
    '''\t\tvar attack_target := global_position
\t\tvar has_attack_target := false
\t\tif _player_visible and _player != null and is_instance_valid(_player):
\t\t\tattack_target = _player.global_position
\t\t\thas_attack_target = true
\t\telif _has_last_seen_position:
\t\t\tattack_target = _last_seen_position
\t\t\thas_attack_target = true
''',
    '''\t\tvar player_valid := _player != null and is_instance_valid(_player)
\t\tvar player_position := _player.global_position if player_valid else Vector3.ZERO
\t\tvar attack_target_result := EnemyCombatRuntime.resolve_attack_target(
\t\t\tglobal_position,
\t\t\t_player_visible,
\t\t\tplayer_valid,
\t\t\tplayer_position,
\t\t\t_has_last_seen_position,
\t\t\t_last_seen_position
\t\t)
\t\tvar has_attack_target := bool(attack_target_result.get("valid", false))
\t\tvar attack_target: Vector3 = attack_target_result.get("position", global_position)
''',
    "locked attack target selection",
)

text = replace_once(
    text,
    '''\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)
\t\t\tif forced_distance < _forced_damage_best_distance - damage_pursuit_min_progress:
\t\t\t\t_forced_damage_best_distance = forced_distance
\t\t\t\t_forced_damage_stall_remaining = damage_pursuit_stall_timeout
\t\t\telse:
\t\t\t\t_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
''',
    '''\t\t\tvar forced_distance := _horizontal_distance(global_position, _forced_damage_target)
\t\t\tvar pursuit_progress := EnemyCombatRuntime.damage_pursuit_progress(
\t\t\t\tforced_distance,
\t\t\t\t_forced_damage_best_distance,
\t\t\t\tdamage_pursuit_min_progress,
\t\t\t\t_forced_damage_stall_remaining,
\t\t\t\tdamage_pursuit_stall_timeout,
\t\t\t\tdelta
\t\t\t)
\t\t\t_forced_damage_best_distance = float(
\t\t\t\tpursuit_progress.get("best_distance", _forced_damage_best_distance)
\t\t\t)
\t\t\t_forced_damage_stall_remaining = float(
\t\t\t\tpursuit_progress.get("stall_remaining", _forced_damage_stall_remaining)
\t\t\t)
''',
    "damage pursuit progress",
)

text = replace_once(
    text,
    '''\t\t\tif (
\t\t\t\t_forced_damage_stall_remaining <= 0.0
\t\t\t\tand (_current_path.is_empty() or _path_index >= _current_path.size())
\t\t\t):
''',
    '''\t\t\tif EnemyCombatRuntime.should_abandon_damage_pursuit(
\t\t\t\t_forced_damage_stall_remaining,
\t\t\t\t_current_path.is_empty(),
\t\t\t\t_path_index,
\t\t\t\t_current_path.size()
\t\t\t):
''',
    "damage pursuit abandon",
)

text = replace_once(
    text,
    '''\t\tvar distance_to_player := _horizontal_distance(global_position, _last_seen_position)
\t\tif distance_to_player <= attack_range:
''',
    '''\t\tvar distance_to_player := _horizontal_distance(global_position, _last_seen_position)
\t\tif EnemyCombatRuntime.should_start_attack(distance_to_player, attack_range):
''',
    "normal attack range decision",
)

text = replace_function(
    text,
    "_refresh_close_combat_visibility",
    '''func _refresh_close_combat_visibility() -> void:
\tvar player_valid := _player != null and is_instance_valid(_player)
\tvar player_distance := INF
\tif player_valid:
\t\tplayer_distance = _horizontal_distance(global_position, _player.global_position)
\tif not EnemyCombatRuntime.should_check_close_combat_visibility(
\t\tcombat_role == EnemyCombatProfiles.Role.CLOSE,
\t\tplayer_valid,
\t\tplayer_distance,
\t\tattack_range,
\t\tattack_range_tolerance
\t):
\t\treturn
\tif not _check_line_of_sight():
\t\treturn
\t_player_visible = true
\t_alerted = true
\t_seconds_without_sight = 0.0
\t_last_seen_position = _player.global_position
\t_last_seen_position.y = global_position.y
\t_has_last_seen_position = true''',
)

text = replace_function(
    text,
    "_can_handoff_damage_pursuit_to_combat",
    '''func _can_handoff_damage_pursuit_to_combat() -> bool:
\tvar player_valid := _player != null and is_instance_valid(_player)
\tvar player_distance := INF
\tif player_valid:
\t\tplayer_distance = _horizontal_distance(global_position, _player.global_position)
\tif not EnemyCombatRuntime.can_attempt_damage_handoff(
\t\t_forced_damage_commit_remaining,
\t\tplayer_valid,
\t\tplayer_distance,
\t\tattack_range,
\t\tattack_range_tolerance
\t):
\t\treturn false
\tif not _check_line_of_sight():
\t\treturn false
\t_player_visible = true
\t_alerted = true
\t_seconds_without_sight = 0.0
\t_last_seen_position = _player.global_position
\t_last_seen_position.y = global_position.y
\t_has_last_seen_position = true
\treturn true''',
)

text = replace_function(
    text,
    "_damage_source_approach_position",
    '''func _damage_source_approach_position(source_position: Vector3) -> Vector3:
\treturn EnemyCombatRuntime.damage_source_approach_position(
\t\tglobal_position,
\t\tsource_position,
\t\tdamage_approach_offset,
\t\tdamage_approach_distance_ratio
\t)''',
)

text = replace_function(
    text,
    "_move_during_attack_recovery",
    '''func _move_during_attack_recovery(target: Vector3, delta: float) -> void:
\tvar plan := EnemyCombatRuntime.attack_recovery_plan(
\t\tglobal_position,
\t\ttarget,
\t\tcombat_role == EnemyCombatProfiles.Role.CLOSE,
\t\tmove_speed,
\t\t_runtime_move_speed,
\t\t_runtime_chase_speed,
\t\tattack_approach_speed,
\t\tattack_strafe_speed,
\t\t_attack_strafe_direction,
\t\tattack_preferred_distance,
\t\tattack_minimum_distance,
\t\tattack_recovery_strafe_scale,
\t\tattack_retreat_speed_scale,
\t\tattack_approach_distance_margin,
\t\tattack_approach_min_speed_scale
\t)
\tif not bool(plan.get("valid", false)):
\t\t_stop_horizontal_motion()
\t\treturn

\tvar forward_direction: Vector3 = plan.get("facing_direction", Vector3.ZERO)
\tvar desired_velocity: Vector3 = plan.get("desired_velocity", Vector3.ZERO)
\t_facing_direction = forward_direction
\trotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
\tif desired_velocity.length_squared() <= 0.001:
\t\t_stop_horizontal_motion()
\t\treturn

\tvelocity.x = move_toward(velocity.x, desired_velocity.x, delta * movement_acceleration)
\tvelocity.z = move_toward(velocity.z, desired_velocity.z, delta * movement_acceleration)
\t_play_directional_animation(&"walk", &"walk_back")''',
)

text = replace_function(
    text,
    "_attempt_attack",
    '''func _attempt_attack() -> void:
\tif _attack_locked:
\t\treturn
\tvar combat_generation := _combat_interrupt_generation
\t_attack_locked = true
\t_attack_windup_active = true
\t_attack_strafe_direction *= -1.0
\tif _has_animation(&"attack"):
\t\tanimated_sprite.play(&"attack")
\t\t_apply_frame_ground_offset()
\tif attack_audio.stream != null:
\t\tattack_audio.play()

\tawait get_tree().create_timer(_runtime_attack_windup).timeout
\tif not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
\t\treturn
\tif _player != null and is_instance_valid(_player):
\t\tvar player_distance := _horizontal_distance(global_position, _player.global_position)
\t\tif player_distance <= attack_range + attack_range_tolerance:
\t\t\tvar has_line_of_sight := _check_line_of_sight()
\t\t\tif EnemyCombatRuntime.should_fire_after_windup(
\t\t\t\tplayer_distance,
\t\t\t\tattack_range,
\t\t\t\tattack_range_tolerance,
\t\t\t\thas_line_of_sight
\t\t\t):
\t\t\t\t_fire_projectile()
\t_attack_windup_active = false
\tif attack_approach_speed > 0.0 or attack_strafe_speed > 0.0:
\t\t_play_directional_animation(&"walk", &"walk_back")
\telse:
\t\t_play_directional_animation(&"idle", &"idle_back")

\tvar remaining := EnemyCombatRuntime.remaining_attack_cooldown(
\t\t_runtime_attack_cooldown,
\t\t_runtime_attack_windup
\t)
\tawait get_tree().create_timer(remaining).timeout
\tif not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
\t\treturn
\t_attack_locked = false
\t_attack_windup_active = false
\t_play_directional_animation(&"idle", &"idle_back")''',
)

text = replace_function(
    text,
    "_calculate_intercept_time",
    '''func _calculate_intercept_time(
\tprojectile_position: Vector3,
\ttarget_position: Vector3,
\ttarget_velocity: Vector3,
\tprojectile_speed: float
) -> float:
\treturn EnemyCombatRuntime.calculate_intercept_time(
\t\tprojectile_position,
\t\ttarget_position,
\t\ttarget_velocity,
\t\tprojectile_speed
\t)''',
)

path.write_text(text, encoding="utf-8")


recovery_path = Path("tests/enemy_attack_recovery_animation_audit.py")
recovery = recovery_path.read_text(encoding="utf-8")
recovery = replace_once(
    recovery,
    '''combatant = function_block(read("scripts/actors/enemy_combatant_base.gd"), "_attempt_attack")
assert_order(
    combatant,
    "_fire_projectile()",
    '_play_directional_animation(&"idle", &"idle_back")',
    "var remaining := maxf(",
)
''',
    '''combatant = function_block(read("scripts/actors/enemy_combatant_base.gd"), "_attempt_attack")
assert_order(
    combatant,
    "_fire_projectile()",
    '_play_directional_animation(&"idle", &"idle_back")',
    "var remaining := EnemyCombatRuntime.remaining_attack_cooldown(",
)
''',
    "combatant recovery audit",
)
recovery_path.write_text(recovery, encoding="utf-8")


handoff_path = Path("tests/enemy_attack_handoff_audit.py")
handoff_path.write_text('''from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
profile = (ROOT / "scripts/actors/enemy_combat_profiles.gd").read_text(encoding="utf-8")
ravager = (ROOT / "scripts/actors/enemy_combatant_base.gd").read_text(encoding="utf-8")
combat = (ROOT / "scripts/actors/enemy_combat_runtime.gd").read_text(encoding="utf-8")
red = (ROOT / "scripts/actors/enemy_lunge_base.gd").read_text(encoding="utf-8")

assert "func damage_pursuit_commit_time" not in profile
for source in (ravager, red):
    assert "var damage_pursuit_commit_time" in source
    assert "_forced_damage_commit_remaining" in source
    assert "_forced_damage_commit_remaining = damage_pursuit_commit_time" in source
    assert "_can_handoff_damage_pursuit_to_combat" in source
    assert "_check_line_of_sight()" in source

assert "EnemyCombatRuntime.can_attempt_damage_handoff(" in ravager
assert "EnemyCombatRuntime.should_check_close_combat_visibility(" in ravager
assert "attack_range + attack_range_tolerance" in ravager
assert "attack_range + attack_range_tolerance" in combat
assert "attack_range + attack_range_tolerance" in red
assert "_refresh_close_combat_visibility()" in ravager
assert "combat_role == EnemyCombatProfiles.Role.CLOSE" in red
# Başlamış saldırı hasar kaynağına yönelme davranışından önce çözülür.
assert ravager.index("if _attack_locked:") < ravager.index("if _has_forced_damage_target:")
assert red.index("if _attack_locked:") < red.index("if _has_forced_damage_target:")

ravager_damage = ravager[
    ravager.index("func take_damage("):ravager.index("func _on_noise_emitted(")
]
red_damage = red[
    red.index("func take_damage("):red.index("func _collision_floor_local_y(")
]
assert "_combat_interrupt_generation += 1" not in ravager_damage
assert "_attack_locked = false" not in ravager_damage
assert "_attack_generation += 1" not in red_damage
assert "_attack_locked = false" not in red_damage
assert "_attack_lunge_remaining = 0.0" not in red_damage

print("enemy attack handoff audit passed")
''', encoding="utf-8")


workflow_path = Path(".github/workflows/validate.yml")
workflow = workflow_path.read_text(encoding="utf-8")
anchor = '''      - name: Run enemy navigation runtime regression
        shell: bash
        run: |
          set -o pipefail
          log="$RUNNER_TEMP/enemy-navigation-runtime.log"
          godot --headless --path . tests/enemy_navigation_runtime_test.tscn 2>&1 | tee "$log"
          if grep -E 'ERROR:|invalid UID' "$log"; then
            echo "::error::Enemy navigation runtime log contains an error or invalid UID"
            exit 1
          fi
'''
addition = anchor + '''      - name: Run enemy combat runtime regression
        shell: bash
        run: |
          set -o pipefail
          log="$RUNNER_TEMP/enemy-combat-runtime.log"
          godot --headless --path . tests/enemy_combat_runtime_test.tscn 2>&1 | tee "$log"
          if grep -E 'ERROR:|invalid UID' "$log"; then
            echo "::error::Enemy combat runtime log contains an error or invalid UID"
            exit 1
          fi
'''
workflow = replace_once(workflow, anchor, addition, "validate combat runtime step")
workflow_path.write_text(workflow, encoding="utf-8")
