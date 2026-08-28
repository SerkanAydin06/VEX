class_name VexCrucibleWarden
extends "res://scripts/actors/ravager.gd"

@export_category("09 - Ground Slam")
@export var ground_slam_scene: PackedScene
@export_range(1.0, 10.0, 0.1) var ground_slam_trigger_range := 5.2
@export_range(1.0, 10.0, 0.1) var ground_slam_radius := 4.6
@export_range(1, 200, 1) var ground_slam_damage := 42
@export_range(0.2, 10.0, 0.05) var ground_slam_cooldown := 2.7
@export_range(0.05, 2.0, 0.01) var ground_slam_windup := 0.58
@export_range(0.0, 3.0, 0.05) var ground_slam_recovery := 0.85
@export_range(1.0, 16.0, 0.5) var ground_slam_shake_radius := 8.5
@export_range(0.0, 0.3, 0.005) var ground_slam_shake_strength := 0.075
@export_range(0.0, 1.5, 0.05) var ground_slam_shake_duration := 0.42
@export_flags_3d_physics var ground_effect_collision_mask := 1
@export_range(0.1, 4.0, 0.1) var ground_probe_height := 1.0
@export_range(0.5, 6.0, 0.1) var ground_probe_depth := 2.8
@export_range(0.0, 0.2, 0.01) var ground_effect_surface_offset := 0.035

@export_category("10 - Heatwave")
@export var heatwave_projectile_scene: PackedScene
@export_range(0.5, 5.0, 0.05) var heatwave_trigger_range := 1.65
@export_range(4, 24, 1) var heatwave_projectile_count := 12
@export_range(1, 100, 1) var heatwave_damage := 18
@export_range(1.0, 30.0, 0.5) var heatwave_projectile_speed := 8.5
@export_range(0.25, 4.0, 0.05) var heatwave_projectile_lifetime := 1.45
@export_range(0.0, 1.0, 0.05) var heatwave_spawn_radius := 0.35
@export_range(0.2, 10.0, 0.05) var heatwave_cooldown := 4.8
@export_range(0.05, 2.0, 0.01) var heatwave_windup := 0.50
@export_range(0.0, 3.0, 0.05) var heatwave_recovery := 0.75
@export_range(0.5, 2.0, 0.05) var heatwave_approach_speed_multiplier := 1.20
@export var heatwave_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

@export_category("11 - Zırhlı Zayıf Nokta")
@export_range(0.5, 3.0, 0.05) var headshot_local_height := 1.15

@onready var heatwave_origin: Marker3D = get_node_or_null("HeatwaveOrigin") as Marker3D
@onready var heatwave_audio: AudioStreamPlayer3D = get_node_or_null("HeatwaveAudio") as AudioStreamPlayer3D

var _ground_slam_ready_at_msec := 0
var _heatwave_ready_at_msec := 0
var _heatwave_burst_generation := 0
var _last_heatwave_player_hit_generation := -1
var _warden_detour_direction := Vector3.ZERO
var _warden_detour_remaining := 0.0
var _warden_movement_target := Vector3.ZERO


func _navigate_to(target: Vector3, delta: float) -> void:
	# Warden chase intentionally mirrors the collision-tangent behavior that
	# works reliably for the RedViper family. Search/patrol still use the shared
	# AStar navigation, but active pursuit reacts to the wall actually touched
	# instead of sampling wide left/right guesses that can oscillate.
	if state == State.SEARCH or state == State.PATROL or state == State.RETURN:
		super._navigate_to(target, delta)
		return

	var resolved_target := _resolve_enemy_door_step(target)
	resolved_target.y = global_position.y
	_warden_movement_target = resolved_target
	_warden_detour_remaining = maxf(0.0, _warden_detour_remaining - delta)
	_refresh_warden_collision_detour()

	var direction := resolved_target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		_stop_horizontal_motion()
		return
	direction = direction.normalized()

	if (
		_warden_detour_remaining > 0.0
		and _warden_detour_direction.length_squared() > 0.001
	):
		direction = _warden_detour_direction

	_facing_direction = direction
	rotation.y = atan2(-direction.x, -direction.z)
	velocity.x = move_toward(
		velocity.x,
		direction.x * _runtime_move_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * _runtime_move_speed,
		delta * movement_acceleration
	)
	if animated_sprite.animation != &"hurt" and animated_sprite.animation != &"attack":
		_play_directional_animation(&"walk", &"walk_back")


