class_name VexFinishSwitch
extends Node3D

@export_category("Bitiş Kontrolü")
@export var display_name := "TAHLİYE KONTROLÜ"
@export var required_keys: Array[StringName] = [&"blue", &"red"]
@export var required_enemy_id: StringName = &""
@export_file("*.tscn") var next_level_path := ""

@export_category("Finish Switch Görseli")
# Eski Sprite3D tabanlı finish switch ile sahne override uyumluluğu için tutulur.
@export var visual_world_size := Vector2(1.0, 1.0)
@export var activated_modulate := Color(0.55, 0.65, 0.55, 1.0)
@export var screen_tint := Color(0.12, 0.72, 1.0, 1.0)
@export var accent_tint := Color(1.0, 0.34, 0.06, 1.0)
@export var ready_tint := Color(0.18, 1.0, 0.52, 1.0)
@export var active_tint := Color(0.24, 1.0, 0.72, 1.0)
@export_range(0.0, 180.0, 1.0) var rotor_speed_degrees := 34.0
@export_range(0.5, 5.0, 0.1) var idle_pulse_speed := 2.1

@onready var _screen: MeshInstance3D = $VisualConsole/Screen
@onready var _accent_strip: MeshInstance3D = $VisualConsole/AccentStrip
@onready var _status_left: MeshInstance3D = $VisualConsole/StatusLeft
@onready var _status_right: MeshInstance3D = $VisualConsole/StatusRight
@onready var _status_rotor: Node3D = $VisualConsole/StatusRotor
@onready var _ready_core: MeshInstance3D = $VisualConsole/StatusRotor/ReadyCore
@onready var _lever_pivot: Node3D = $VisualConsole/LeverPivot
@onready var _header_label: Label3D = $VisualConsole/HeaderLabel
@onready var _screen_label: Label3D = $VisualConsole/ScreenLabel
@onready var _status_label: Label3D = $VisualConsole/StatusLabel
@onready var _footer_label: Label3D = $VisualConsole/FooterLabel
@onready var _screen_glow: OmniLight3D = $VisualConsole/ScreenGlow
@onready var _accent_glow: OmniLight3D = $VisualConsole/AccentGlow

var _used := false
var _visual_ready := true
var _pulse_phase := 0.0


func _ready() -> void:
	add_to_group("interactable")
	_prepare_console_materials()
	_refresh_console_text()
	_set_visual_access_state(required_keys.is_empty() and required_enemy_id == &"")
	set_process(true)


func _process(delta: float) -> void:
	if _used:
		return
	_pulse_phase += delta * idle_pulse_speed
	_status_rotor.rotation.z += deg_to_rad(rotor_speed_degrees) * delta
	var pulse := (sin(_pulse_phase) + 1.0) * 0.5
	_ready_core.scale = Vector3.ONE * lerpf(0.94, 1.08, pulse)
	_screen_glow.light_energy = lerpf(0.58, 0.92, pulse)
	_accent_glow.light_energy = lerpf(0.34, 0.62, 1.0 - pulse)
	_status_label.modulate.a = lerpf(0.76, 1.0, pulse)


func get_interaction_text(player: Node) -> String:
	if _used:
		return ""
	if not _player_has_all_keys(player):
		_set_visual_access_state(false)
		return tr("INTERACT_REQUIRED") % [_resolved_display_name(), _get_required_key_label()]
	if required_enemy_id != &"" and not GameState.was_enemy_defeated(required_enemy_id):
		_set_visual_access_state(false)
		return tr("FINISH_GUARD_ACTIVE") % _resolved_display_name()
	_set_visual_access_state(true)
	return tr("FINISH_ACTIVATE")


func interact(player: Node) -> void:
	if _used:
		return
	if not _player_has_all_keys(player):
		_set_visual_access_state(false)
		GameState.notify(tr("FINISH_LOCKED_REQUIRED") % _get_required_key_label())
		return
	if required_enemy_id != &"" and not GameState.was_enemy_defeated(required_enemy_id):
		_set_visual_access_state(false)
		GameState.notify(tr("FINISH_LOCKED_GUARD"))
		GameState.set_objective("FINISH_OBJECTIVE_GUARD")
		return

	_used = true
	set_process(false)
	_play_activation_visual()
	GameState.notify(tr("FINISH_ACTIVATED"))
	GameState.call_deferred("complete_level", next_level_path)


func _player_has_all_keys(player: Node) -> bool:
	if player == null or not player.has_method("has_key"):
		return false
	for key_id: StringName in required_keys:
		if not bool(player.call("has_key", key_id)):
			return false
	return true


