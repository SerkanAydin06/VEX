class_name VexFurniceCarrierDecal
extends Area3D

@export_category("01 - Hasar Alanı")
@export_range(0.5, 6.0, 0.1) var hazard_radius := 2.0
@export_range(0.5, 20.0, 0.1) var lifetime := 6.0
@export_range(0.1, 2.0, 0.05) var damage_tick_interval := 0.5
@export_range(1, 100, 1) var damage_per_tick := 4
@export_range(0.1, 2.0, 0.05) var hazard_height := 0.6

@export_category("02 - Görsel")
@export_range(0.5, 6.0, 0.1) var visual_reference_radius := 2.0
@export_range(0.0, 2.0, 0.05) var fade_duration := 0.65

@onready var visual: AnimatedSprite3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _source: Node = null
var _elapsed := 0.0
var _tick_remaining := 0.0
var _base_visual_scale := Vector3.ONE


func _ready() -> void:
	_configure_shape_and_visual()
	visual.play(&"default")
	_tick_remaining = 0.0


func configure(new_damage_per_tick: int, source: Node) -> void:
	damage_per_tick = maxi(1, new_damage_per_tick)
	_source = source if is_instance_valid(source) else null


func _physics_process(delta: float) -> void:
	_elapsed += delta
	_tick_remaining -= delta
	if _tick_remaining <= 0.0:
		_tick_remaining = maxf(0.05, damage_tick_interval)
		_damage_overlapping_player()

	if _elapsed >= lifetime:
		queue_free()
		return

	if fade_duration > 0.0 and _elapsed >= lifetime - fade_duration:
		var remaining := maxf(0.0, lifetime - _elapsed)
		var alpha := clampf(remaining / fade_duration, 0.0, 1.0)
		var tint := visual.modulate
		tint.a = alpha
		visual.modulate = tint


func _configure_shape_and_visual() -> void:
	var cylinder := collision_shape.shape as CylinderShape3D
	if cylinder != null:
		cylinder.radius = hazard_radius
		cylinder.height = hazard_height
		collision_shape.position.y = hazard_height * 0.5
	_base_visual_scale = visual.scale
	var scale_multiplier := hazard_radius / maxf(visual_reference_radius, 0.01)
	visual.scale = _base_visual_scale * scale_multiplier


func _damage_overlapping_player() -> void:
	var player := GameState.player as Node3D
	if player == null or not is_instance_valid(player):
		return
	if not overlaps_body(player):
		return
	if player.has_method("take_damage"):
		player.call("take_damage", damage_per_tick, player.global_position, _valid_source())


func _valid_source() -> Node:
	if is_instance_valid(_source):
		return _source
	_source = null
	return null
