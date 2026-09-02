extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_test_sprint_gating_and_impulse()
	_test_stamina_delay_and_recovery()
	_test_jump_and_vertical_priority()
	_test_horizontal_acceleration()
	if _failures.is_empty():
		print("PLAYER MOVEMENT RUNTIME TEST OK")
		get_tree().quit(0)
		return
	for failure in _failures:
		push_error(failure)
	get_tree().quit(1)


func _test_sprint_gating_and_impulse() -> void:
	var runtime := VexPlayerMovementRuntime.new()
	_assert_true(
		runtime.wants_to_sprint(true, 1.0, 100.0, true, false, false, 0.1),
		"Grounded moving player should be able to sprint"
	)
	_assert_true(
		runtime.apply_external_impulse(Vector3.RIGHT, 6.0, 2.0, 0.5),
		"Valid external impulse was rejected"
	)
	_assert_true(
		not runtime.wants_to_sprint(true, 1.0, 100.0, true, false, false, 0.1),
		"External impulse should suppress sprint"
	)
	var velocity := runtime.update_horizontal_velocity(
		Vector3(1.0, 3.0, 2.0),
		Vector3(20.0, 0.0, 20.0),
		18.0,
		0.1
	)
	_assert_approx(velocity.x, 6.0, "Impulse did not override horizontal X velocity")
	_assert_approx(velocity.y, 3.0, "Horizontal runtime changed vertical velocity")
	_assert_approx(velocity.z, 0.0, "Impulse introduced unexpected Z velocity")
	var vertical := runtime.resolve_vertical_velocity(0.0, true, 7.0, 20.0, -0.1, 0.1)
	_assert_approx(vertical, 2.0, "Pending upward impulse was not applied")
	var after_pending := runtime.resolve_vertical_velocity(0.0, true, 7.0, 20.0, -0.1, 0.1)
	_assert_approx(after_pending, -0.1, "Upward impulse should only apply once")


func _test_stamina_delay_and_recovery() -> void:
	var runtime := VexPlayerMovementRuntime.new()
	var drained := runtime.update_stamina(1.0, 100.0, true, 100.0, 26.0, 20.0, 0.65)
	_assert_approx(float(drained.get("stamina", 0.0)), 74.0, "Sprint stamina drain changed")
	_assert_true(bool(drained.get("is_sprinting", false)), "Sprint stopped before stamina reached zero")
	var delayed := runtime.update_stamina(0.5, 74.0, false, 100.0, 26.0, 20.0, 0.65)
	_assert_approx(float(delayed.get("stamina", 0.0)), 74.0, "Stamina recovered before recovery delay ended")
	var recovered := runtime.update_stamina(0.2, 74.0, false, 100.0, 26.0, 20.0, 0.65)
	_assert_approx(float(recovered.get("stamina", 0.0)), 78.0, "Stamina recovery rate changed after delay")
	var exhausted := runtime.update_stamina(1.0, 10.0, true, 100.0, 26.0, 20.0, 0.65)
	_assert_approx(float(exhausted.get("stamina", -1.0)), 0.0, "Stamina should clamp at zero")
	_assert_true(not bool(exhausted.get("is_sprinting", true)), "Sprint should stop at zero stamina")


func _test_jump_and_vertical_priority() -> void:
	var runtime := VexPlayerMovementRuntime.new()
	_assert_true(not runtime.has_jump_request(), "Fresh movement runtime has a jump request")
	runtime.queue_jump(0.65)
	_assert_true(runtime.has_jump_request(), "Queued jump request was not retained")
	_assert_true(
		runtime.apply_external_impulse(Vector3.FORWARD, 5.0, 4.0, 0.4),
		"Impulse setup failed for jump-priority test"
	)
	var jump_velocity := runtime.resolve_vertical_velocity(1.0, true, 7.0, 20.0, -0.1, 0.1)
	_assert_approx(jump_velocity, 7.0, "Jump did not take priority over pending upward impulse")
	_assert_true(not runtime.has_jump_request(), "Jump request was not consumed")
	var impulse_velocity := runtime.resolve_vertical_velocity(1.0, false, 7.0, 20.0, -0.1, 0.1)
	_assert_approx(impulse_velocity, 4.0, "Pending upward impulse was lost after jump")
	var gravity_velocity := runtime.resolve_vertical_velocity(1.0, false, 7.0, 20.0, -0.1, 0.1)
	_assert_approx(gravity_velocity, -1.0, "Airborne gravity integration changed")


func _test_horizontal_acceleration() -> void:
	var runtime := VexPlayerMovementRuntime.new()
	var velocity := runtime.update_horizontal_velocity(
		Vector3.ZERO,
		Vector3(4.0, 0.0, -2.0),
		10.0,
		0.1
	)
	_assert_approx(velocity.x, 1.0, "Horizontal X acceleration changed")
	_assert_approx(velocity.z, -1.0, "Horizontal Z acceleration changed")


func _assert_true(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _assert_approx(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		_failures.append("%s: actual=%s expected=%s" % [message, actual, expected])
