class_name VexHubTerminal
extends StaticBody3D

enum TerminalMode {
	MISSION_CONTROL,
	DEPLOYMENT,
	INFORMATION,
}

@export_category("Terminal")
@export_enum("Mission Control", "Deployment", "Information") var terminal_mode: int = TerminalMode.INFORMATION
@export var display_name := "BASTION TERMİNALİ"
@export_multiline var info_message := "BASTION-7 SİSTEMİ ÇEVRİMİÇİ"
@export var offline := false
@export var offline_message := "POWER OFFLINE"
@export var screen_header := "VEX // BASTION-7"

@export_category("Ekran Metinleri")
@export var mission_control_text := "MISSION CONTROL"
@export var deployment_ready_text := "DEPLOYMENT HAZIR"
@export var operation_text := "OPERASYON"
@export var no_mission_text := "YENİ GÖREV YOK"
@export var mission_waiting_text := "YENİ OPERASYON BEKLENİYOR"
@export var select_operation_text := "OPERASYON SEÇ"
@export var deploy_text := "GÖREVE ÇIK"

@export_category("Ekran")
@export var active_color := Color(0.32, 0.95, 1.0, 1.0)
@export var offline_color := Color(1.0, 0.20, 0.08, 1.0)

@onready var screen_label: Label3D = $ScreenLabel


func _ready() -> void:
	add_to_group("interactable")
	if not GameState.hub_mission_changed.is_connected(_on_hub_mission_changed):
		GameState.hub_mission_changed.connect(_on_hub_mission_changed)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	call_deferred("_refresh_screen")


func get_interaction_text(_player: Node) -> String:
	if offline:
		return tr("INTERACT_LOCKED") % [tr(display_name), tr(offline_message)]
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			var mission_path := _get_next_mission_path()
			var mission_label := _get_next_mission_label()
			if mission_path.is_empty():
				return tr("TERMINAL_INTERACT_STATUS") % [tr(display_name), tr(no_mission_text)]
			return tr("TERMINAL_INTERACT_STATUS") % [tr(display_name), mission_label]
		TerminalMode.DEPLOYMENT:
			if not GameState.has_hub_selected_mission():
				var mission_path := _get_next_mission_path()
				if mission_path.is_empty():
					return tr("TERMINAL_INTERACT_STATUS") % [tr(display_name), tr(no_mission_text)]
				return tr("TERMINAL_INTERACT_STATUS") % [tr(select_operation_text), _get_next_mission_label()]
			return tr("TERMINAL_INTERACT_STATUS") % [tr(deploy_text), tr(GameState.get_hub_selected_mission_label())]
		_:
			return tr("TERMINAL_INTERACT") % tr(display_name)


func interact(_player: Node) -> void:
	if offline:
		GameState.notify(tr("DOOR_LOCKED_MESSAGE") % [tr(display_name), tr(offline_message)])
		return
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			GameState.select_hub_mission(_get_next_mission_path(), _get_next_mission_label())
			GameState.notify(_get_next_mission_briefing())
		TerminalMode.DEPLOYMENT:
			if GameState.has_hub_selected_mission():
				GameState.deploy_selected_hub_mission()
				return
			GameState.select_hub_mission(_get_next_mission_path(), _get_next_mission_label())
			GameState.notify(_get_next_mission_briefing())
		_:
			GameState.notify(tr(info_message))
	if is_inside_tree():
		_refresh_screen()


func _on_hub_mission_changed(_path: String, _label: String) -> void:
	if not is_inside_tree():
		return
	_refresh_screen()


func _on_language_changed(_locale: String) -> void:
	_refresh_screen()


func _get_hub_scene() -> Node:
	if not is_inside_tree():
		return null
	var current: Node = self
	while current != null:
		if current.has_method("get_next_mission_path") and current.has_method("get_next_mission_label"):
			return current
		current = current.get_parent()
	return null


func _get_next_mission_path() -> String:
	var hub := _get_hub_scene()
	if hub != null and hub.has_method("get_next_mission_path"):
		return str(hub.call("get_next_mission_path"))
	return ""


func _get_next_mission_label() -> String:
	var hub := _get_hub_scene()
	if hub != null and hub.has_method("get_next_mission_label"):
		return str(hub.call("get_next_mission_label"))
	return tr(mission_waiting_text)


func _get_next_mission_briefing() -> String:
	var hub := _get_hub_scene()
	if hub != null and hub.has_method("get_next_mission_briefing"):
		return str(hub.call("get_next_mission_briefing"))
	return tr("MISSION_BRIEFING_UNAVAILABLE")


func _refresh_screen() -> void:
	if not is_inside_tree() or screen_label == null:
		return
	if offline:
		screen_label.modulate = offline_color
		screen_label.text = "%s\n%s" % [tr(screen_header), tr(offline_message)]
		return
	screen_label.modulate = active_color
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			screen_label.text = "%s\n%s\n%s" % [
				tr(screen_header),
				tr(mission_control_text),
				_get_next_mission_label(),
			]
		TerminalMode.DEPLOYMENT:
			if GameState.has_hub_selected_mission():
				screen_label.text = "%s\n%s\n%s" % [
					tr(screen_header),
					tr(deployment_ready_text),
					tr(GameState.get_hub_selected_mission_label()),
				]
			else:
				screen_label.text = "%s\n%s\n%s" % [
					tr(screen_header),
					tr(operation_text),
					_get_next_mission_label(),
				]

		_:
			screen_label.text = "%s\n%s" % [tr(screen_header), tr(info_message)]
