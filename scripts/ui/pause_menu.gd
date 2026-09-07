class_name VexPauseMenu
extends Control

@onready var menu_panel: PanelContainer = %MenuPanel
@onready var resume_button: Button = %ResumeButton
@onready var restart_level_button: Button = %RestartLevelButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var settings_panel: VexSettingsPanel = %SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(close_menu)
	restart_level_button.pressed.connect(GameState.restart_level)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(_return_to_main_menu)
	settings_panel.close_requested.connect(_on_settings_closed)


func open_menu() -> void:
	visible = true
	menu_panel.visible = true
	settings_panel.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	resume_button.grab_focus()


func close_menu() -> void:
	settings_panel.visible = false
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if settings_panel.visible:
			settings_panel.hide_panel()
		else:
			close_menu()


func _open_settings() -> void:
	menu_panel.visible = false
	settings_panel.show_panel()


func _on_settings_closed() -> void:
	menu_panel.visible = true
	settings_button.grab_focus()


func _return_to_main_menu() -> void:
	# Bastion is a free-form safe point. Flush its latest state synchronously
	# before leaving; if disk writing fails, keep the player in Bastion instead of
	# silently discarding the most recent base/loadout changes. Missions never
	# write here, so Pause -> Main Menu still cannot create a mid-level checkpoint.
	var current_scene := get_tree().current_scene
	if (
		current_scene != null
		and current_scene.scene_file_path == GameState.BASTION_7_PATH
		and not GameState.save_current_safe_progress("main_menu_exit")
	):
		GameState.notify(GameState.get_save_failure_message())
		main_menu_button.grab_focus()
		return
	GameState.return_to_main_menu()
