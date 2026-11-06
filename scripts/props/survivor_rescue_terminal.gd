class_name VexSurvivorRescueTerminal
extends StaticBody3D

signal survivor_rescued

@export_category("Survivor Rescue")
@export var display_name_key := "CH03_RESCUE_UNIT"
@export var interact_key := "CH03_RESCUE_INTERACT"
@export var rescued_message_key := "CH03_RESCUE_COMPLETE"
@export var objective_after_rescue := "CH03_OBJECTIVE_EVAC"
@export var rescued_light_color := Color(0.35, 1.0, 0.58, 1.0)

@onready var status_light: OmniLight3D = %StatusLight
@onready var status_label: Label3D = %StatusLabel
@onready var unit_label: Label3D = %UnitLabel
@onready var accent_strip: MeshInstance3D = %AccentStrip

var rescued := false


func _ready() -> void:
	add_to_group("interactable")
	if unit_label != null:
		unit_label.text = tr(display_name_key)
	if status_label != null:
		status_label.text = tr("CH03_RESCUE_STATUS_CRITICAL")


func get_interaction_text(_player: Node) -> String:
	if rescued:
		return ""
	return tr(interact_key)


func interact(_player: Node) -> void:
	if rescued:
		return
	rescued = true
	if status_light != null:
		status_light.light_color = rescued_light_color
	if status_label != null:
		status_label.text = tr("CH03_RESCUE_STABLE")
		status_label.modulate = rescued_light_color
	if accent_strip != null:
		var accent := StandardMaterial3D.new()
		accent.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		accent.albedo_color = rescued_light_color
		accent_strip.material_override = accent
	GameState.notify(rescued_message_key)
	GameState.set_objective(objective_after_rescue)
	survivor_rescued.emit()
