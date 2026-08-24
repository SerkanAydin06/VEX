class_name VexTerminalMenu
extends CanvasLayer

enum FacilityStatus {
	CLEARED,
	ACTIVE,
	LOCKED,
}

@export_category("Terminal Status Colors")
@export var cleared_color := Color(0.30, 1.0, 0.62, 1.0)
@export var active_color := Color(0.30, 0.90, 1.0, 1.0)
@export var locked_color := Color(1.0, 0.28, 0.16, 1.0)

@onready var terminal_root: Control = %TerminalRoot
@onready var network_summary: Label = %NetworkSummary
@onready var mission_01_button: Button = %Mission01Button
@onready var mission_02_button: Button = %Mission02Button
@onready var mission_03_button: Button = %Mission03Button
@onready var facility_preview: TextureRect = %FacilityPreview
@onready var selected_code: Label = %SelectedCode
@onready var selected_name: Label = %SelectedName
@onready var selected_type: Label = %SelectedType
@onready var status_value: Label = %StatusValue
@onready var briefing_label: Label = %BriefingLabel
@onready var select_button: Button = %SelectButton
@onready var deploy_button: Button = %DeployButton
@onready var close_button: Button = %CloseButton

var _mission_definitions: Array[VexMissionDefinition] = []
var _selected_index := -1
var _allow_selection := false
var _allow_deploy := false
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var buttons := _get_mission_buttons()
	for index in buttons.size():
		buttons[index].pressed.connect(_select_mission.bind(index))
	select_button.pressed.connect(_select_current_operation)
	deploy_button.pressed.connect(_deploy_current_operation)
	close_button.pressed.connect(close_menu)
	if not GameState.hub_mission_changed.is_connected(_on_hub_mission_changed):
		GameState.hub_mission_changed.connect(_on_hub_mission_changed)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	terminal_root.visible = false


func open_terminal(mission_definitions: Array, allow_selection: bool, allow_deploy: bool) -> void:
	_mission_definitions.clear()
	for definition in mission_definitions:
		if definition is VexMissionDefinition:
			_mission_definitions.append(definition as VexMissionDefinition)
	_allow_selection = allow_selection
	_allow_deploy = allow_deploy
	_selected_index = _get_initial_selection_index()
	_was_paused = get_tree().paused
	terminal_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_menu()
	var buttons := _get_mission_buttons()
	if _selected_index >= 0 and _selected_index < buttons.size():
		buttons[_selected_index].grab_focus()
	else:
		close_button.grab_focus()


func close_menu() -> void:
	if not terminal_root.visible:
		return
	terminal_root.visible = false
	get_tree().paused = _was_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _was_paused else Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return terminal_root.visible


func _input(event: InputEvent) -> void:
	if not terminal_root.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_menu()


func _get_initial_selection_index() -> int:
	if _mission_definitions.is_empty():
		return -1
	for index in _mission_definitions.size():
		if _get_status(index) == FacilityStatus.ACTIVE:
			return index
	return _mission_definitions.size() - 1


func _get_mission_buttons() -> Array[Button]:
	var buttons: Array[Button] = [mission_01_button, mission_02_button, mission_03_button]
	return buttons


func _select_mission(index: int) -> void:
	if index < 0 or index >= _mission_definitions.size():
		return
	_selected_index = index
	_refresh_menu()


func _get_status(index: int) -> FacilityStatus:
	if index < 0 or index >= _mission_definitions.size():
		return FacilityStatus.LOCKED
	var definition := _mission_definitions[index]
	if GameState.campaign_stage >= definition.campaign_stage:
		return FacilityStatus.CLEARED
	if definition.campaign_stage == GameState.campaign_stage + 1:
		return FacilityStatus.ACTIVE
	return FacilityStatus.LOCKED


func _get_status_text(status: FacilityStatus) -> String:
	match status:
		FacilityStatus.CLEARED:
			return tr("TERMINAL_STATUS_CLEARED")
		FacilityStatus.ACTIVE:
			return tr("TERMINAL_STATUS_ACTIVE")
		_:
			return tr("TERMINAL_STATUS_LOCKED")


func _get_status_color(status: FacilityStatus) -> Color:
	match status:
		FacilityStatus.CLEARED:
			return cleared_color
		FacilityStatus.ACTIVE:
			return active_color
		_:
			return locked_color


