extends Control

const MAIN_MENU_SCENE := "res://scenes/ui/main_menu.tscn"

@onready var company_group: Control = %CompanyGroup
@onready var creator_group: Control = %CreatorGroup
@onready var accent_line: ColorRect = %AccentLine

var _sequence_running := true
var _transition_started := false
var _elapsed := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	company_group.modulate.a = 0.0
	creator_group.modulate.a = 0.0
	accent_line.modulate.a = 0.0
	_run_sequence()


func _process(delta: float) -> void:
	_elapsed += delta


func _unhandled_input(event: InputEvent) -> void:
	if _transition_started or _elapsed < 0.35:
		return

	var should_skip := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		should_skip = key_event.pressed and not key_event.echo
	elif event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		should_skip = mouse_event.pressed

	if should_skip:
		_go_to_main_menu()


func _run_sequence() -> void:
	# 1) PARDUS GAMES
	var company_in := create_tween().set_parallel(true)
	company_in.tween_property(company_group, "modulate:a", 1.0, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	company_in.tween_property(accent_line, "modulate:a", 0.8, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await company_in.finished
	await get_tree().create_timer(0.75).timeout
	if _transition_started:
		return

	var company_out := create_tween().set_parallel(true)
	company_out.tween_property(company_group, "modulate:a", 0.0, 0.38)
	company_out.tween_property(accent_line, "modulate:a", 0.0, 0.38)
	await company_out.finished
	if _transition_started:
		return

	await get_tree().create_timer(0.15).timeout
	if _transition_started:
		return

	# 2) A GAME BY / SERKAN AYDIN
	var creator_in := create_tween().set_parallel(true)
	creator_in.tween_property(creator_group, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	creator_in.tween_property(accent_line, "modulate:a", 0.8, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await creator_in.finished
	await get_tree().create_timer(0.90).timeout
	if _transition_started:
		return

	var creator_out := create_tween().set_parallel(true)
	creator_out.tween_property(creator_group, "modulate:a", 0.0, 0.42)
	creator_out.tween_property(accent_line, "modulate:a", 0.0, 0.42)
	await creator_out.finished
	if _transition_started:
		return

	_sequence_running = false
	_go_to_main_menu()


func _go_to_main_menu() -> void:
	if _transition_started:
		return
	_transition_started = true
	_sequence_running = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE)
	if error != OK:
		push_error("Ana menü yüklenemedi: %s" % error_string(error))