func _prepare_console_materials() -> void:
	_set_emissive_mesh(_screen, screen_tint, 2.8)
	_set_emissive_mesh(_accent_strip, accent_tint, 2.2)
	_set_emissive_mesh(_status_left, Color(1.0, 0.12, 0.06, 1.0), 2.4)
	_set_emissive_mesh(_status_right, ready_tint, 2.7)
	_set_emissive_mesh(_ready_core, ready_tint, 2.9)
	_screen_glow.light_color = screen_tint
	_accent_glow.light_color = accent_tint


func _set_emissive_mesh(mesh: MeshInstance3D, color: Color, energy: float) -> void:
	if mesh == null:
		return
	var material := mesh.material_override as StandardMaterial3D
	if material == null:
		return
	var local_material := material.duplicate() as StandardMaterial3D
	if local_material == null:
		return
	local_material.albedo_color = Color(
		color.r * 0.22,
		color.g * 0.22,
		color.b * 0.22,
		1.0
	)
	local_material.emission_enabled = true
	local_material.emission = color
	local_material.emission_energy_multiplier = energy
	mesh.material_override = local_material


func _set_visual_access_state(is_ready: bool) -> void:
	if _used or _visual_ready == is_ready:
		return
	_visual_ready = is_ready
	if is_ready:
		_status_label.text = _localized_device_text("SİSTEM HAZIR", "SYSTEM READY")
		_status_label.modulate = ready_tint
		_set_emissive_mesh(_status_right, ready_tint, 2.7)
		_set_emissive_mesh(_ready_core, ready_tint, 2.9)
		_screen_glow.light_color = screen_tint
	else:
		_status_label.text = _localized_device_text("YETKİ BEKLENİYOR", "CLEARANCE REQUIRED")
		_status_label.modulate = Color(1.0, 0.38, 0.16, 1.0)
		_set_emissive_mesh(_status_right, Color(1.0, 0.2, 0.08, 1.0), 2.2)
		_set_emissive_mesh(_ready_core, Color(1.0, 0.2, 0.08, 1.0), 2.4)
		_screen_glow.light_color = Color(1.0, 0.24, 0.08, 1.0)


func _play_activation_visual() -> void:
	_visual_ready = true
	_status_label.text = _localized_device_text("BAĞLANTI AKTİF", "LINK ACTIVE")
	_status_label.modulate = active_tint
	_footer_label.text = _localized_device_text("TAHLİYE ONAYLANDI", "EXTRACTION CONFIRMED")
	_set_emissive_mesh(_status_right, active_tint, 3.4)
	_set_emissive_mesh(_ready_core, active_tint, 3.7)
	_set_emissive_mesh(_screen, active_tint, 3.1)
	_screen_glow.light_color = active_tint
	_accent_glow.light_color = active_tint

	var activation_tween := create_tween().set_parallel(true)
	activation_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	activation_tween.tween_property(_lever_pivot, "rotation_degrees:x", 48.0, 0.24)
	activation_tween.tween_property(
		_status_rotor,
		"rotation_degrees:z",
		_status_rotor.rotation_degrees.z + 180.0,
		0.36
	)
	activation_tween.tween_property(_ready_core, "scale", Vector3(1.34, 1.34, 1.34), 0.16)
	activation_tween.tween_property(_screen_glow, "light_energy", 1.65, 0.18)
	activation_tween.tween_property(_accent_glow, "light_energy", 1.0, 0.18)
	activation_tween.chain().tween_property(_ready_core, "scale", Vector3.ONE, 0.18)


func _refresh_console_text() -> void:
	_header_label.text = _localized_device_text("VEX // KONTROL", "VEX // CONTROL")
	var screen_text := _resolved_display_name().to_upper()
	_screen_label.text = screen_text
	if screen_text.length() > 28:
		_screen_label.font_size = 17
	elif screen_text.length() > 22:
		_screen_label.font_size = 19
	else:
		_screen_label.font_size = 22
	_status_label.text = _localized_device_text("SİSTEM HAZIR", "SYSTEM READY")
	_footer_label.text = _localized_device_text("MANUEL BAĞLANTI // BEKLEMEDE", "MANUAL LINK // STANDBY")


func _resolved_display_name() -> String:
	if display_name == "TAHLİYE KONTROLÜ":
		return _localized_device_text("TAHLİYE KONTROLÜ", "EVACUATION CONTROL")
	return tr(display_name)


func _localized_device_text(tr_text: String, en_text: String) -> String:
	return en_text if TranslationServer.get_locale().to_lower().begins_with("en") else tr_text


func _get_required_key_label() -> String:
	var labels: Array[String] = []
	for key_id: StringName in required_keys:
		match key_id:
			&"blue":
				labels.append(tr("KEY_BLUE"))
			&"red":
				labels.append(tr("KEY_RED"))
			&"yellow":
				labels.append(tr("KEY_YELLOW"))
			_:
				labels.append(String(key_id).to_upper())
	return " + ".join(labels)
