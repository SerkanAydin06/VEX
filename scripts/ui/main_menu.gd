extends Control

@export_category("Playable Build Summary")
@export_range(1, 99, 1) var campaign_level_count := 3
@export_range(0, 99, 1) var campaign_secret_count := 3

@onready var background: TextureRect = %Background
@onready var logo: TextureRect = %Logo
@onready var main_shell: PanelContainer = %MainShell
@onready var menu_buttons: VBoxContainer = %MenuButtons
@onready var new_game_button: Button = %NewGameButton
@onready var continue_button: Button = %ContinueButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var mission_panel: PanelContainer = %MissionPanel
@onready var mission_data: Label = %MissionData
@onready var pulse_line: ColorRect = %PulseLine
@onready var system_clock: Label = %SystemClock
@onready var modal_shade: ColorRect = %ModalShade
@onready var settings_panel: VexSettingsPanel = %SettingsPanel
@onready var credits_panel: PanelContainer = %CreditsPanel
@onready var credits_title: Label = $CreditsPanel/Margin/VBox/Title
@onready var credits_body: Label = $CreditsPanel/Margin/VBox/Body
@onready var credits_close_button: Button = %CreditsCloseButton
@onready var confirm_panel: PanelContainer = %ConfirmPanel
@onready var confirm_body: Label = $ConfirmPanel/Margin/VBox/Body
@onready var confirm_yes_button: Button = %ConfirmYesButton
@onready var confirm_no_button: Button = %ConfirmNoButton
@onready var facility_status_label: Label = $FacilityStatus/VBox/Label
@onready var menu_music: AudioStreamPlayer = $MenuMusic

var _ambient_time := 0.0
var _last_clock_second := -1
var _continue_error_visible := false


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	new_game_button.pressed.connect(_on_new_game_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_open_settings)
	credits_button.pressed.connect(_open_credits)
	quit_button.pressed.connect(_quit_game)
	credits_close_button.pressed.connect(_close_credits)
	confirm_yes_button.pressed.connect(_confirm_new_game)
	confirm_no_button.pressed.connect(_close_confirmation)
	settings_panel.close_requested.connect(_on_settings_closed)
	SettingsManager.difficulty_changed.connect(_update_mission_data)
	SettingsManager.language_changed.connect(_on_language_changed)
	continue_button.visible = true
	continue_button.disabled = not GameState.has_save()
	background.position = Vector2.ZERO
	background.scale = Vector2.ONE
	_update_clock(true)
	_update_mission_data(SettingsManager.difficulty)
	_refresh_localized_dynamic_text()
	_start_menu_music()
	_play_intro()
	new_game_button.grab_focus()

func _input(event: InputEvent) -> void:
	if settings_panel.visible and settings_panel.is_capturing_key_input():
		return
	if event is InputEventKey:
		var key_event := event as InputEventKey

		if (
			key_event.pressed
			and (
				key_event.keycode == KEY_TAB
				or key_event.physical_keycode == KEY_TAB
			)
		):
			get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_ambient_time += delta
	# Arka planı sabit tut. Önceki sürümde her kare küçük ondalıklı
	# position kaydırmaları ve intro zoom tween'i, tam ekran texture'da
	# kayma/titreme/bozulma etkisi yapıyordu.
	background.position = Vector2.ZERO
	background.scale = Vector2.ONE
	pulse_line.modulate.a = 0.5 + sin(_ambient_time * 2.15) * 0.35
	_update_clock(false)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if settings_panel.visible:
		settings_panel.hide_panel()
	elif credits_panel.visible:
		_close_credits()
	elif confirm_panel.visible:
		_close_confirmation()


func _on_new_game_pressed() -> void:
	if GameState.has_save():
		_show_modal(confirm_panel)
		confirm_no_button.grab_focus()
	else:
		GameState.start_new_game()


func _on_continue_pressed() -> void:
	if GameState.continue_game():
		return
	_continue_error_visible = true
	continue_button.disabled = true
	_update_mission_data(SettingsManager.difficulty)
	continue_button.grab_focus()


func _confirm_new_game() -> void:
	_hide_all_modals()
	GameState.start_new_game()


func _close_confirmation() -> void:
	_hide_all_modals()
	new_game_button.grab_focus()


func _open_settings() -> void:
	modal_shade.visible = true
	settings_panel.show_panel()


func _on_settings_closed() -> void:
	modal_shade.visible = false
	settings_button.grab_focus()


func _open_credits() -> void:
	_show_modal(credits_panel)
	credits_close_button.grab_focus()


func _close_credits() -> void:
	_hide_all_modals()
	credits_button.grab_focus()


func _quit_game() -> void:
	get_tree().quit()


func _show_modal(panel: Control) -> void:
	modal_shade.visible = true
	panel.visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.97, 0.97)
	panel.pivot_offset = panel.size * 0.5
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.16)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _hide_all_modals() -> void:
	modal_shade.visible = false
	settings_panel.visible = false
	credits_panel.visible = false
	confirm_panel.visible = false


func _play_intro() -> void:
	logo.modulate.a = 0.0
	main_shell.modulate.a = 0.0
	mission_panel.modulate.a = 0.0
	var shell_position := main_shell.position
	var mission_position := mission_panel.position
	main_shell.position.x -= 46.0
	mission_panel.position.x += 36.0
	background.pivot_offset = Vector2.ZERO
	background.position = Vector2.ZERO
	background.scale = Vector2.ONE
	var tween := create_tween().set_parallel(true)
	tween.tween_property(logo, "modulate:a", 1.0, 0.5).set_delay(0.08)
	tween.tween_property(main_shell, "position", shell_position, 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.12)
	tween.tween_property(main_shell, "modulate:a", 1.0, 0.32).set_delay(0.12)
	tween.tween_property(mission_panel, "position", mission_position, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT).set_delay(0.22)
	tween.tween_property(mission_panel, "modulate:a", 1.0, 0.36).set_delay(0.22)


func _update_clock(force: bool) -> void:
	var now := Time.get_time_dict_from_system()
	var second := int(now.get("second", 0))
	if not force and second == _last_clock_second:
		return
	_last_clock_second = second
	system_clock.text = "%02d:%02d:%02d" % [
		int(now.get("hour", 0)),
		int(now.get("minute", 0)),
		second,
	]


func _update_mission_data(_difficulty: int) -> void:
	if _continue_error_visible:
		mission_data.text = GameState.get_continue_failure_message()
		return
	mission_data.text = tr("MAIN_MISSION_DATA") % [
		campaign_level_count,
		campaign_secret_count,
		SettingsManager.get_difficulty_display_name(),
	]


func _on_language_changed(_locale: String) -> void:
	_update_mission_data(SettingsManager.difficulty)
	_refresh_localized_dynamic_text()


func _refresh_localized_dynamic_text() -> void:
	credits_title.text = tr("CAMPAIGN_PROTOCOL_TITLE")
	credits_body.text = tr("CAMPAIGN_ARCHIVE_BODY").replace("\\n", "\n")
	confirm_body.text = tr("CAMPAIGN_NEW_GAME_CONFIRM")
	facility_status_label.text = tr("CH01_NAME")


func _start_menu_music() -> void:
	if menu_music.stream == null:
		return
	if not menu_music.finished.is_connected(_restart_menu_music):
		menu_music.finished.connect(_restart_menu_music)
	menu_music.play()


func _restart_menu_music() -> void:
	if is_inside_tree() and menu_music.stream != null:
		menu_music.play()
