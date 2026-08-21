class_name VexPauseMenu
extends Control

@onready var menu_panel: PanelContainer = %MenuPanel
@onready var resume_button: Button = %ResumeButton
@onready var checkpoint_button: Button = %CheckpointButton
@onready var settings_button: Button = %SettingsButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var settings_panel: VexSettingsPanel = %SettingsPanel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	resume_button.pressed.connect(close_menu)
	checkpoint_button.pressed.connect(GameState.restart_checkpoint)
	settings_button.pressed.connect(_open_settings)
	main_menu_button.pressed.connect(GameState.return_to_main_menu)
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
