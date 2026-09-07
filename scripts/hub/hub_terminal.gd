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

@export_category("Screen Signal")
@export var screen_motion_enabled := true
@export_range(0.0, 0.08, 0.001) var screen_signal_strength := 0.018
@export_range(0.2, 6.0, 0.1) var screen_signal_speed := 2.2

@onready var offline_overlay: Label3D = $Visuals/ScreenAssembly/OfflineOverlay
@onready var screen_surface: Sprite3D = $Visuals/ScreenAssembly/ScreenSurface
@onready var terminal_menu: VexTerminalMenu = $TerminalMenu
@onready var archive_terminal: VexArchiveTerminal = $ArchiveTerminal

var _screen_base_position := Vector3.ZERO
var _screen_base_pixel_size := 0.0008
var _screen_signal_time := 0.0


func _ready() -> void:
	add_to_group("interactable")
	if screen_surface != null:
		_screen_base_position = screen_surface.position
		_screen_base_pixel_size = screen_surface.pixel_size
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	_refresh_offline_overlay()


func _process(delta: float) -> void:
	if screen_surface == null:
		return
	if offline:
		screen_surface.position = _screen_base_position
		screen_surface.pixel_size = _screen_base_pixel_size
		screen_surface.modulate = Color(0.22, 0.28, 0.30, 1.0)
		return
	if not screen_motion_enabled:
		screen_surface.position = _screen_base_position
		screen_surface.pixel_size = _screen_base_pixel_size
		screen_surface.modulate = Color.WHITE
		return

	_screen_signal_time = fmod(
		_screen_signal_time + delta * screen_signal_speed,
		TAU * 64.0
	)
	var slow_wave := sin(_screen_signal_time)
	var scan_wave := sin(_screen_signal_time * 3.7 + 0.9)
	var signal := clampf(screen_signal_strength, 0.0, 0.08)
	var vertical_drift := slow_wave * signal * 0.06
	var scale_pulse := 1.0 + scan_wave * signal * 0.15
	var brightness := 0.96 + (slow_wave * 0.5 + 0.5) * signal * 1.7
	var cyan_bias := 0.985 + (scan_wave * 0.5 + 0.5) * signal * 0.65

	screen_surface.position = _screen_base_position + Vector3(0.0, vertical_drift, 0.0)
	screen_surface.pixel_size = _screen_base_pixel_size * scale_pulse
	screen_surface.modulate = Color(brightness, cyan_bias, 1.0, 1.0)


func get_interaction_text(_player: Node) -> String:
	var resolved_name := _get_display_name()
	if offline:
		return tr("INTERACT_LOCKED") % [resolved_name, tr(offline_message)]
	return tr("TERMINAL_INTERACT_OPEN") % resolved_name


func interact(_player: Node) -> void:
	if offline:
		GameState.notify(tr("DOOR_LOCKED_MESSAGE") % [_get_display_name(), tr(offline_message)])
		return
	if terminal_mode == TerminalMode.INFORMATION:
		archive_terminal.open_terminal()
		return
	terminal_menu.open_terminal(
		_get_mission_definitions(),
		true,
		terminal_mode == TerminalMode.DEPLOYMENT
	)


func _get_display_name() -> String:
	if terminal_mode == TerminalMode.INFORMATION:
		return "VEX ANA TERMİNALİ" if TranslationServer.get_locale().begins_with("tr") else "VEX MAIN TERMINAL"
	return tr(display_name)


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
