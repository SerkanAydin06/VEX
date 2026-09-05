class_name VexCrucibleWardenHeatwaveProjectile
extends Area3D

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")

@export_category("01 - Uçuş")
@export_range(1.0, 30.0, 0.5) var speed := 8.5
@export_range(0.2, 5.0, 0.05) var lifetime := 1.45
@export_range(0.05, 1.0, 0.01) var collision_radius := 0.20

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
var _lifecycle_generation := 0
var _base_visual_scale := Vector3.ONE
var _base_visual_modulate := Color.WHITE
var _base_light_energy := 0.0


func _ready() -> void:
	add_to_group("projectile")
	var sphere := collision_shape.shape as SphereShape3D
	if sphere != null:
		sphere.radius = collision_radius
	_base_visual_scale = visual.scale
	_base_visual_modulate = visual.modulate
	_base_light_energy = heat_light.light_energy if heat_light != null else 0.0
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	activate_from_pool()


func activate_from_pool() -> void:
	_lifecycle_generation += 1
	_direction = Vector3.FORWARD
	_source = null
	_damage = 18
	_burst_id = 0
	_remaining_lifetime = lifetime
	_active = true
	_impacted = false
	visible = true
	set_physics_process(true)
	set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)
	visual.visible = true
	visual.scale = _base_visual_scale
	visual.modulate = _base_visual_modulate
	visual.frame = 0
	visual.play(&"default")
	if heat_light != null:
		heat_light.visible = true
		heat_light.light_energy = _base_light_energy


func deactivate_for_pool() -> void:
	_lifecycle_generation += 1
	_active = false
	_impacted = false
	_source = null
	_direction = Vector3.FORWARD
	set_physics_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.stop()
	visual.visible = false
	if heat_light != null:
		heat_light.visible = false
		heat_light.light_energy = 0.0
	visible = false


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
	_source = source if is_instance_valid(source) else null
	_damage = maxi(1, damage)
	_burst_id = burst_id
	_remaining_lifetime = lifetime
	_active = _direction.length_squared() > 0.001
	_impacted = false


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
	var damage_source := _valid_source()
	if damage_source is CollisionObject3D:
		exclusions.append((damage_source as CollisionObject3D).get_rid())
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
	if not _active or _impacted:
		return
	var damage_source := _valid_source()
	if body == damage_source:
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

	var damage_source := _valid_source()
	if (
		damage_source != null
		and damage_source.has_method("apply_heatwave_projectile_hit")
	):
		damage_source.call(
			"apply_heatwave_projectile_hit",
			_burst_id,
			damage_target,
			_damage,
			global_position
		)
	elif damage_target.has_method("take_damage"):
		damage_target.call("take_damage", _damage, global_position, damage_source)


func _valid_source() -> Node:
	if is_instance_valid(_source):
		return _source
	_source = null
	return null


func _begin_impact() -> void:
	if _impacted:
		return
	var generation := _lifecycle_generation
	_impacted = true
	_active = false
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(
		visual,
		"scale",
		_base_visual_scale * impact_scale_multiplier,
		impact_fade_time
	)
	tween.tween_property(visual, "modulate:a", 0.0, impact_fade_time)
	if heat_light != null:
		tween.tween_property(heat_light, "light_energy", 0.0, impact_fade_time)
	await tween.finished
	if is_inside_tree() and generation == _lifecycle_generation:
		_recycle_or_free()


func _recycle_or_free() -> void:
	if has_meta("vex_projectile_pool_key"):
		EnemyProjectilePool.recycle(self)
	else:
		queue_free()
