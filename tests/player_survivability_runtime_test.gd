extends Node

var _failures: Array[String] = []


func _ready() -> void:
	_test_initialization_and_pickups()
	_test_damage_absorption_and_feedback_cooldown()
	_test_fully_absorbed_damage()
	_test_lethal_damage_and_restore()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return
	print("PLAYER SURVIVABILITY RUNTIME TEST: OK")
	get_tree().quit(0)


func _test_initialization_and_pickups() -> void:
	var runtime := VexPlayerSurvivabilityRuntime.new()
	runtime.initialize(100, 100, 150, 0.60, 0.90)
	_expect(runtime.get_health() == 100, "Başlangıç health maksimumda değil")
	_expect(runtime.get_armor() == 100, "Başlangıç armor maksimuma clamp edilmiyor")

	runtime.sync_state(70, 80, false)
	var collected_health := runtime.collect_health(50)
	_expect(collected_health == 30, "Health pickup gerçek toplanan miktarı döndürmüyor")
	_expect(runtime.get_health() == 100, "Health pickup maksimumu aşıyor")
	_expect(runtime.collect_health(10) == 0, "Dolu health pickup kabul ediliyor")

	var collected_armor := runtime.collect_armor(50)
	_expect(collected_armor == 20, "Armor pickup gerçek toplanan miktarı döndürmüyor")
	_expect(runtime.get_armor() == 100, "Armor pickup maksimumu aşıyor")
	_expect(runtime.collect_armor(10) == 0, "Dolu armor pickup kabul ediliyor")
	_expect(runtime.collect_health(0) == 0, "Sıfır health pickup kabul ediliyor")
	_expect(runtime.collect_armor(-10) == 0, "Negatif armor pickup kabul ediliyor")


func _test_damage_absorption_and_feedback_cooldown() -> void:
	var runtime := VexPlayerSurvivabilityRuntime.new()
	runtime.initialize(100, 100, 50, 0.60, 0.90)
	var first := runtime.apply_damage(20, true)
	_expect(bool(first.get("applied", false)), "Geçerli hasar uygulanmıyor")
	_expect(int(first.get("absorbed", -1)) == 12, "Armor absorption hesabı değişti")
	_expect(int(first.get("health_damage", -1)) == 8, "Health damage hesabı değişti")
	_expect(runtime.get_armor() == 38, "Armor hasar sonrası yanlış")
	_expect(runtime.get_health() == 92, "Health hasar sonrası yanlış")
	_expect(bool(first.get("play_hurt_feedback", false)), "İlk health damage hurt feedback üretmiyor")
	_expect(not bool(first.get("died", true)), "Öldürücü olmayan hasar death üretiyor")

	var second := runtime.apply_damage(10, true)
	_expect(not bool(second.get("play_hurt_feedback", true)), "Hurt feedback cooldown korunmuyor")
	_expect(runtime.get_hurt_audio_cooldown_remaining() > 0.0, "Hurt feedback cooldown state tutulmuyor")

	runtime.update(0.90)
	var third := runtime.apply_damage(10, true)
	_expect(bool(third.get("play_hurt_feedback", false)), "Cooldown bitince hurt feedback geri açılmıyor")


func _test_fully_absorbed_damage() -> void:
	var runtime := VexPlayerSurvivabilityRuntime.new()
	runtime.initialize(100, 100, 100, 0.60, 0.90)
	var result := runtime.apply_damage(1, true)
	_expect(int(result.get("absorbed", -1)) == 1, "Tek hasar armor tarafından emilmiyor")
	_expect(int(result.get("health_damage", -1)) == 0, "Tam emilen hasar health azaltıyor")
	_expect(runtime.get_health() == 100, "Tam emilen hasar health state'i bozuyor")
	_expect(not bool(result.get("play_hurt_feedback", true)), "Health kaybı yokken hurt feedback çalıyor")


func _test_lethal_damage_and_restore() -> void:
	var runtime := VexPlayerSurvivabilityRuntime.new()
	runtime.initialize(100, 100, 0, 0.60, 0.90)
	runtime.sync_state(10, 0, false)
	var lethal := runtime.apply_damage(20, true)
	_expect(bool(lethal.get("died", false)), "Lethal damage death üretmiyor")
	_expect(runtime.get_health() == 0, "Lethal damage health'i sıfırlamıyor")
	_expect(runtime.get_is_dead(), "Lethal damage dead state'i set etmiyor")

	var ignored := runtime.apply_damage(20, true)
	_expect(not bool(ignored.get("applied", true)), "Dead state sonrası hasar tekrar uygulanıyor")

	runtime.restore_state(0, 999)
	_expect(runtime.get_health() == 1, "Restore health minimum 1'e clamp edilmiyor")
	_expect(runtime.get_armor() == 100, "Restore armor maksimuma clamp edilmiyor")
	_expect(not runtime.get_is_dead(), "Restore dead state'i temizlemiyor")
	_expect_close(
		runtime.get_hurt_audio_cooldown_remaining(),
		0.0,
		0.0001,
		"Restore hurt feedback cooldown'ını temizlemiyor"
	)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _expect_close(actual: float, expected: float, tolerance: float, message: String) -> void:
	if absf(actual - expected) > tolerance:
		_failures.append("%s: actual=%.6f expected=%.6f" % [message, actual, expected])
