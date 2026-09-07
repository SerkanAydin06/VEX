class_name VexKeybindPanel
extends PanelContainer

signal close_requested

@onready var rows: VBoxContainer = %Rows
@onready var status_label: Label = %StatusLabel
@onready var reset_button: Button = %ResetButton
@onready var close_button: Button = %CloseButton

const ACTION_LABELS := {
	&"move_forward": "KEYBIND_MOVE_FORWARD", &"move_backward": "KEYBIND_MOVE_BACKWARD",
	&"move_left": "KEYBIND_MOVE_LEFT", &"move_right": "KEYBIND_MOVE_RIGHT",
	&"jump": "KEYBIND_JUMP", &"sprint": "KEYBIND_SPRINT", &"crouch": "KEYBIND_CROUCH",
	&"interact": "KEYBIND_INTERACT", &"reload": "KEYBIND_RELOAD", &"automap": "KEYBIND_AUTOMAP",
	&"night_vision": "KEYBIND_NIGHT_VISION", &"weapon_flashlight": "KEYBIND_WEAPON_FLASHLIGHT",
	&"weapon_1": "KEYBIND_WEAPON_1", &"weapon_2": "KEYBIND_WEAPON_2",
	&"weapon_3": "KEYBIND_WEAPON_3", &"weapon_4": "KEYBIND_WEAPON_4", &"weapon_5": "KEYBIND_WEAPON_5",
}

var _buttons: Dictionary = {}
var _waiting_action: StringName = &""

func _ready() -> void:
	_build_rows()
	reset_button.pressed.connect(_on_reset_pressed)
	close_button.pressed.connect(hide_panel)

func _build_rows() -> void:
	for child in rows.get_children():
		child.queue_free()
	_buttons.clear()
	for action: StringName in SettingsManager.rebindable_actions:
		var row := HBoxContainer.new()
		row.custom_minimum_size = Vector2(0.0, 40.0)
		row.add_theme_constant_override("separation", 10)
		var label := Label.new()
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.text = tr(str(ACTION_LABELS.get(action, str(action))))
		row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(160.0, 38.0)
		button.pressed.connect(_begin_rebind.bind(action))
		row.add_child(button)
		rows.add_child(row)
		_buttons[action] = button
	_refresh_buttons()

func show_panel() -> void:
	_waiting_action = &""
	_build_rows()
	status_label.text = tr("KEYBIND_HINT")
	_refresh_buttons()
	visible = true
	close_button.grab_focus()

func hide_panel() -> void:
	_waiting_action = &""
	visible = false
	close_requested.emit()

func _begin_rebind(action: StringName) -> void:
	_waiting_action = action
	status_label.text = tr("KEYBIND_PRESS_KEY") % tr(str(ACTION_LABELS.get(action, str(action))))

func is_waiting_for_key() -> bool:
	return _waiting_action != &""


func _input(event: InputEvent) -> void:
	if not visible or _waiting_action == &"":
		return
	if event is InputEventKey and event.pressed and not event.echo:
		_capture_key_event(event as InputEventKey)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _waiting_action != &"":
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()


func _capture_key_event(key_event: InputEventKey) -> void:
	if key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE:
		_waiting_action = &""
		status_label.text = tr("KEYBIND_HINT")
		get_viewport().set_input_as_handled()
		return
	var code: Key = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
	if code == KEY_NONE:
		return
	if SettingsManager.rebind_key(_waiting_action, code):
		_waiting_action = &""
		status_label.text = tr("KEYBIND_SAVED")
		_refresh_buttons()
	get_viewport().set_input_as_handled()

func _refresh_buttons() -> void:
	for raw_action: Variant in _buttons.keys():
		var action := StringName(str(raw_action))
		var button := _buttons.get(raw_action) as Button
		if button != null:
			button.text = SettingsManager.get_keybinding_text(action)

func _on_reset_pressed() -> void:
	SettingsManager.reset_keybindings()
	_refresh_buttons()
	status_label.text = tr("KEYBIND_RESET_DONE")
