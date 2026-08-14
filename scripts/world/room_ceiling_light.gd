@tool
class_name VexRoomCeilingLight
extends Node3D

@export_category("Beyaz Oda Işığı")
@export var light_color := Color(0.9, 0.95, 1.0, 1.0):
	set(value):
		light_color = value
		_apply_configuration()
@export_range(0.0, 8.0, 0.05) var light_energy := 2.6:
	set(value):
		light_energy = value
		_apply_configuration()
@export_range(1.0, 20.0, 0.1) var light_range := 7.4:
	set(value):
		light_range = value
		_apply_configuration()
@export_range(5.0, 80.0, 0.5) var cone_angle := 18.0:
	set(value):
		cone_angle = value
		_apply_configuration()
@export_range(0.1, 4.0, 0.05) var cone_attenuation := 1.6:
	set(value):
		cone_attenuation = value
		_apply_configuration()
@export_range(0.0, 4.0, 0.05) var distance_attenuation := 0.35:
	set(value):
		distance_attenuation = value
		_apply_configuration()
@export var shadow_enabled := false:
	set(value):
		shadow_enabled = value
		_apply_configuration()

@export_category("Uzaklık LOD")
@export var distance_fade_enabled := true:
	set(value):
		distance_fade_enabled = value
		_apply_configuration()
@export_range(1.0, 60.0, 0.5) var distance_fade_begin := 18.0:
	set(value):
		distance_fade_begin = value
		_apply_configuration()
@export_range(0.5, 20.0, 0.5) var distance_fade_length := 5.0:
	set(value):
		distance_fade_length = value
		_apply_configuration()

@export_category("Armatür Görseli")
@export_range(0.0005, 0.01, 0.00005) var fixture_pixel_size := 0.00135:
	set(value):
		fixture_pixel_size = value
		_apply_configuration()
@export var fixture_modulate := Color(0.88, 0.92, 0.96, 1.0):
	set(value):
		fixture_modulate = value
		_apply_configuration()


func _ready() -> void:
	_apply_configuration()


func _apply_configuration() -> void:
	if not is_inside_tree():
		return

	var target_light := get_node_or_null("Light") as SpotLight3D
	if target_light != null:
		target_light.light_color = light_color
		target_light.light_energy = light_energy
		target_light.spot_range = light_range
		target_light.spot_angle = cone_angle
		target_light.spot_angle_attenuation = cone_attenuation
		target_light.spot_attenuation = distance_attenuation
		target_light.shadow_enabled = shadow_enabled
		target_light.distance_fade_enabled = distance_fade_enabled
		target_light.distance_fade_begin = distance_fade_begin
		target_light.distance_fade_length = distance_fade_length

	var fixture := get_node_or_null("Fixture") as Sprite3D
	if fixture != null:
		fixture.pixel_size = fixture_pixel_size
		fixture.modulate = fixture_modulate

