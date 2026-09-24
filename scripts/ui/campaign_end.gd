extends Control

@onready var continue_button: Button = %ContinueButton
@onready var main_menu_button: Button = %MainMenuButton
@onready var difficulty_value: Label = %DifficultyValue


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = false
	difficulty_value.text = tr(GameState.get_active_difficulty_name())
	continue_button.pressed.connect(_on_continue_pressed)
	main_menu_button.pressed.connect(GameState.return_to_main_menu)
	continue_button.grab_focus()


func _on_continue_pressed() -> void:
	if GameState.continue_to_next_level():
		return
	continue_button.grab_focus()
