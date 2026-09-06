class_name VexEnemyLungePerformanceBase
extends "res://scripts/actors/enemy_lunge_base.gd"

const EnemyPerformanceRuntime = preload("res://scripts/actors/enemy_performance_runtime.gd")

var _perf_los_frame := -1000000
var _perf_los_result := false
var _perf_observer_frame := -1000000
var _perf_observer_behind := false


func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		_perf_los_result = false
		return false

	var physics_frame := Engine.get_physics_frames()
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	var cache_frames := 2
	if player_distance > EnemyPerformanceRuntime.MID_DISTANCE:
		cache_frames = 4
	elif player_distance > EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE:
		cache_frames = 3
	if physics_frame - _perf_los_frame < cache_frames:
		return _perf_los_result

	var near_priority := player_distance <= EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE
	if not EnemyPerformanceRuntime.try_claim_sight(near_priority):
		return _perf_los_result

	_perf_los_frame = physics_frame
	_perf_los_result = super._check_line_of_sight()
	return _perf_los_result


func _chase_position(delta: float, target_position: Vector3, use_chase_speed: bool = true) -> void:
	var resolved_target := _resolve_enemy_door_step(target_position)
	resolved_target.y = global_position.y
	_movement_target = resolved_target

	var target_changed := (
		not _has_navigation_target
		or _horizontal_distance(_navigation_target, resolved_target) > path_target_change_distance
	)
	if _navigation_refresh_remaining <= 0.0 or target_changed:
		var near_priority := _navigation_path.is_empty()
		if _player != null and is_instance_valid(_player):
			near_priority = (
				near_priority
				or EnemyPerformanceRuntime.is_near_player(self, _player)
			)
		if EnemyPerformanceRuntime.try_claim_path(near_priority):
			_navigation_path = EnemyNavigationRuntime.build_shortest_path(
				self,
				resolved_target,
				navigation_collision_mask,
				floor_collision_mask,
				navigation_clearance,
				floor_snap_ray_start_height,
				floor_snap_ray_extra_depth,
				EnemyPerformanceRuntime.effective_runtime_grid_step(runtime_grid_step),
				EnemyPerformanceRuntime.effective_runtime_grid_max_nodes(runtime_grid_max_nodes),
				EnemyPerformanceRuntime.effective_runtime_grid_search_margin(runtime_grid_search_margin)
			)
			_navigation_path_index = 1 if _navigation_path.size() > 1 else 0
			_navigation_target = resolved_target
			_has_navigation_target = true
			_navigation_refresh_remaining = path_refresh_interval
		else:
			_navigation_refresh_remaining = EnemyPerformanceRuntime.PATH_RETRY_DELAY

	while (
		_navigation_path_index < _navigation_path.size()
		and EnemyNavigationRuntime.has_reached_walkable_target(
			self,
			_navigation_path[_navigation_path_index],
			investigation_reach_distance,
			navigation_collision_mask,
			floor_collision_mask,
			navigation_clearance,
			floor_snap_ray_start_height,
			floor_snap_ray_extra_depth
		)
	):
		_navigation_path_index += 1

	var movement_point := resolved_target
	if _navigation_path_index < _navigation_path.size():
		movement_point = _navigation_path[_navigation_path_index]

	var direction: Vector3 = movement_point - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		_play_animation(&"idle")
		return
	direction = direction.normalized()

	if _detour_remaining > 0.0 and _detour_direction.length_squared() > 0.001:
		direction = _detour_direction

	_facing_direction = direction
	var desired_speed := _runtime_chase_speed if use_chase_speed else _runtime_move_speed
	velocity.x = move_toward(
		velocity.x,
		direction.x * desired_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * desired_speed,
		delta * movement_acceleration
	)
	rotation.y = atan2(-direction.x, -direction.z)
	_play_animation(&"walk")


func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:
	return EnemyPerformanceRuntime.resolve_enemy_door_step_cached(
		self,
		target_position,
		navigation_clearance,
		investigation_reach_distance
	)


func _is_observer_behind_enemy(back_view_threshold_value: float) -> bool:
	var physics_frame := Engine.get_physics_frames()
	var cache_frames := 4
	if _player != null and is_instance_valid(_player):
		var player_distance := _horizontal_distance(global_position, _player.global_position)
		cache_frames = 2 if player_distance <= EnemyPerformanceRuntime.NEAR_PRIORITY_DISTANCE else 6
	if physics_frame - _perf_observer_frame < cache_frames:
		return _perf_observer_behind
	_perf_observer_frame = physics_frame
	_perf_observer_behind = super._is_observer_behind_enemy(back_view_threshold_value)
	return _perf_observer_behind


func _attack_playback_scale_for_runtime_windup() -> float:
	if animated_sprite == null or not _has_animation(&"attack"):
		return 1.0
	var frames := animated_sprite.sprite_frames
	if frames == null or frames.get_frame_count(&"attack") < 3:
		return 1.0
	var animation_fps := maxf(frames.get_animation_speed(&"attack"), 0.001)
	var release_units := (
		frames.get_frame_duration(&"attack", 0)
		+ frames.get_frame_duration(&"attack", 1)
		+ frames.get_frame_duration(&"attack", 2) * 0.5
	)
	var authored_release_time := release_units / animation_fps
	return maxf(authored_release_time / maxf(_runtime_attack_windup, 0.001), 0.01)


func _play_animation(animation_name: StringName) -> void:
	if animation_name != &"attack":
		super._play_animation(animation_name)
		return
	if not _has_animation(&"attack"):
		return
	if animated_sprite.animation == &"attack" and animated_sprite.is_playing():
		return
	animated_sprite.play(&"attack", _attack_playback_scale_for_runtime_windup())
	_apply_frame_ground_offset()


func _place_corpse_visual_on_floor() -> void:
	if (
		animated_sprite != null
		and animated_sprite.animation == &"death"
		and not death_frame_y_offsets.is_empty()
	):
		var frame_index := mini(animated_sprite.frame, death_frame_y_offsets.size() - 1)
		animated_sprite.position.y = _visual_base_y + death_frame_y_offsets[frame_index]
		return
	super._place_corpse_visual_on_floor()
