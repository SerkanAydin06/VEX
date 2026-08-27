class_name VexFurniceCarrierProjectile
extends Area3D

@export_category("01 - Uçuş")
@export_range(1.0, 40.0, 0.5) var speed := 14.0
@export_range(0.5, 10.0, 0.1) var lifetime := 5.0
@export_range(0.05, 1.0, 0.01) var collision_radius := 0.22

@export_category("02 - Impact ve Decal")
@export var decal_scene: PackedScene
@export_range(0.0, 0.5, 0.01) var impact_surface_offset := 0.04
@export_flags_3d_physics var ground_collision_mask := 1
@export_range(0.1, 4.0, 0.1) var ground_probe_height := 1.4
@export_range(0.5, 8.0, 0.1) var ground_probe_depth := 3.5
@export_range(0.0, 0.2, 0.01) var decal_surface_offset := 0.03

@onready var projectile_visual: AnimatedSprite3D = $ProjectileVisual
@onready var impact_visual: AnimatedSprite3D = $ImpactVisual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var impact_light: OmniLight3D = $ImpactLight

var _direction := Vector3.FORWARD
var _source: Node = null
var _direct_damage := 18
var _decal_tick_damage := 4
var _remaining_lifetime := 0.0
var _active := false
var _impacted := false


func _ready() -> void:
	var sphere := collision_shape.shape as SphereShape3D
	if sphere != null:
		sphere.radius = collision_radius
	projectile_visual.play(&"default")
	impact_visual.visible = false
	impact_light.visible = false
	_remaining_lifetime = lifetime
	body_entered.connect(_on_body_entered)


func launch(direction: Vector3, source: Node, direct_damage: int, decal_tick_damage: int) -> void:
	_direction = direction.normalized()
	_source = source
	_direct_damage = maxi(1, direct_damage)
	_decal_tick_damage = maxi(1, decal_tick_damage)
	_active = _direction.length_squared() > 0.001


func _physics_process(delta: float) -> void:
	if not _active or _impacted:
		return
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()
		return

	var from := global_position
	var to := from + _direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if _source is CollisionObject3D:
		exclusions.append((_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask, exclusions)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if not hit.is_empty():
		var hit_position: Vector3 = hit.get("position", to)
		var hit_normal: Vector3 = hit.get("normal", Vector3.UP)
		_resolve_direct_hit(hit.get("collider") as Node, hit_position)
		_begin_impact(hit_position + hit_normal * impact_surface_offset)
		return
	global_position = to


func _on_body_entered(body: Node) -> void:
	if not _active or _impacted or body == _source:
		return
	_resolve_direct_hit(body, global_position)
	_begin_impact(global_position)


func _resolve_direct_hit(target: Node, hit_position: Vector3) -> void:
	if target == null:
		return
	var damage_target := target
	if not damage_target.has_method("take_damage") and damage_target.get_parent() != null:
		var parent := damage_target.get_parent()
		if parent.has_method("take_damage"):
			damage_target = parent
	if damage_target == GameState.player and damage_target.has_method("take_damage"):
		damage_target.call("take_damage", _direct_damage, hit_position, _source)


func _begin_impact(impact_position: Vector3) -> void:
	if _impacted:
		return
	_impacted = true
	_active = false
	global_position = impact_position
	collision_shape.set_deferred("disabled", true)
	projectile_visual.visible = false
	_spawn_decal_below(impact_position)
	impact_visual.visible = true
	impact_visual.play(&"default")
	impact_light.visible = true
	var tween := create_tween()
	tween.tween_property(impact_light, "light_energy", 0.0, 0.35)
	await impact_visual.animation_finished
	if is_inside_tree():
		queue_free()


func _spawn_decal_below(impact_position: Vector3) -> void:
	if decal_scene == null or get_tree().current_scene == null:
		return
	var ray_start := impact_position + Vector3.UP * ground_probe_height
	var ray_end := impact_position + Vector3.DOWN * ground_probe_depth
	var exclusions: Array[RID] = [get_rid()]
	if _source is CollisionObject3D:
		exclusions.append((_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(ray_start, ray_end, ground_collision_mask, exclusions)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var decal := decal_scene.instantiate() as Node3D
	if decal == null:
		return
	if decal.has_method("configure"):
		decal.call("configure", _decal_tick_damage, _source)
	get_tree().current_scene.add_child(decal)
	var floor_position: Vector3 = hit.get("position", impact_position)
	var floor_normal: Vector3 = hit.get("normal", Vector3.UP)
	decal.global_position = floor_position + floor_normal * decal_surface_offset
