class_name VexFurniceCarrier
extends "res://scripts/actors/ravager.gd"

@export_category("09 - Furnice Carrier Saldırı Seçimi")
@export_range(0.5, 12.0, 0.1) var close_attack_threshold := 6.0
@export_range(0.2, 6.0, 0.05) var projectile_attack_cooldown := 1.80
@export_range(0.05, 2.0, 0.05) var projectile_attack_windup := 0.45
@export_range(1, 100, 1) var projectile_decal_tick_damage := 4

@export_category("10 - Thermal Burst")
@export var thermal_burst_scene: PackedScene
@export_range(1, 100, 1) var thermal_burst_damage := 22
@export_range(0.2, 8.0, 0.05) var thermal_burst_cooldown := 3.20
@export_range(0.05, 2.0, 0.05) var thermal_burst_windup := 0.50
@export var thermal_burst_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export_flags_3d_physics var ground_effect_collision_mask := 1
@export_range(0.1, 4.0, 0.1) var ground_probe_height := 1.0
@export_range(0.5, 6.0, 0.1) var ground_probe_depth := 2.5
@export_range(0.0, 0.2, 0.01) var ground_effect_surface_offset := 0.03

@onready var projectile_muzzle: Marker3D = $ProjectileMuzzle
@onready var thermal_burst_origin: Marker3D = $ThermalBurstOrigin

var _thermal_burst_ready_at_msec := 0


func _attempt_attack() -> void:
	if _attack_locked or _player == null or not is_instance_valid(_player):
		return

	var distance_to_player := _horizontal_distance(global_position, _player.global_position)
	var thermal_burst_ready := Time.get_ticks_msec() >= _thermal_burst_ready_at_msec
	var use_thermal_burst := distance_to_player <= close_attack_threshold and thermal_burst_ready
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
	var selected_windup := thermal_burst_windup if use_thermal_burst else projectile_attack_windup
	var runtime_windup := maxf(0.01, selected_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD:
		return

	if use_thermal_burst:
		_emit_thermal_burst()
		var runtime_thermal_cooldown := maxf(0.01, thermal_burst_cooldown * cooldown_scale)
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
	var runtime_attack_cooldown := maxf(runtime_windup, projectile_attack_cooldown * cooldown_scale)
	var remaining := maxf(0.0, runtime_attack_cooldown - runtime_windup)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or state == State.DEAD:
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
	var decal_damage := _scaled_special_damage(projectile_decal_tick_damage)
	projectile.call("launch", shot_direction, self, _runtime_attack_damage, decal_damage)


func _projectile_muzzle_world_position() -> Vector3:
	# Marker konumu Inspector tuning verisidir:
	# X = sağ/sol, Y = yükseklik, Z = baktığı yönde ileri/geri.
	# Ravager omurgası root'u fiziksel olarak döndürmediği için marker global_position'ı
	# doğrudan kullanmak yerine logical facing yönüne dönüştürürüz.
	var forward := _facing_direction
	forward.y = 0.0
	if forward.length_squared() <= 0.001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() <= 0.001:
		right = Vector3.RIGHT
	else:
		right = right.normalized()
	var tuning_offset := projectile_muzzle.position
	return (
		global_position
		+ right * tuning_offset.x
		+ Vector3.UP * tuning_offset.y
		+ forward * tuning_offset.z
	)


func _emit_thermal_burst() -> void:
	if thermal_burst_scene == null or get_tree().current_scene == null:
		return
	var shockwave := thermal_burst_scene.instantiate() as Node3D
	if shockwave == null:
		return
	var runtime_damage := _scaled_special_damage(thermal_burst_damage)
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
	var ray_start := origin + Vector3.UP * ground_probe_height
	var ray_end := origin + Vector3.DOWN * ground_probe_depth
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, ground_effect_collision_mask, [get_rid()])
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return origin
	var floor_position: Vector3 = hit.get("position", origin)
	var floor_normal: Vector3 = hit.get("normal", Vector3.UP)
	return floor_position + floor_normal * ground_effect_surface_offset


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"thermal_burst":
		return thermal_burst_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
