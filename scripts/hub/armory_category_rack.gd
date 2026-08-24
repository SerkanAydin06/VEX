class_name VexArmoryCategoryRack
extends Node3D

@export_category("Kategori")
@export var category_label_key := "ARMORY_GROUP_SIDEARM"

@export_category("İç Aydınlatma")
@export var top_light_color := Color(0.32, 0.86, 1.0, 1.0)
@export_range(0.0, 3.0, 0.05) var top_light_energy := 1.0
@export_range(0.5, 3.0, 0.05) var top_light_range := 1.05

@onready var category_label: Label3D = %CategoryLabel


func _ready() -> void:
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	_apply_scene_settings()


func _apply_scene_settings() -> void:
	category_label.text = tr(category_label_key)
	for light_node: Node in get_tree().get_nodes_in_group("armory_bay_top_light"):
		if not is_ancestor_of(light_node):
			continue
		var light := light_node as SpotLight3D
		if light != null:
			light.light_color = top_light_color
			light.light_energy = top_light_energy
			light.spot_range = top_light_range


func _on_language_changed(_locale: String) -> void:
	_apply_scene_settings()
