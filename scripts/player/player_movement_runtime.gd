class_name VexPlayerMovementRuntime
extends RefCounted

var _jump_requested := false
var _stamina_recovery_delay_remaining := 0.0
var _external_impulse_velocity := Vector3.ZERO
var _external_impulse_remaining := 0.0
var _external_impulse_decay_speed := 0.0
var _external_impulse_vertical_pending := 0.0


func wants_to_sprint(
	sprint_pressed: bool,
	movement_amount: float,
	current_stamina: float,
	on_floor: bool,
	is_crouching: bool,
	is_aiming: bool,
	input_threshold: float
) -> bool:
	return (
		sprint_pressed
		and movement_amount >= input_threshold
		and current_stamina > 0.0
		and on_floor
		and not is_crouching
		and not is_aiming
		and not has_external_impulse()
	)


func queue_jump(stamina_recovery_delay: float) -> void:
	_jump_requested = true
	_stamina_recovery_delay_remaining = maxf(0.0, stamina_recovery_delay)


func has_jump_request() -> bool:
	return _jump_requested


func update_stamina(
	delta: float,
	current_stamina: float,
	is_sprinting: bool,
	maximum_stamina: float,
	sprint_drain_per_second: float,
	recovery_per_second: float,
	recovery_delay: float
) -> Dictionary:
	if is_sprinting:
		current_stamina = maxf(
			0.0,
			current_stamina - sprint_drain_per_second * delta
		)
		_stamina_recovery_delay_remaining = maxf(0.0, recovery_delay)
		if current_stamina <= 0.0:
			is_sprinting = false
		return {
			"stamina": current_stamina,
			"is_sprinting": is_sprinting,
		}

	_stamina_recovery_delay_remaining = maxf(
		0.0,
		_stamina_recovery_delay_remaining - delta
	)
	if _stamina_recovery_delay_remaining <= 0.0:
		current_stamina = minf(
			maximum_stamina,
			current_stamina + recovery_per_second * delta
		)
	return {
		"stamina": current_stamina,
		"is_sprinting": is_sprinting,
	}


func reset_stamina_recovery_delay() -> void:
	_stamina_recovery_delay_remaining = 0.0


func apply_external_impulse(
	direction: Vector3,
	horizontal_speed: float,
	upward_speed: float,
	duration: float
) -> bool:
	var horizontal_direction := direction
	horizontal_direction.y = 0.0
	if horizontal_direction.length_squared() <= 0.001:
		return false
	horizontal_direction = horizontal_direction.normalized()
	var safe_speed := maxf(0.0, horizontal_speed)
	var safe_duration := maxf(0.05, duration)
	_external_impulse_velocity = horizontal_direction * safe_speed
	_external_impulse_remaining = safe_duration
	_external_impulse_decay_speed = safe_speed / safe_duration
	_external_impulse_vertical_pending = maxf(
		_external_impulse_vertical_pending,
		maxf(0.0, upward_speed)
	)
	return true


func has_external_impulse() -> bool:
	return _external_impulse_remaining > 0.0


func update_horizontal_velocity(
	current_velocity: Vector3,
	target_velocity: Vector3,
	rate: float,
	delta: float
) -> Vector3:
	var result := current_velocity
	if has_external_impulse():
		result.x = _external_impulse_velocity.x
		result.z = _external_impulse_velocity.z
		_external_impulse_remaining = maxf(0.0, _external_impulse_remaining - delta)
		_external_impulse_velocity = _external_impulse_velocity.move_toward(
			Vector3.ZERO,
			_external_impulse_decay_speed * delta
		)
		if _external_impulse_remaining <= 0.0:
			_external_impulse_velocity = Vector3.ZERO
		return result

	result.x = move_toward(result.x, target_velocity.x, rate * delta)
	result.z = move_toward(result.z, target_velocity.z, rate * delta)
	return result


func resolve_vertical_velocity(
	current_velocity_y: float,
	on_floor: bool,
	jump_velocity: float,
	gravity: float,
	floor_stick_velocity: float,
	delta: float
) -> float:
	if _jump_requested:
		_jump_requested = false
		return jump_velocity
	if _external_impulse_vertical_pending > 0.0:
		var impulse_velocity := maxf(
			current_velocity_y,
			_external_impulse_vertical_pending
		)
		_external_impulse_vertical_pending = 0.0
		return impulse_velocity
	if not on_floor:
		return current_velocity_y - gravity * delta
	return floor_stick_velocity
