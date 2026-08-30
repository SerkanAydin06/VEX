class_name VexFurniceCarrier
extends "res://scripts/actors/enemy_combatant_base.gd"

var _ability: VexFurniceCarrierAbilitySettings

@onready var thermal_burst_origin: Marker3D = $ThermalBurstOrigin

var _thermal_burst_ready_at_msec := 0


func _ready() -> void:
	_ability = special_ability_settings as VexFurniceCarrierAbilitySettings
	if _ability == null:
		_ability = VexFurniceCarrierAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Furnice Carrier özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func _attempt_attack() -> void:
	if _attack_locked or _player == null or not is_instance_valid(_player):
		return
	var combat_generation := _combat_interrupt_generation

	var distance_to_player := _horizontal_distance(global_position, _player.global_position)
	var thermal_burst_ready := Time.get_ticks_msec() >= _thermal_burst_ready_at_msec
	var use_thermal_burst := distance_to_player <= _ability.close_attack_threshold and thermal_burst_ready
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	_stop_horizontal_motion()

	var attack_animation: StringName = &"thermal_burst" if use_thermal_burst else &"attack"
	if _has_animation(attack_animation):
		animated_sprite.play(attack_animation)
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.play()

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var selected_windup := _ability.thermal_burst_windup if use_thermal_burst else _ability.projectile_attack_windup
	var runtime_windup := maxf(0.01, selected_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return

	if use_thermal_burst:
		_emit_thermal_burst()
		var runtime_thermal_cooldown := maxf(0.01, _ability.thermal_burst_cooldown * cooldown_scale)
		_thermal_burst_ready_at_msec = Time.get_ticks_msec() + int(round(runtime_thermal_cooldown * 1000.0))
	else:
		var still_in_range := (
			_player != null
			and is_instance_valid(_player)
			and _horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight():
			_fire_furnice_projectile()

	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")

	# Thermal Burst'un kendi cooldown'u ayrı tutulur. Yakında kalındığında burst
	# hazır değilse Carrier normal projectile saldırısına devam eder.
	var runtime_attack_cooldown := maxf(runtime_windup, _ability.projectile_attack_cooldown * cooldown_scale)
	var remaining := maxf(0.0, runtime_attack_cooldown - runtime_windup)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _fire_furnice_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	if get_tree().current_scene == null:
		return
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = _projectile_muzzle_world_position()

	# Atış anında hedef yönü kilitlenir; projectile sonrasında homing yapmaz.
	var target_position := _player.global_position + Vector3.UP * projectile_target_height
	var shot_direction := (target_position - projectile.global_position).normalized()
	var decal_damage := _scaled_special_damage(_ability.projectile_decal_tick_damage)
	projectile.call("launch", shot_direction, self, _runtime_attack_damage, decal_damage)


func _projectile_muzzle_world_position() -> Vector3:
	# Carrier billboard sprite kullandığı için muzzle'ı logical facing marker'ına bağlamak
	# ekranda kayma üretir. Offset doğrudan 512x341 attack frame'indeki furnace ağzının
	# piksel konumuna bağlanır. +X sprite üzerinde sağ, +Y sprite üzerinde aşağıdır.
	var billboard_right := Vector3.RIGHT
	var camera := get_viewport().get_camera_3d()
	if camera != null and is_instance_valid(camera):
		billboard_right = camera.global_transform.basis.x
		billboard_right.y = 0.0
		if billboard_right.length_squared() > 0.001:
			billboard_right = billboard_right.normalized()
		else:
			billboard_right = Vector3.RIGHT

	var depth_direction := _facing_direction
	if _player != null and is_instance_valid(_player):
		depth_direction = _player.global_position - global_position
	depth_direction.y = 0.0
	if depth_direction.length_squared() <= 0.001:
		depth_direction = Vector3.FORWARD
	else:
		depth_direction = depth_direction.normalized()

	var pixel_offset := _ability.projectile_muzzle_sprite_offset_pixels
	var pixel_size := animated_sprite.pixel_size
	return (
		animated_sprite.global_position
		+ billboard_right * pixel_offset.x * pixel_size
		+ Vector3.UP * -pixel_offset.y * pixel_size
		+ depth_direction * _ability.projectile_muzzle_depth_offset
	)


func _emit_thermal_burst() -> void:
	if _ability.thermal_burst_scene == null or get_tree().current_scene == null:
		return
	var shockwave := _ability.thermal_burst_scene.instantiate() as Node3D
	if shockwave == null:
		return
	var runtime_damage := _scaled_special_damage(_ability.thermal_burst_damage)
	if shockwave.has_method("configure"):
		shockwave.call("configure", runtime_damage, self)
	get_tree().current_scene.add_child(shockwave)
	shockwave.global_position = _ground_effect_position()


func _scaled_special_damage(base_damage: int) -> int:
	if not apply_difficulty_scaling:
		return maxi(1, base_damage)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	return maxi(1, int(round(float(base_damage) * damage_scale)))


func _ground_effect_position() -> Vector3:
	var origin := thermal_burst_origin.global_position
	var ray_start := origin + Vector3.UP * _ability.ground_probe_height
	var ray_end := origin + Vector3.DOWN * _ability.ground_probe_depth
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, _ability.ground_effect_collision_mask, [get_rid()])
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return origin
	var floor_position: Vector3 = hit.get("position", origin)
	var floor_normal: Vector3 = hit.get("normal", Vector3.UP)
	return floor_position + floor_normal * _ability.ground_effect_surface_offset


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"thermal_burst":
		return _ability.thermal_burst_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
