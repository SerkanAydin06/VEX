class_name VexHubTerminal
extends Node3D

enum TerminalMode {
	MISSION_CONTROL,
	DEPLOYMENT,
	INFORMATION,
}

@export_category("Terminal")
@export_enum("Mission Control", "Deployment", "Information") var terminal_mode: int = TerminalMode.INFORMATION
@export var display_name := "BASTION TERMİNALİ"
@export var offline := false
@export var offline_message := "POWER OFFLINE"

@onready var offline_overlay: Label3D = $Visuals/ScreenAssembly/OfflineOverlay
@onready var terminal_menu: VexTerminalMenu = $TerminalMenu
@onready var archive_terminal: VexArchiveTerminal = $ArchiveTerminal


func _ready() -> void:
	add_to_group("interactable")
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	_refresh_offline_overlay()


func get_interaction_text(_player: Node) -> String:
	if offline:
		return tr("INTERACT_LOCKED") % [tr(display_name), tr(offline_message)]
	return tr("TERMINAL_INTERACT_OPEN") % tr(display_name)


func interact(_player: Node) -> void:
	if offline:
		GameState.notify(tr("DOOR_LOCKED_MESSAGE") % [tr(display_name), tr(offline_message)])
		return
	if terminal_mode == TerminalMode.INFORMATION:
		archive_terminal.open_terminal()
		return
	terminal_menu.open_terminal(
		_get_mission_definitions(),
		true,
		terminal_mode == TerminalMode.DEPLOYMENT
	)


func _on_language_changed(_locale: String) -> void:
	_refresh_offline_overlay()


func _get_hub_scene() -> Node:
	if not is_inside_tree():
		return null
	var current: Node = self
	while current != null:
		if current.has_method("get_mission_definitions"):
			return current
		current = current.get_parent()
	return null


func _get_mission_definitions() -> Array:
	var hub := _get_hub_scene()
	if hub != null:
		return hub.call("get_mission_definitions") as Array
	return []


func _refresh_offline_overlay() -> void:
	if offline_overlay == null:
		return
	offline_overlay.visible = offline
	offline_overlay.text = tr(offline_message)
