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
@export_range(0.3, 3.0, 0.05) var heatwave_approach_stall_timeout := 0.90
@export_range(0.05, 0.5, 0.01) var heatwave_approach_min_progress := 0.12
@export var heatwave_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

@export_category("11 - Zırhlı Zayıf Nokta")
@export_range(0.5, 3.0, 0.05) var headshot_local_height := 1.15

@onready var heatwave_origin: Marker3D = get_node_or_null("HeatwaveOrigin") as Marker3D
@onready var heatwave_audio: AudioStreamPlayer3D = get_node_or_null("HeatwaveAudio") as AudioStreamPlayer3D

var _ground_slam_ready_at_msec := 0
var _heatwave_ready_at_msec := 0
var _heatwave_burst_generation := 0
var _last_heatwave_player_hit_generation := -1
var _heatwave_approach_best_distance := INF
var _heatwave_approach_stall_remaining := 0.0
var _heatwave_approach_anchor_position := Vector3.ZERO
var _has_heatwave_approach_anchor := false


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
			if _is_heatwave_approach_stalled(distance_to_player):
				# Rota veya kapı ağzı ilerlemiyorsa aynı bitmiş yolu her kare yeniden
				# kullanma. Önce rotayı zorla yenile; oyuncu Slam menzilinde ve gerçekten
				# görünürse elit düşman dimdik beklemek yerine alan baskısına döner.
				_clear_path()
				_path_refresh_remaining = 0.0
				_reset_heatwave_approach_progress(distance_to_player)
				if (
					ground_slam_ready
					and distance_to_player <= ground_slam_trigger_range
					and _check_line_of_sight()
				):
					_begin_ground_slam_attack()
					return
			_close_for_heatwave(heatwave_approach_speed_multiplier)
			return
		_reset_heatwave_approach_progress()
		_begin_heatwave_attack()
		return
	_reset_heatwave_approach_progress()

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


func _is_heatwave_approach_stalled(distance_to_player: float) -> bool:
	var delta := maxf(get_physics_process_delta_time(), 0.001)
	var moved_since_anchor := (
		_has_heatwave_approach_anchor
		and _horizontal_distance(global_position, _heatwave_approach_anchor_position)
		>= heatwave_approach_min_progress
	)
	if (
		not _has_heatwave_approach_anchor
		or is_inf(_heatwave_approach_best_distance)
		or moved_since_anchor
		or distance_to_player
		< _heatwave_approach_best_distance - heatwave_approach_min_progress
	):
		_heatwave_approach_best_distance = minf(
			_heatwave_approach_best_distance,
			distance_to_player
		)
		_heatwave_approach_anchor_position = global_position
		_has_heatwave_approach_anchor = true
		_heatwave_approach_stall_remaining = heatwave_approach_stall_timeout
		return false
	_heatwave_approach_stall_remaining = maxf(
		0.0,
		_heatwave_approach_stall_remaining - delta
	)
	return _heatwave_approach_stall_remaining <= 0.0


func _reset_heatwave_approach_progress(current_distance: float = INF) -> void:
	_heatwave_approach_best_distance = current_distance
	_heatwave_approach_stall_remaining = heatwave_approach_stall_timeout
	_heatwave_approach_anchor_position = global_position
	_has_heatwave_approach_anchor = not is_inf(current_distance)


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
		var velocity_scale := maximum_speed / horizontal_speed
		velocity.x *= velocity_scale
		velocity.z *= velocity_scale


func _begin_ground_slam_attack() -> void:
	var combat_generation := _combat_interrupt_generation
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
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
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
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _begin_heatwave_attack() -> void:
	var combat_generation := _combat_interrupt_generation
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
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
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
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
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
