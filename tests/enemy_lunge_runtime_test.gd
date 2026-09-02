extends Node

const LungeRuntime = preload("res://scripts/actors/enemy_lunge_runtime.gd")


func _ready() -> void:
	_assert_close(
		LungeRuntime.initial_attack_lunge_duration(0.35, 0.25),
		0.25,
		"windup should cap lunge duration"
	)
	_assert_close(
		LungeRuntime.initial_attack_lunge_duration(-1.0, 0.25),
		0.0,
		"negative lunge duration should clamp to zero"
	)

	var expired := LungeRuntime.attack_lunge_plan(
		Vector3.ZERO,
		Vector3(0.0, 0.0, -2.0),
		true,
		0.0,
		4.0,
		0.4,
		0.1
	)
	_assert_equal(int(expired.get("mode", -1)), LungeRuntime.MODE_BRAKE, "expired lunge should brake")
	_assert_close(float(expired.get("remaining", -1.0)), 0.0, "expired lunge remaining")

	var invalid_player := LungeRuntime.attack_lunge_plan(
		Vector3.ZERO,
		Vector3(0.0, 0.0, -2.0),
		false,
		0.3,
		4.0,
		0.4,
		0.1
	)
	_assert_equal(
		int(invalid_player.get("mode", -1)),
		LungeRuntime.MODE_BRAKE,
		"invalid player should brake"
	)
	_assert_close(float(invalid_player.get("remaining", -1.0)), 0.0, "invalid player remaining")

	var stopped := LungeRuntime.attack_lunge_plan(
		Vector3.ZERO,
		Vector3(0.0, 0.0, -0.5),
		true,
		0.3,
		4.0,
		0.6,
		0.1
	)
	_assert_equal(int(stopped.get("mode", -1)), LungeRuntime.MODE_STOP, "close target should hard stop")
	_assert_close(float(stopped.get("remaining", -1.0)), 0.2, "hard stop should preserve countdown")
	_assert_vector_close(
		stopped.get("desired_velocity", Vector3.ONE),
		Vector3.ZERO,
		"hard stop velocity"
	)

	var moving := LungeRuntime.attack_lunge_plan(
		Vector3.ZERO,
		Vector3(0.0, 0.0, -2.0),
		true,
		0.3,
		4.0,
		0.4,
		0.1
	)
	_assert_equal(int(moving.get("mode", -1)), LungeRuntime.MODE_MOVE, "distant target should move")
	_assert_close(float(moving.get("remaining", -1.0)), 0.2, "moving lunge countdown")
	_assert_vector_close(
		moving.get("facing_direction", Vector3.ZERO),
		Vector3(0.0, 0.0, -1.0),
		"moving lunge facing"
	)
	_assert_vector_close(
		moving.get("desired_velocity", Vector3.ZERO),
		Vector3(0.0, 0.0, -4.0),
		"moving lunge desired velocity"
	)

	print("ENEMY LUNGE RUNTIME TEST: OK")
	get_tree().quit()


func _assert_equal(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		get_tree().quit(1)


func _assert_close(actual: float, expected: float, message: String) -> void:
	if not is_equal_approx(actual, expected):
		push_error("%s: expected %.6f, got %.6f" % [message, expected, actual])
		get_tree().quit(1)


func _assert_vector_close(actual: Vector3, expected: Vector3, message: String) -> void:
	if not actual.is_equal_approx(expected):
		push_error("%s: expected %s, got %s" % [message, expected, actual])
		get_tree().quit(1)
