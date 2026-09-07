class_name VexLevel01EnvironmentStory
extends Node3D

@export_category("01 - Yapısal Işık Override")
@export var disabled_structure_light_paths: Array[NodePath] = []

@export_category("02 - Final Yarık İzi")
@export var breach_visual_path: NodePath = NodePath("FinalVista/FinalBreachCore")
@export var breach_light_path: NodePath = NodePath("FinalVista/BreachLight")
@export_range(0.1, 6.0, 0.1) var breach_pulse_speed := 1.65
@export_range(0.0, 0.18, 0.005) var breach_scale_pulse := 0.035
@export_range(0.0, 0.6, 0.01) var breach_light_pulse := 0.18

var _breach_visual: Node3D = null
var _breach_light: OmniLight3D = null
var _breach_base_scale := Vector3.ONE
var _breach_base_energy := 0.0
var _pulse_time := 0.0


func _ready() -> void:
	_apply_structure_light_overrides()
	_breach_visual = get_node_or_null(breach_visual_path) as Node3D
	_breach_light = get_node_or_null(breach_light_path) as OmniLight3D
	if _breach_visual != null:
		_breach_base_scale = _breach_visual.scale
	if _breach_light != null:
		_breach_base_energy = _breach_light.light_energy


func _process(delta: float) -> void:
	if _breach_visual == null and _breach_light == null:
		return
	_pulse_time += delta * breach_pulse_speed
	var pulse := sin(_pulse_time) * 0.5 + 0.5
	if _breach_visual != null:
		var scale_factor := 1.0 + pulse * breach_scale_pulse
		_breach_visual.scale = _breach_base_scale * scale_factor
	if _breach_light != null:
		_breach_light.light_energy = _breach_base_energy * (1.0 + pulse * breach_light_pulse)


func _exit_tree() -> void:
	if _breach_visual != null and is_instance_valid(_breach_visual):
		_breach_visual.scale = _breach_base_scale
	if _breach_light != null and is_instance_valid(_breach_light):
		_breach_light.light_energy = _breach_base_energy


func _apply_structure_light_overrides() -> void:
	for light_path: NodePath in disabled_structure_light_paths:
		var light_root := get_node_or_null(light_path) as Node3D
		if light_root == null:
			push_warning("VEX-01 çevresel ışık override hedefi bulunamadı: %s" % light_path)
			continue
		light_root.visible = false