func _refresh_menu() -> void:
	if not terminal_root.visible:
		return
	var cleared_count := 0
	for index in _mission_definitions.size():
		if _get_status(index) == FacilityStatus.CLEARED:
			cleared_count += 1
	network_summary.text = tr("TERMINAL_MENU_CLEARED_COUNT") % [cleared_count, _mission_definitions.size()]

	var buttons := _get_mission_buttons()
	for index in buttons.size():
		var button := buttons[index]
		button.visible = index < _mission_definitions.size()
		if not button.visible:
			continue
		var button_definition := _mission_definitions[index]
		var button_status := _get_status(index)
		button.text = "%s\n%s\n%s" % [
			button_definition.terminal_code,
			tr(button_definition.display_name),
			_get_status_text(button_status),
		]
		button.button_pressed = index == _selected_index
		button.add_theme_color_override("font_color", _get_status_color(button_status))

	if _selected_index < 0 or _selected_index >= _mission_definitions.size():
		_refresh_empty_detail()
		return

	var selected_definition := _mission_definitions[_selected_index]
	var selected_status := _get_status(_selected_index)
	var selected_status_color := _get_status_color(selected_status)
	facility_preview.texture = selected_definition.terminal_preview
	selected_code.text = selected_definition.terminal_code
	selected_name.text = tr(selected_definition.display_name)
	selected_type.text = tr(selected_definition.facility_type)
	status_value.text = _get_status_text(selected_status)
	status_value.add_theme_color_override("font_color", selected_status_color)

	match selected_status:
		FacilityStatus.CLEARED:
			briefing_label.text = "%s\n\n%s" % [
				tr("TERMINAL_MENU_COMPLETED_DETAIL"),
				tr(selected_definition.completion_message),
			]
		FacilityStatus.ACTIVE:
			briefing_label.text = "%s\n\n%s" % [
				tr("TERMINAL_MENU_NEXT_OPERATION"),
				tr(selected_definition.briefing),
			]
		_:
			briefing_label.text = tr("TERMINAL_MENU_LOCKED_DETAIL") % selected_definition.campaign_stage

	var is_active := selected_status == FacilityStatus.ACTIVE
	var is_selected := GameState.hub_selected_mission_path == selected_definition.scene_path
	select_button.visible = _allow_selection and is_active
	select_button.disabled = is_selected
	select_button.text = tr("TERMINAL_MENU_SELECTED") if is_selected else tr("TERMINAL_MENU_SELECT")
	deploy_button.visible = _allow_deploy and is_active
	deploy_button.disabled = not is_selected
	close_button.text = tr("TERMINAL_MENU_CLOSE")


func _refresh_empty_detail() -> void:
	facility_preview.texture = null
	selected_code.text = "B-7"
	selected_name.text = tr("TERMINAL_MENU_ALL_CLEARED")
	selected_type.text = tr("TERMINAL_MENU_NETWORK_IDLE")
	status_value.text = tr("TERMINAL_STATUS_CLEARED")
	status_value.add_theme_color_override("font_color", cleared_color)
	briefing_label.text = tr("TERMINAL_MENU_ALL_CLEARED_DETAIL")
	select_button.visible = false
	deploy_button.visible = false
	close_button.text = tr("TERMINAL_MENU_CLOSE")


func _select_current_operation() -> void:
	if _selected_index < 0 or _selected_index >= _mission_definitions.size():
		return
	if _get_status(_selected_index) != FacilityStatus.ACTIVE:
		return
	var definition := _mission_definitions[_selected_index]
	GameState.select_hub_mission(definition.scene_path, definition.display_name)
	_refresh_menu()
	if deploy_button.visible and not deploy_button.disabled:
		deploy_button.grab_focus()


func _deploy_current_operation() -> void:
	if _selected_index < 0 or _selected_index >= _mission_definitions.size():
		return
	var definition := _mission_definitions[_selected_index]
	if GameState.hub_selected_mission_path != definition.scene_path:
		GameState.select_hub_mission(definition.scene_path, definition.display_name)
	terminal_root.visible = false
	get_tree().paused = false
	if not GameState.deploy_selected_hub_mission():
		terminal_root.visible = true
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_refresh_menu()
		deploy_button.grab_focus()


func _on_hub_mission_changed(_path: String, _label: String) -> void:
	_refresh_menu()


func _on_language_changed(_locale: String) -> void:
	_refresh_menu()
