class_name VexVenomMarshallProjectile
extends Node3D

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")

@export_range(1.0, 40.0, 0.5) var speed := 16.0
@export_range(0.2, 8.0, 0.1) var lifetime := 4.0
@export_flags_3d_physics var collision_mask := 1 | 2
@export_range(0.05, 2.0, 0.05) var impact_duration := 0.42

@onready var flight_visual: AnimatedSprite3D = $FlightVisual
@onready var impact_visual: AnimatedSprite3D = $ImpactVisual
@onready var light: OmniLight3D = $ProjectileLight

var damage := 10
var direction := Vector3.FORWARD
var source: Node = null
var _remaining := 0.0
var _active := false
var _impacting := false
var _generation := 0


func _ready() -> void:
	activate_from_pool()


func activate_from_pool() -> void:
	_generation += 1
	_active = true
	_impacting = false
	damage = 10
	direction = Vector3.FORWARD
	source = null
	_remaining = lifetime
	visible = true
	set_physics_process(true)
	flight_visual.visible = true
	flight_visual.frame = 0
	flight_visual.play(&"projectile")
	impact_visual.visible = false
	impact_visual.stop()
	light.visible = true


func deactivate_for_pool() -> void:
	_generation += 1
	_active = false
	_impacting = false
	source = null
	set_physics_process(false)
	flight_visual.visible = false
	impact_visual.visible = false
	light.visible = false
	visible = false


func launch(new_direction: Vector3, new_source: Node, new_damage: int) -> void:
	direction = new_direction.normalized()
	source = new_source
	damage = maxi(1, new_damage)


func _physics_process(delta: float) -> void:
	if not _active or _impacting:
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining <= 0.0:
		_begin_impact(global_position, null)
		return

	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = []
	if source is CollisionObject3D and is_instance_valid(source):
		exclusions.append((source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		start_position,
		end_position,
		collision_mask,
		exclusions
	)
	query.hit_from_inside = true
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = end_position
		return

	var hit_position: Vector3 = result.get("position", end_position)
	var target := _resolve_damage_target(result.get("collider") as Object)
	_begin_impact(hit_position, target)


func _begin_impact(hit_position: Vector3, target: Node) -> void:
	if not _active or _impacting:
		return
	_impacting = true
	global_position = hit_position
	if target != null and target.is_in_group("player") and target.has_method("take_damage"):
		var damage_source: Node = source if source != null and is_instance_valid(source) else null
		target.call("take_damage", damage, hit_position, damage_source)

	flight_visual.visible = false
	impact_visual.visible = true
	impact_visual.frame = 0
	impact_visual.play(&"impact")
	light.visible = false
	var impact_generation := _generation
	await get_tree().create_timer(impact_duration).timeout
	if not is_inside_tree() or impact_generation != _generation:
		return
	_recycle_or_free()


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _recycle_or_free() -> void:
	if has_meta("vex_projectile_pool_key"):
		EnemyProjectilePool.recycle(self)
	else:
		queue_free()
