class_name VexPlayerViewRuntime
extends RefCounted

var _pitch := 0.0
var _recoil_pitch_degrees := 0.0
var _recoil_yaw_degrees := 0.0
var _recoil_recovery_degrees_per_second := 7.0
var _bob_time := 0.0
var _footstep_remaining := 0.0
var _camera_rest_position := Vector3.ZERO


func initialize(camera_rest_position: Vector3) -> void:
	_camera_rest_position = camera_rest_position


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
	is_sprinting: bool,
	tuning: Dictionary
) -> Dictionary:
	_footstep_remaining = maxf(0.0, _footstep_remaining - delta)
	var activation_threshold := float(tuning.get("activation_threshold", 0.05))
	if on_floor and movement_amount > activation_threshold:
		_bob_time += delta * movement_speed * float(tuning.get("speed_multiplier", 1.0))
		var bob_offset := Vector3.ZERO
		if head_bob_enabled:
			bob_offset = Vector3(
				cos(_bob_time * float(tuning.get("horizontal_frequency_multiplier", 0.5)))
				* float(tuning.get("horizontal_amplitude", 0.0)),
				sin(_bob_time) * float(tuning.get("vertical_amplitude", 0.0)),
				0.0
			)
		var camera_position := current_camera_position.lerp(
			_camera_rest_position + bob_offset,
			delta * float(tuning.get("lerp_speed", 1.0))
		)
		var play_footstep := footstep_available and _footstep_remaining <= 0.0
		var footstep_pitch := 1.0
		var footstep_loudness := 0.0
		if play_footstep:
			footstep_pitch = randf_range(
				float(tuning.get("footstep_pitch_min", 1.0)),
				float(tuning.get("footstep_pitch_max", 1.0))
			)
			_footstep_remaining = (
				float(tuning.get("sprint_footstep_interval", 0.34))
				if movement_speed
				> float(tuning.get("walk_speed", 4.0))
				+ float(tuning.get("sprint_detection_margin", 0.1))
				else float(tuning.get("walk_footstep_interval", 0.46))
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
			delta * float(tuning.get("return_lerp_speed", 1.0))
		),
		"play_footstep": false,
		"footstep_pitch": 1.0,
		"footstep_loudness": 0.0,
	}