func _refresh_warden_collision_detour() -> void:
	# Keep the chosen side briefly. Re-selecting every frame is what produced
	# the visible left/right oscillation around cover.
	if _warden_detour_remaining > 0.0:
		return

	for collision_index: int in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var normal := collision.get_normal()
		if absf(normal.y) >= 0.55:
			continue
		normal.y = 0.0
		if normal.length_squared() <= 0.001:
			continue
		normal = normal.normalized()

		var tangent_a := Vector3(-normal.z, 0.0, normal.x).normalized()
		var tangent_b := -tangent_a
		var target_direction := _warden_movement_target - global_position
		target_direction.y = 0.0
		if target_direction.length_squared() > 0.001:
			target_direction = target_direction.normalized()

		var probe_distance := maxf(navigation_clearance * 1.8, 1.15)
		var candidate_a := global_position + tangent_a * probe_distance
		var candidate_b := global_position + tangent_b * probe_distance
		var a_clear := _is_walk_segment_clear(global_position, candidate_a)
		var b_clear := _is_walk_segment_clear(global_position, candidate_b)

		if a_clear and not b_clear:
			_warden_detour_direction = tangent_a
		elif b_clear and not a_clear:
			_warden_detour_direction = tangent_b
		else:
			_warden_detour_direction = (
				tangent_a
				if tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)
				else tangent_b
			)
		_warden_detour_remaining = 0.70
		return


func _update_behavior(delta: float) -> void:
	# Crucible Warden is a close-pressure elite. Partial visibility around cover
	# must make it push the corner instead of waiting at long range.
	if (
		state != State.DEAD
		and _alerted
		and not _attack_locked
		and _player != null
		and is_instance_valid(_player)
	):
		var player_distance := _horizontal_distance(global_position, _player.global_position)
		if player_distance > heatwave_trigger_range * 0.95:
			var observer := global_position + Vector3.UP * sight_origin_height
			var visibility_ratio := _ranged_visibility_ratio_from(observer)
			if visibility_ratio < 0.85:
				state = State.CHASE
				_navigate_to(_player.global_position, delta)
				return
	super._update_behavior(delta)


func _attempt_attack() -> void:
	if _attack_locked or _player == null or not is_instance_valid(_player):
		return

	var distance_to_player := _horizontal_distance(global_position, _player.global_position)
	var now_msec := Time.get_ticks_msec()
	var heatwave_ready := now_msec >= _heatwave_ready_at_msec
	var ground_slam_ready := now_msec >= _ground_slam_ready_at_msec

	# Heatwave is the Warden's point-blank signature attack. When it is ready,
	# the enemy deliberately keeps closing instead of wasting the charge on a slam.
	if heatwave_ready:
		if distance_to_player > heatwave_trigger_range:
			_close_for_heatwave(heatwave_approach_speed_multiplier)
			return
		_begin_heatwave_attack()
		return

	# While Heatwave is cooling down, Ground Slam controls the nearby arena.
	if ground_slam_ready and distance_to_player <= ground_slam_trigger_range:
		_begin_ground_slam_attack()
		return

	# Both attacks can be cooling at once. Keep pressure instead of freezing at
	# the outer attack radius, but do not push through the player's body.
	if distance_to_player > heatwave_trigger_range * 0.85:
		_close_for_heatwave(0.90)
	else:
		_stop_horizontal_motion()


func _close_for_heatwave(speed_multiplier: float) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	# Do not bypass navigation while closing for Heatwave. Direct velocity toward
	# a player behind cover made the large Warden body slide unpredictably along
	# the wall and fight the chase detour logic.
	var delta := get_physics_process_delta_time()
	_navigate_to(_player.global_position, delta)
	var speed_scale := maxf(0.1, speed_multiplier)
	velocity.x *= speed_scale
	velocity.z *= speed_scale
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var maximum_speed := _runtime_move_speed * speed_scale
	if horizontal_speed > maximum_speed and horizontal_speed > 0.001:
		var scale := maximum_speed / horizontal_speed
		velocity.x *= scale
		velocity.z *= scale


