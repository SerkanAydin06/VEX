class_name VexEnemyCombatantPerformanceBase
extends "res://scripts/actors/enemy_combatant_base.gd"

const EnemyPerformanceRuntime = preload("res://scripts/actors/enemy_performance_runtime.gd")
const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")

var _perf_los_frame := -1000000
var _perf_los_result := false
var _perf_los_visibility_ratio := 0.0
var _perf_observer_frame := -1000000
var _perf_observer_behind := false
var _perf_last_runtime_path := PackedVector3Array()
var _perf_last_runtime_target := Vector3.ZERO
var _perf_has_runtime_target := false


func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		_last_visibility_ratio = 0.0
		_perf_los_result = false
		_perf_los_visibility_ratio = 0.0
		return false

	var physics_frame := Engine.get_physics_frames()
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	var cache_frames := 2
	if player_distance > EnemyPerformanceRuntime.MID_DISTANCE:
		cache_frames = 4
	elif player_distance > EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE:
		cache_frames = 3
	if physics_frame - _perf_los_frame < cache_frames:
		_last_visibility_ratio = _perf_los_visibility_ratio
		return _perf_los_result

	var near_priority := player_distance <= EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE
	if not EnemyPerformanceRuntime.try_claim_sight(near_priority):
		_last_visibility_ratio = _perf_los_visibility_ratio
		return _perf_los_result

	_perf_los_frame = physics_frame
	_perf_los_result = super._check_line_of_sight()
	_perf_los_visibility_ratio = _last_visibility_ratio
	return _perf_los_result


func _build_runtime_shortest_path(destination: Vector3) -> PackedVector3Array:
	var near_priority := _current_path.is_empty()
	if _player != null and is_instance_valid(_player):
		near_priority = (
			near_priority
			or EnemyPerformanceRuntime.is_near_player(self, _player)
		)
	if not EnemyPerformanceRuntime.try_claim_path(near_priority):
		if (
			_perf_has_runtime_target
			and not _perf_last_runtime_path.is_empty()
			and _horizontal_distance(_perf_last_runtime_target, destination)
			<= path_target_change_distance * 3.0
		):
			return _perf_last_runtime_path.duplicate()
		return PackedVector3Array()

	var path := super._build_runtime_shortest_path(destination)
	if not path.is_empty():
		_perf_last_runtime_path = path.duplicate()
		_perf_last_runtime_target = destination
		_perf_has_runtime_target = true
	return path


func _reposition_for_clear_shot(delta: float) -> void:
	var needs_cover_scan := (
		not _has_ranged_reposition_target
		or _ranged_reposition_remaining <= 0.0
		or (
			_has_ranged_reposition_target
			and _horizontal_distance(global_position, _ranged_reposition_target)
			<= waypoint_reach_distance
		)
	)
	if needs_cover_scan:
		var near_priority := (
			_player != null
			and is_instance_valid(_player)
			and EnemyPerformanceRuntime.is_near_player(self, _player)
		)
		if not EnemyPerformanceRuntime.try_claim_cover(near_priority):
			_ranged_reposition_remaining = maxf(
				_ranged_reposition_remaining,
				EnemyPerformanceRuntime.COVER_RETRY_DELAY
			)
			if _has_ranged_reposition_target:
				_navigate_to(_ranged_reposition_target, delta)
			elif _has_last_seen_position:
				_navigate_to(_last_seen_position, delta)
			else:
				_stop_horizontal_motion()
			return
	super._reposition_for_clear_shot(delta)


func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:
	return EnemyPerformanceRuntime.resolve_enemy_door_step_cached(
		self,
		target_position,
		navigation_clearance,
		waypoint_reach_distance
	)


func _is_observer_behind_enemy() -> bool:
	var physics_frame := Engine.get_physics_frames()
	var cache_frames := 4
	if _player != null and is_instance_valid(_player):
		var player_distance := _horizontal_distance(global_position, _player.global_position)
		cache_frames = 2 if player_distance <= EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE else 6
	if physics_frame - _perf_observer_frame < cache_frames:
		return _perf_observer_behind
	_perf_observer_frame = physics_frame
	_perf_observer_behind = super._is_observer_behind_enemy()
	return _perf_observer_behind


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		return
	var projectile := EnemyProjectilePool.acquire(
		projectile_scene,
		projectile_parent
	) as Node3D
	if projectile == null:
		return

	var spawn_right := _facing_direction.cross(Vector3.UP)
	if spawn_right.length_squared() <= 0.001:
		spawn_right = Vector3.RIGHT
	else:
		spawn_right = spawn_right.normalized()
	var spawn_forward := _facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * projectile_spawn_height
		+ spawn_right * projectile_spawn_side_offset
		+ spawn_forward * projectile_spawn_forward_offset
	)
	var target_position := (
		_player.global_position
		+ Vector3.UP * projectile_target_height
	)
	var projectile_speed := maxf(float(projectile.get("speed")), 0.1)
	var target_velocity := Vector3.ZERO
	if _player is CharacterBody3D and projectile_lead_factor > 0.0:
		target_velocity = (_player as CharacterBody3D).velocity
		target_velocity.y = 0.0
	var travel_time := minf(
		_calculate_intercept_time(
			projectile.global_position,
			target_position,
			target_velocity,
			projectile_speed
		),
		projectile_max_lead_time
	)
	if projectile_lead_factor > 0.0:
		target_position += target_velocity * travel_time * projectile_lead_factor
	var shot_direction := (target_position - projectile.global_position).normalized()
	projectile.call("launch", shot_direction, self, _runtime_attack_damage)
