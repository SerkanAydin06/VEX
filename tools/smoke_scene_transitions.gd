## Sahne geçişi duman testi: her bölümü/hub'ı açar, brifingi geçer, ilerler/ateş eder/doldurur,
## oyuncuyu öldürür ve oyun akarken sahneyi değiştirir. Çıktıdaki ERROR/SCRIPT ERROR satırları hatadır.
##   godot --headless --path . -s tools/smoke_scene_transitions.gd
## Not: user:// kayıtlarına yazabilir; depo yerine geçici bir kopyada çalıştır.
extends SceneTree

const SCENES := [
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/hub/bastion_7.tscn",
	"res://scenes/levels/level_test.tscn",
]


func _initialize() -> void:
	_run()


func _wait(seconds: float) -> void:
	var elapsed := 0.0
	while elapsed < seconds:
		await process_frame
		elapsed += 1.0 / 60.0


func _tap(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _run() -> void:
	for path: String in SCENES:
		print("SMOKE ", path)
		change_scene_to_file(path)
		await _wait(1.0)
		for _i: int in range(4):
			await _tap(KEY_SPACE)
			await _wait(0.6)
		for _step: int in range(6):
			Input.action_press("move_forward")
			Input.action_press("fire")
			await _wait(0.5)
			Input.action_release("fire")
			Input.action_release("move_forward")
			await _tap(KEY_R)
			await _wait(0.3)
		var player: Variant = root.get_node("GameState").get("player")
		if is_instance_valid(player) and player.has_method("take_damage"):
			player.call("take_damage", 9999)
		await _wait(1.0)
	change_scene_to_file("res://scenes/ui/main_menu.tscn")
	await _wait(2.0)
	print("SMOKE DONE")
	quit()
