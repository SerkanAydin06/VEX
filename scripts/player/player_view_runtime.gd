class_name VexPlayerViewRuntime
extends RefCounted

var _pitch := 0.0
var _recoil_pitch_degrees := 0.0
var _recoil_yaw_degrees := 0.0
var _recoil_recovery_degrees_per_second := 7.0
var _bob_time := 0.0
var _footstep_remaining := 0.0
var _camera_rest_position := Vector3.ZERO
var _bob_activation_threshold := 0.05
var _bob_speed_multiplier := 1.0
var _bob_horizontal_frequency_multiplier := 0.5
var _bob_horizontal_amplitude := 0.0
var _bob_vertical_amplitude := 0.0
var _bob_lerp_speed := 1.0
var _bob_return_lerp_speed := 1.0
var _footstep_pitch_min := 1.0
var _footstep_pitch_max := 1.0
var _sprint_footstep_interval := 0.34
var _walk_footstep_interval := 0.46
var _walk_speed := 4.0
var _sprint_detection_margin := 0.1


func initialize(camera_rest_position: Vector3) -> void:
	_camera_rest_position = camera_rest_position


func configure_bob(
	activation_threshold: float,
	speed_multiplier: float,
	horizontal_frequency_multiplier: float,
	horizontal_amplitude: float,
	vertical_amplitude: float,
	lerp_speed: float,
	return_lerp_speed: float,
	footstep_pitch_min: float,
	footstep_pitch_max: float,
	sprint_footstep_interval: float,
	walk_footstep_interval: float,
	walk_speed: float,
	sprint_detection_margin: float
) -> void:
	_bob_activation_threshold = maxf(0.0, activation_threshold)
	_bob_speed_multiplier = maxf(0.0, speed_multiplier)
	_bob_horizontal_frequency_multiplier = maxf(0.0, horizontal_frequency_multiplier)
	_bob_horizontal_amplitude = maxf(0.0, horizontal_amplitude)
	_bob_vertical_amplitude = maxf(0.0, vertical_amplitude)
	_bob_lerp_speed = maxf(0.0, lerp_speed)
	_bob_return_lerp_speed = maxf(0.0, return_lerp_speed)
	_footstep_pitch_min = footstep_pitch_min
	_footstep_pitch_max = maxf(footstep_pitch_min, footstep_pitch_max)
	_sprint_footstep_interval = maxf(0.01, sprint_footstep_interval)
	_walk_footstep_interval = maxf(0.01, walk_footstep_interval)
	_walk_speed = maxf(0.0, walk_speed)
	_sprint_detection_margin = maxf(0.0, sprint_detection_margin)


func apply_mouse_look(
	relative: Vector2,
	mouse_sensitivity: float,
	pitch_limit_degrees: float
) -> float:
	var yaw_delta := deg_to_rad(-relative.x * mouse_sensitivity)
	_pitch = clampf(
		_pitch - deg_to_rad(relative.y * mouse_sensitivity),
		deg_to_rad(-pitch_limit_degrees),
		deg_to_rad(pitch_limit_degrees)
	)
	return yaw_delta


func apply_controller_look(
	look: Vector2,
	controller_sensitivity: float,
	delta: float,
	pitch_limit_degrees: float
) -> float:
	var sensitivity := controller_sensitivity * delta
	_pitch = clampf(
		_pitch - look.y * sensitivity,
		deg_to_rad(-pitch_limit_degrees),
		deg_to_rad(pitch_limit_degrees)
	)
	return -look.x * sensitivity


func apply_recoil(
	vertical_degrees: float,
	horizontal_degrees: float,
	max_vertical_degrees: float,
	max_horizontal_degrees: float,
	recovery_degrees_per_second: float
) -> void:
	_recoil_pitch_degrees = clampf(
		_recoil_pitch_degrees + maxf(0.0, vertical_degrees),
		0.0,
		maxf(0.0, max_vertical_degrees)
	)
	_recoil_yaw_degrees = clampf(
		_recoil_yaw_degrees + horizontal_degrees,
		-maxf(0.0, max_horizontal_degrees),
		maxf(0.0, max_horizontal_degrees)
	)
	_recoil_recovery_degrees_per_second = maxf(0.1, recovery_degrees_per_second)


func clear_recoil() -> void:
	_recoil_pitch_degrees = 0.0
	_recoil_yaw_degrees = 0.0


func update_recoil(delta: float, yaw_recovery_multiplier: float) -> void:
	_recoil_pitch_degrees = move_toward(
		_recoil_pitch_degrees,
		0.0,
		_recoil_recovery_degrees_per_second * delta
	)
	_recoil_yaw_degrees = move_toward(
		_recoil_yaw_degrees,
		0.0,
		_recoil_recovery_degrees_per_second * yaw_recovery_multiplier * delta
	)


func get_view_rotation(pitch_limit_degrees: float) -> Vector2:
	return Vector2(
		clampf(
			_pitch + deg_to_rad(_recoil_pitch_degrees),
			deg_to_rad(-pitch_limit_degrees),
			deg_to_rad(pitch_limit_degrees)
		),
		deg_to_rad(_recoil_yaw_degrees)
	)


func get_hud_recoil(is_aiming: bool) -> Vector2:
	if is_aiming:
		return Vector2.ZERO
	return Vector2(_recoil_yaw_degrees, _recoil_pitch_degrees)


func update_view_bob(
	delta: float,
	current_camera_position: Vector3,
	on_floor: bool,
	movement_amount: float,
	movement_speed: float,
	head_bob_enabled: bool,
	footstep_available: bool,
	is_crouching: bool,
	is_sprinting: bool
) -> Dictionary:
	_footstep_remaining = maxf(0.0, _footstep_remaining - delta)
	if on_floor and movement_amount > _bob_activation_threshold:
		_bob_time += delta * movement_speed * _bob_speed_multiplier
		var bob_offset := Vector3.ZERO
		if head_bob_enabled:
			bob_offset = Vector3(
				cos(_bob_time * _bob_horizontal_frequency_multiplier) * _bob_horizontal_amplitude,
				sin(_bob_time) * _bob_vertical_amplitude,
				0.0
			)
		var camera_position := current_camera_position.lerp(
			_camera_rest_position + bob_offset,
			delta * _bob_lerp_speed
		)
		var play_footstep := footstep_available and _footstep_remaining <= 0.0
		var footstep_pitch := 1.0
		var footstep_loudness := 0.0
		if play_footstep:
			footstep_pitch = randf_range(_footstep_pitch_min, _footstep_pitch_max)
			_footstep_remaining = (
				_sprint_footstep_interval
				if movement_speed > _walk_speed + _sprint_detection_margin
				else _walk_footstep_interval
			)
			footstep_loudness = 0.18 if is_crouching else (0.95 if is_sprinting else 0.45)
		return {
			"camera_position": camera_position,
			"play_footstep": play_footstep,
			"footstep_pitch": footstep_pitch,
			"footstep_loudness": footstep_loudness,
		}

	return {
		"camera_position": current_camera_position.lerp(
			_camera_rest_position,
			delta * _bob_return_lerp_speed
		),
		"play_footstep": false,
		"footstep_pitch": 1.0,
		"footstep_loudness": 0.0,
	}