func _begin_ground_slam_attack() -> void:
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	_stop_horizontal_motion()
	if _has_animation(&"attack"):
		animated_sprite.play(&"attack")
		_apply_frame_ground_offset()

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var runtime_windup := maxf(0.01, ground_slam_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD:
		return

	_emit_ground_slam()
	if attack_audio != null and attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()
	GameState.emit_noise(global_position, 1.5, self)

	var runtime_cooldown := maxf(runtime_windup, ground_slam_cooldown * cooldown_scale)
	_ground_slam_ready_at_msec = (
		Time.get_ticks_msec()
		+ int(round(runtime_cooldown * 1000.0))
	)
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")

	var recovery := maxf(0.0, ground_slam_recovery * cooldown_scale)
	if recovery > 0.0:
		await get_tree().create_timer(recovery).timeout
	if not is_inside_tree() or state == State.DEAD:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _begin_heatwave_attack() -> void:
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	_stop_horizontal_motion()
	if _has_animation(&"heatwave"):
		animated_sprite.play(&"heatwave")
		_apply_frame_ground_offset()

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var runtime_windup := maxf(0.01, heatwave_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD:
		return

	_emit_heatwave()
	if heatwave_audio != null and heatwave_audio.stream != null:
		heatwave_audio.stop()
		heatwave_audio.play()
	GameState.emit_noise(global_position, 1.25, self)

	var runtime_cooldown := maxf(runtime_windup, heatwave_cooldown * cooldown_scale)
	_heatwave_ready_at_msec = (
		Time.get_ticks_msec()
		+ int(round(runtime_cooldown * 1000.0))
	)
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")

	var recovery := maxf(0.0, heatwave_recovery * cooldown_scale)
	if recovery > 0.0:
		await get_tree().create_timer(recovery).timeout
	if not is_inside_tree() or state == State.DEAD:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _emit_ground_slam() -> void:
	if ground_slam_scene == null or get_tree().current_scene == null:
		return
	var slam := ground_slam_scene.instantiate() as Node3D
	if slam == null:
		return
	var runtime_damage := _scaled_special_damage(ground_slam_damage)
	if slam.has_method("configure"):
		slam.call(
			"configure",
			ground_slam_radius,
			runtime_damage,
			self,
			ground_slam_shake_radius,
			ground_slam_shake_strength,
			ground_slam_shake_duration
		)
	get_tree().current_scene.add_child(slam)
	slam.global_position = _ground_effect_position()


func _emit_heatwave() -> void:
	if heatwave_projectile_scene == null or get_tree().current_scene == null:
		return

	_heatwave_burst_generation += 1
	_last_heatwave_player_hit_generation = -1
	var burst_id := _heatwave_burst_generation
	var projectile_count := maxi(4, heatwave_projectile_count)
	var runtime_damage := _scaled_special_damage(heatwave_damage)
	var origin := (
		heatwave_origin.global_position
		if heatwave_origin != null
		else global_position
	)
	# Rotate the ring slightly each cast so repeated waves do not form identical
	# safe spokes, while preserving perfectly even 360-degree coverage.
	var angular_step := TAU / float(projectile_count)
	var angular_offset := randf_range(0.0, angular_step)

	for index in range(projectile_count):
		var projectile := heatwave_projectile_scene.instantiate() as Node3D
		if projectile == null:
			continue
		projectile.set("speed", heatwave_projectile_speed)
		projectile.set("lifetime", heatwave_projectile_lifetime)
		get_tree().current_scene.add_child(projectile)

		var angle := angular_offset + angular_step * float(index)
		var direction := Vector3(cos(angle), 0.0, sin(angle)).normalized()
		projectile.global_position = origin + direction * heatwave_spawn_radius
		if projectile.has_method("launch"):
			projectile.call(
				"launch",
				direction,
				self,
				runtime_damage,
				burst_id
			)


func apply_heatwave_projectile_hit(
	burst_id: int,
	target: Node,
	damage: int,
	hit_position: Vector3
) -> bool:
	if target == null or target != GameState.player:
		return false
	# Several radial projectiles can graze the player in the same ring. The
	# whole wave is one AoE attack, so a player can only take damage once/cast.
	if burst_id == _last_heatwave_player_hit_generation:
		return false
	_last_heatwave_player_hit_generation = burst_id
	if target.has_method("take_damage"):
		target.call("take_damage", maxi(1, damage), hit_position, self)
		return true
	return false


func _scaled_special_damage(base_damage: int) -> int:
	if not apply_difficulty_scaling:
		return maxi(1, base_damage)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	return maxi(1, int(round(float(base_damage) * damage_scale)))


func _ground_effect_position() -> Vector3:
	var ray_start := global_position + Vector3.UP * ground_probe_height
	var ray_end := global_position + Vector3.DOWN * ground_probe_depth
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		ground_effect_collision_mask,
		[get_rid()]
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return global_position + Vector3.DOWN * 0.9
	var floor_position: Vector3 = hit.get("position", global_position)
	var floor_normal: Vector3 = hit.get("normal", Vector3.UP)
	return floor_position + floor_normal * ground_effect_surface_offset


func get_weapon_hit_multiplier(
	hit_position: Vector3,
	base_headshot_multiplier: float
) -> float:
	var local_y := hit_position.y - global_position.y
	return base_headshot_multiplier if local_y >= headshot_local_height else 1.0


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"heatwave":
		return heatwave_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)


func _stop_horizontal_motion() -> void:
	# Ravager's generic ATTACK branch brakes before calling _attempt_attack().
	# The Warden sometimes uses that same branch to keep closing for Heatwave.
	# Skipping only that pre-attack brake prevents brake/accelerate jitter while
	# preserving normal stopping during actual attacks, patrol and search states.
	if (
		state == State.ATTACK
		and not _attack_locked
		and _player_visible
		and _player != null
		and is_instance_valid(_player)
	):
		var distance_to_player := _horizontal_distance(global_position, _player.global_position)
		var now_msec := Time.get_ticks_msec()
		var heatwave_ready := now_msec >= _heatwave_ready_at_msec
		var ground_slam_ready := now_msec >= _ground_slam_ready_at_msec
		var should_keep_closing := (
			(heatwave_ready and distance_to_player > heatwave_trigger_range)
			or (
				not heatwave_ready
				and not ground_slam_ready
				and distance_to_player > heatwave_trigger_range * 0.85
			)
		)
		if should_keep_closing:
			return
	super._stop_horizontal_motion()
