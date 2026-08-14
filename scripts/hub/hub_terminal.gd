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

@export_category("Ekran")
@export var active_color := Color(0.32, 0.95, 1.0, 1.0)
@export var offline_color := Color(1.0, 0.20, 0.08, 1.0)

@onready var screen_label: Label3D = $ScreenLabel


func _ready() -> void:
	add_to_group("interactable")
	if not GameState.hub_mission_changed.is_connected(_on_hub_mission_changed):
		GameState.hub_mission_changed.connect(_on_hub_mission_changed)
	call_deferred("_refresh_screen")


func get_interaction_text(_player: Node) -> String:
	if offline:
		return "[E] %s — %s" % [display_name, offline_message]
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			var mission_path := _get_next_mission_path()
			var mission_label := _get_next_mission_label()
			if mission_path.is_empty():
				return "[E] %s — YENİ GÖREV YOK" % display_name
			return "[E] %s // %s" % [display_name, mission_label]
		TerminalMode.DEPLOYMENT:
			if not GameState.has_hub_selected_mission():
				return "[E] %s — GÖREV SEÇİLMEDİ" % display_name
			return "[E] GÖREVE ÇIK // %s" % GameState.get_hub_selected_mission_label()
		_:
			return "[E] %s" % display_name


func interact(_player: Node) -> void:
	if offline:
		GameState.notify("%s — %s" % [display_name, offline_message])
		return
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			GameState.select_hub_mission(_get_next_mission_path(), _get_next_mission_label())
		TerminalMode.DEPLOYMENT:
			GameState.deploy_selected_hub_mission()
		_:
			GameState.notify(info_message)
	_refresh_screen()


func _on_hub_mission_changed(_path: String, _label: String) -> void:
	_refresh_screen()


func _get_hub_scene() -> Node:
	return get_tree().current_scene


func _get_next_mission_path() -> String:
	var hub := _get_hub_scene()
	if hub != null and hub.has_method("get_next_mission_path"):
		return str(hub.call("get_next_mission_path"))
	return ""


func _get_next_mission_label() -> String:
	var hub := _get_hub_scene()
	if hub != null and hub.has_method("get_next_mission_label"):
		return str(hub.call("get_next_mission_label"))
	return "YENİ OPERASYON BEKLENİYOR"


func _refresh_screen() -> void:
	if screen_label == null:
		return
	if offline:
		screen_label.modulate = offline_color
		screen_label.text = "%s\n%s" % [screen_header, offline_message]
		return
	screen_label.modulate = active_color
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			screen_label.text = "%s\nMISSION CONTROL\n%s" % [
				screen_header,
				_get_next_mission_label(),
			]
		TerminalMode.DEPLOYMENT:
			var selected := (
				GameState.get_hub_selected_mission_label()
				if GameState.has_hub_selected_mission()
				else "STANDBY // GÖREV SEÇİLMEDİ"
			)
			screen_label.text = "%s\nDEPLOYMENT\n%s" % [screen_header, selected]
		_:
			screen_label.text = "%s\n%s" % [screen_header, info_message]
