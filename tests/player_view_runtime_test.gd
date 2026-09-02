extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_test_mouse_look()
	_test_controller_look()
	_test_recoil_state()
	_test_view_bob_and_footsteps()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return
	print("PLAYER VIEW RUNTIME TEST: OK")
	get_tree().quit(0)


func _test_mouse_look() -> void:
	var runtime := VexPlayerViewRuntime.new()
	runtime.initialize(Vector3(0.0, 1.0, 0.0))
	var yaw_delta := runtime.apply_mouse_look(Vector2(10.0, -5.0), 0.2, 82.0)
	_expect_close(yaw_delta, deg_to_rad(-2.0), 0.0001, "Mouse yaw delta değişti")
	var rotation := runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, deg_to_rad(1.0), 0.0001, "Mouse pitch hesabı değişti")

	runtime.apply_mouse_look(Vector2(0.0, 1000.0), 1.0, 82.0)
	rotation = runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, deg_to_rad(-82.0), 0.0001, "Mouse pitch alt limite clamp edilmiyor")


func _test_controller_look() -> void:
	var runtime := VexPlayerViewRuntime.new()
	var yaw_delta := runtime.apply_controller_look(Vector2(1.0, 0.5), 2.0, 0.1, 82.0)
	_expect_close(yaw_delta, -0.2, 0.0001, "Controller yaw hesabı değişti")
	var rotation := runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, -0.1, 0.0001, "Controller pitch hesabı değişti")


func _test_recoil_state() -> void:
	var runtime := VexPlayerViewRuntime.new()
	runtime.apply_recoil(4.0, 3.0, 5.0, 2.0, 4.0)
	var rotation := runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, deg_to_rad(4.0), 0.0001, "Recoil pitch uygulanmıyor")
	_expect_close(rotation.y, deg_to_rad(2.0), 0.0001, "Recoil yaw clamp değişti")
	_expect_vector2(runtime.get_hud_recoil(false), Vector2(2.0, 4.0), 0.0001, "HUD recoil offset değişti")
	_expect_vector2(runtime.get_hud_recoil(true), Vector2.ZERO, 0.0001, "ADS sırasında HUD recoil gizlenmiyor")

	runtime.update_recoil(0.5, 0.5)
	rotation = runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, deg_to_rad(2.0), 0.0001, "Recoil pitch recovery değişti")
	_expect_close(rotation.y, deg_to_rad(1.0), 0.0001, "Recoil yaw recovery değişti")

	runtime.clear_recoil()
	rotation = runtime.get_view_rotation(82.0)
	_expect_close(rotation.x, 0.0, 0.0001, "Recoil pitch temizlenmiyor")
	_expect_close(rotation.y, 0.0, 0.0001, "Recoil yaw temizlenmiyor")


func _test_view_bob_and_footsteps() -> void:
	var runtime := VexPlayerViewRuntime.new()
	var rest := Vector3(0.0, 1.0, 0.0)
	runtime.initialize(rest)
	runtime.configure_bob(
		0.05,
		1.70,
		0.50,
		0.025,
		0.035,
		12.0,
		10.0,
		0.94,
		1.06,
		0.34,
		0.46,
		4.0,
		0.10
	)
	var first := runtime.update_view_bob(
		0.1,
		rest,
		true,
		1.0,
		4.0,
		true,
		true,
		false,
		false
	)
	_expect(bool(first.get("play_footstep", false)), "İlk yürüyüş adımı tetiklenmiyor")
	var first_pitch := float(first.get("footstep_pitch", 0.0))
	_expect(first_pitch >= 0.94 and first_pitch <= 1.06, "Footstep pitch tuning aralığından çıkıyor")
	_expect_close(float(first.get("footstep_loudness", 0.0)), 0.45, 0.0001, "Walk noise loudness değişti")
	var bobbed_position := first.get("camera_position", rest) as Vector3
	_expect(bobbed_position.distance_to(rest) > 0.0001, "Head bob kamera offseti üretmiyor")

	var second := runtime.update_view_bob(
		0.1,
		bobbed_position,
		true,
		1.0,
		4.0,
		true,
		true,
		false,
		false
	)
	_expect(not bool(second.get("play_footstep", false)), "Footstep cooldown korunmuyor")
	var second_position := second.get("camera_position", bobbed_position) as Vector3
	var airborne := runtime.update_view_bob(
		0.1,
		second_position,
		false,
		1.0,
		4.0,
		true,
		true,
		false,
		false
	)
	var returned_position := airborne.get("camera_position", second_position) as Vector3
	_expect(
		returned_position.distance_to(rest) < second_position.distance_to(rest),
		"Hareket kesilince kamera rest pozisyonuna dönmüyor"
	)
	_expect(not bool(airborne.get("play_footstep", false)), "Havada footstep tetikleniyor")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		_failures.append("%s: actual=%.6f expected=%.6f" % [message, actual, expected])


func _expect_vector2(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> void:
	if actual.distance_to(expected) > tolerance:
		_failures.append("%s: actual=%s expected=%s" % [message, str(actual), str(expected)])
