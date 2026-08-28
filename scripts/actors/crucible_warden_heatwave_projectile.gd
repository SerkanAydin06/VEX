class_name VexCrucibleWardenHeatwaveProjectile
extends Area3D

@export_category("01 - Uçuş")
@export_range(1.0, 30.0, 0.5) var speed := 8.5
@export_range(0.2, 5.0, 0.05) var lifetime := 1.45
@export_range(0.05, 1.0, 0.01) var collision_radius := 0.32

@export_category("02 - Impact")
@export_range(0.02, 0.5, 0.01) var impact_fade_time := 0.12
@export_range(1.0, 2.0, 0.05) var impact_scale_multiplier := 1.25

@onready var visual: AnimatedSprite3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var heat_light: OmniLight3D = $HeatLight

var _direction := Vector3.FORWARD
var _source: Node = null
var _damage := 18
var _burst_id := 0
var _remaining_lifetime := 0.0
var _active := false
var _impacted := false


func _ready() -> void:
	add_to_group("projectile")
	var sphere := collision_shape.shape as SphereShape3D
	if sphere != null:
		sphere.radius = collision_radius
	visual.play(&"default")
	_remaining_lifetime = lifetime
	body_entered.connect(_on_body_entered)


func launch(
	direction: Vector3,
	source: Node,
	damage: int,
	burst_id: int
) -> void:
	_direction = direction
	_direction.y = 0.0
	if _direction.length_squared() > 0.001:
		_direction = _direction.normalized()
	_source = source
	_damage = maxi(1, damage)
	_burst_id = burst_id
	_active = _direction.length_squared() > 0.001


func _physics_process(delta: float) -> void:
	if not _active or _impacted:
		return
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		_begin_impact()
		return

	var from := global_position
	var to := from + _direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if _source is CollisionObject3D and is_instance_valid(_source):
		exclusions.append((_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask, exclusions)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		global_position = hit.get("position", to)
		_resolve_hit(hit.get("collider") as Node)
		_begin_impact()
		return
	global_position = to


func _on_body_entered(body: Node) -> void:
	if not _active or _impacted or body == _source:
		return
	_resolve_hit(body)
	_begin_impact()


func _resolve_hit(target: Node) -> void:
	if target == null:
		return
	var damage_target := target
	if (
		damage_target != GameState.player
		and damage_target.get_parent() == GameState.player
	):
		damage_target = GameState.player

	if damage_target != GameState.player:
		return

	if (
		_source != null
		and is_instance_valid(_source)
		and _source.has_method("apply_heatwave_projectile_hit")
	):
		_source.call(
			"apply_heatwave_projectile_hit",
			_burst_id,
			damage_target,
			_damage,
			global_position
		)
	elif damage_target.has_method("take_damage"):
		damage_target.call("take_damage", _damage, global_position, _source)


func _begin_impact() -> void:
	if _impacted:
		return
	_impacted = true
	_active = false
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		visual,
		"scale",
		visual.scale * impact_scale_multiplier,
		impact_fade_time
	)
	tween.tween_property(visual, "modulate:a", 0.0, impact_fade_time)
	if heat_light != null:
		tween.tween_property(heat_light, "light_energy", 0.0, impact_fade_time)
	await tween.finished
	if is_inside_tree():
		queue_free()
