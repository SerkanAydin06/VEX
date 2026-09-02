class_name VexPlayerImpactFeedbackRuntime
extends RefCounted

var _shake_remaining := 0.0
var _shake_duration := 0.0
var _shake_strength := 0.0
var _shake_base_offset := Vector2.ZERO
var _shake_active := false
var _shock_generation := 0


func request_camera_shake(
	strength: float,
	duration: float,
	current_camera_offset: Vector2
) -> bool:
	var safe_strength := maxf(0.0, strength)
	var safe_duration := maxf(0.0, duration)
	if safe_strength <= 0.0 or safe_duration <= 0.0:
		return false
	if not _shake_active:
		_shake_base_offset = current_camera_offset
	_shake_active = true
	_shake_strength = maxf(_shake_strength, safe_strength)
	_shake_duration = maxf(_shake_duration, safe_duration)
	_shake_remaining = maxf(_shake_remaining, safe_duration)
	return true


func update_camera_shake(delta: float, screen_shake_enabled: bool) -> Dictionary:
	if not _shake_active:
		return {
			"apply_offset": false,
			"active": false,
		}
	if not screen_shake_enabled:
		return clear_camera_shake()

	_shake_remaining = maxf(0.0, _shake_remaining - delta)
	if _shake_remaining <= 0.0:
		return clear_camera_shake()

	var fade := _shake_remaining / maxf(_shake_duration, 0.001)
	return {
		"apply_offset": true,
		"active": true,
		"camera_offset": Vector2(
			_shake_base_offset.x + randf_range(-_shake_strength, _shake_strength) * fade,
			_shake_base_offset.y + randf_range(-_shake_strength, _shake_strength) * fade
		),
	}


func clear_camera_shake() -> Dictionary:
	var had_active := _shake_active
	var base_offset := _shake_base_offset
	_shake_remaining = 0.0
	_shake_duration = 0.0
	_shake_strength = 0.0
	_shake_active = false
	return {
		"apply_offset": had_active,
		"active": false,
		"camera_offset": base_offset,
	}


func is_camera_shake_active() -> bool:
	return _shake_active


func begin_impact_shock(peak_alpha: float, duration: float) -> Dictionary:
	var safe_peak_alpha := clampf(peak_alpha, 0.0, 0.75)
	var safe_duration := maxf(0.05, duration)
	if safe_peak_alpha <= 0.0:
		return {"accepted": false}

	_shock_generation += 1
	var rise_duration := minf(0.045, safe_duration * 0.25)
	var fade_duration := maxf(0.01, safe_duration - rise_duration)
	return {
		"accepted": true,
		"generation": _shock_generation,
		"peak_alpha": safe_peak_alpha,
		"rise_duration": rise_duration,
		"fade_duration": fade_duration,
	}


func is_impact_shock_generation_current(generation: int) -> bool:
	return generation == _shock_generation
