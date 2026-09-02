class_name VexEnemyCombatRuntime
extends RefCounted


static func resolve_attack_target(
	enemy_position: Vector3,
	player_visible: bool,
	player_valid: bool,
	player_position: Vector3,
	has_last_seen_position: bool,
	last_seen_position: Vector3
) -> Dictionary:
	if player_visible and player_valid:
		return {"valid": true, "position": player_position}
	if has_last_seen_position:
		return {"valid": true, "position": last_seen_position}
	return {"valid": false, "position": enemy_position}


static func should_start_attack(distance_to_target: float, attack_range: float) -> bool:
	return distance_to_target <= attack_range


static func should_fire_after_windup(
	distance_to_player: float,
	attack_range: float,
	attack_range_tolerance: float,
	has_line_of_sight: bool
) -> bool:
	return (
		distance_to_player <= attack_range + attack_range_tolerance
		and has_line_of_sight
	)


static func remaining_attack_cooldown(
	runtime_attack_cooldown: float,
	runtime_attack_windup: float
) -> float:
	return maxf(0.0, runtime_attack_cooldown - runtime_attack_windup)


static func attack_recovery_plan(
	enemy_position: Vector3,
	target_position: Vector3,
	is_close_role: bool,
	scene_move_speed: float,
	runtime_move_speed: float,
	runtime_chase_speed: float,
	attack_approach_speed: float,
	attack_strafe_speed: float,
	attack_strafe_direction: float,
	attack_preferred_distance: float,
	attack_minimum_distance: float,
	attack_recovery_strafe_scale: float,
	attack_retreat_speed_scale: float,
	attack_approach_distance_margin: float,
	attack_approach_min_speed_scale: float
) -> Dictionary:
	var direction_to_target := target_position - enemy_position
	direction_to_target.y = 0.0
	var distance_to_target := direction_to_target.length()
	if distance_to_target <= 0.001:
		return {
			"valid": false,
			"facing_direction": Vector3.ZERO,
			"desired_velocity": Vector3.ZERO,
		}

	var forward_direction := direction_to_target / distance_to_target
	var right_direction := forward_direction.cross(Vector3.UP).normalized()
	var preferred_distance := attack_preferred_distance
	var minimum_distance := minf(attack_minimum_distance, preferred_distance)
	var speed_scale := runtime_move_speed / maxf(scene_move_speed, 0.001)
	var desired_velocity := Vector3.ZERO

	if attack_recovery_strafe_scale > 0.0 and attack_strafe_speed > 0.0:
		desired_velocity += (
			right_direction
			* attack_strafe_speed
			* attack_strafe_direction
			* speed_scale
			* attack_recovery_strafe_scale
		)

	if is_close_role:
		if distance_to_target > preferred_distance:
			desired_velocity = forward_direction * runtime_chase_speed
	elif distance_to_target > preferred_distance + attack_approach_distance_margin:
		var approach_speed := maxf(
			attack_approach_speed * speed_scale,
			runtime_move_speed * attack_approach_min_speed_scale
		)
		desired_velocity += forward_direction * approach_speed
	elif distance_to_target < minimum_distance:
		desired_velocity -= (
			forward_direction
			* runtime_move_speed
			* attack_retreat_speed_scale
		)

	var maximum_speed := runtime_chase_speed if is_close_role else runtime_move_speed
	if desired_velocity.length() > maximum_speed:
		desired_velocity = desired_velocity.normalized() * maximum_speed

	return {
		"valid": true,
		"facing_direction": forward_direction,
		"desired_velocity": desired_velocity,
	}


static func calculate_intercept_time(
	projectile_position: Vector3,
	target_position: Vector3,
	target_velocity: Vector3,
	projectile_speed: float
) -> float:
	var displacement := target_position - projectile_position
	var fallback_time := displacement.length() / maxf(projectile_speed, 0.1)
	var quadratic_a := target_velocity.length_squared() - projectile_speed * projectile_speed
	var quadratic_b := 2.0 * displacement.dot(target_velocity)
	var quadratic_c := displacement.length_squared()
	if quadratic_c <= 0.0001:
		return 0.0
	if absf(quadratic_a) <= 0.0001:
		if absf(quadratic_b) <= 0.0001:
			return fallback_time
		var linear_time := -quadratic_c / quadratic_b
		return linear_time if linear_time > 0.0 else fallback_time

	var discriminant := (
		quadratic_b * quadratic_b
		- 4.0 * quadratic_a * quadratic_c
	)
	if discriminant < 0.0:
		return fallback_time
	var discriminant_root := sqrt(discriminant)
	var denominator := 2.0 * quadratic_a
	var first_time := (-quadratic_b - discriminant_root) / denominator
	var second_time := (-quadratic_b + discriminant_root) / denominator
	var intercept_time := -1.0
	if first_time > 0.0:
		intercept_time = first_time
	if second_time > 0.0 and (intercept_time < 0.0 or second_time < intercept_time):
		intercept_time = second_time
	return intercept_time if intercept_time > 0.0 else fallback_time


static func damage_source_approach_position(
	enemy_position: Vector3,
	source_position: Vector3,
	damage_approach_offset: float,
	damage_approach_distance_ratio: float
) -> Vector3:
	var result := source_position
	result.y = enemy_position.y
	var toward_enemy := enemy_position - result
	toward_enemy.y = 0.0
	var distance := toward_enemy.length()
	if distance > 0.001:
		var offset := minf(
			damage_approach_offset,
			distance * damage_approach_distance_ratio
		)
		result += (toward_enemy / distance) * offset
	return result


static func damage_pursuit_progress(
	current_distance: float,
	best_distance: float,
	minimum_progress: float,
	stall_remaining: float,
	stall_timeout: float,
	delta: float
) -> Dictionary:
	if current_distance < best_distance - minimum_progress:
		return {
			"best_distance": current_distance,
			"stall_remaining": stall_timeout,
		}
	return {
		"best_distance": best_distance,
		"stall_remaining": maxf(0.0, stall_remaining - delta),
	}


static func should_abandon_damage_pursuit(
	stall_remaining: float,
	path_is_empty: bool,
	path_index: int,
	path_size: int
) -> bool:
	return stall_remaining <= 0.0 and (path_is_empty or path_index >= path_size)


static func can_attempt_damage_handoff(
	forced_damage_commit_remaining: float,
	player_valid: bool,
	player_distance: float,
	attack_range: float,
	attack_range_tolerance: float
) -> bool:
	return (
		forced_damage_commit_remaining <= 0.0
		and player_valid
		and player_distance <= attack_range + attack_range_tolerance
	)


static func should_check_close_combat_visibility(
	is_close_role: bool,
	player_valid: bool,
	player_distance: float,
	attack_range: float,
	attack_range_tolerance: float
) -> bool:
	return (
		is_close_role
		and player_valid
		and player_distance <= attack_range + attack_range_tolerance
	)
