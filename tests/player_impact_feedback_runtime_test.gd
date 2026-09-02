extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_test_camera_shake_state()
	_test_camera_shake_setting_clear()
	_test_impact_shock_plan()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return
	print("PLAYER IMPACT FEEDBACK RUNTIME TEST: OK")
	get_tree().quit(0)


func _test_camera_shake_state() -> void:
	var runtime := VexPlayerImpactFeedbackRuntime.new()
	var base := Vector2(0.15, -0.20)
	_expect(
		not runtime.request_camera_shake(0.0, 0.2, base),
		"Sıfır strength camera shake kabul ediliyor"
	)
	_expect(not runtime.is_camera_shake_active(), "Geçersiz shake runtime'ı aktif ediyor")

	_expect(runtime.request_camera_shake(0.4, 0.5, base), "Geçerli camera shake reddediliyor")
	_expect(runtime.is_camera_shake_active(), "Camera shake aktif state'e geçmiyor")
	# Aktif shake sırasında yeni istek base offset'i değiştirmemeli; yalnız güç/süre büyüyebilir.
	_expect(
		runtime.request_camera_shake(0.2, 0.8, Vector2(9.0, 9.0)),
		"İkinci camera shake isteği reddediliyor"
	)
	var tick := runtime.update_camera_shake(0.1, true)
	_expect(bool(tick.get("apply_offset", false)), "Aktif shake kamera offseti üretmiyor")
	_expect(bool(tick.get("active", false)), "Shake erken bitiyor")
	var offset := tick.get("camera_offset", Vector2.ZERO) as Vector2
	_expect(
		absf(offset.x - base.x) <= 0.4001 and absf(offset.y - base.y) <= 0.4001,
		"Shake offseti strength sınırının dışına çıkıyor"
	)

	var finished := runtime.update_camera_shake(1.0, true)
	_expect(not bool(finished.get("active", true)), "Shake süresi dolunca bitmiyor")
	_expect(bool(finished.get("apply_offset", false)), "Shake bitişinde base offset geri uygulanmıyor")
	_expect_vector2(
		finished.get("camera_offset", Vector2.ZERO) as Vector2,
		base,
		0.0001,
		"Shake bitişinde ilk kamera offseti geri gelmiyor"
	)
	_expect(not runtime.is_camera_shake_active(), "Shake bitişi runtime state'i temizlemiyor")


func _test_camera_shake_setting_clear() -> void:
	var runtime := VexPlayerImpactFeedbackRuntime.new()
	var base := Vector2(-0.3, 0.4)
	runtime.request_camera_shake(0.5, 1.0, base)
	var cleared := runtime.update_camera_shake(0.1, false)
	_expect(bool(cleared.get("apply_offset", false)), "Screen shake kapatılınca base offset uygulanmıyor")
	_expect(not bool(cleared.get("active", true)), "Screen shake kapatılınca runtime aktif kalıyor")
	_expect_vector2(
		cleared.get("camera_offset", Vector2.ZERO) as Vector2,
		base,
		0.0001,
		"Screen shake kapatılınca kamera base offsetine dönmüyor"
	)


func _test_impact_shock_plan() -> void:
	var runtime := VexPlayerImpactFeedbackRuntime.new()
	var rejected := runtime.begin_impact_shock(0.0, 0.2)
	_expect(not bool(rejected.get("accepted", true)), "Sıfır alpha impact shock kabul ediliyor")

	var first := runtime.begin_impact_shock(2.0, 0.01)
	_expect(bool(first.get("accepted", false)), "Geçerli impact shock reddediliyor")
	_expect_close(float(first.get("peak_alpha", 0.0)), 0.75, 0.0001, "Impact alpha clamp değişti")
	_expect_close(float(first.get("rise_duration", 0.0)), 0.0125, 0.0001, "Minimum shock rise süresi değişti")
	_expect_close(float(first.get("fade_duration", 0.0)), 0.0375, 0.0001, "Minimum shock fade süresi değişti")
	var first_generation := int(first.get("generation", 0))
	_expect(
		runtime.is_impact_shock_generation_current(first_generation),
		"İlk shock generation güncel sayılmıyor"
	)

	var second := runtime.begin_impact_shock(0.5, 0.4)
	var second_generation := int(second.get("generation", 0))
	_expect(second_generation == first_generation + 1, "Shock generation artmıyor")
	_expect(
		not runtime.is_impact_shock_generation_current(first_generation),
		"Eski shock generation geçersizleşmiyor"
	)
	_expect(
		runtime.is_impact_shock_generation_current(second_generation),
		"Yeni shock generation güncel değil"
	)
	_expect_close(float(second.get("rise_duration", 0.0)), 0.045, 0.0001, "Shock rise üst sınırı değişti")
	_expect_close(float(second.get("fade_duration", 0.0)), 0.355, 0.0001, "Shock fade hesabı değişti")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		_failures.append("%s: actual=%.6f expected=%.6f" % [message, actual, expected])


func _expect_vector2(actual: Vector2, expected: Vector2, tolerance: float, message: String) -> void:
	if actual.distance_to(expected) > tolerance:
		_failures.append("%s: actual=%s expected=%s" % [message, str(actual), str(expected)])
