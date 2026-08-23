class_name VexExplosiveBarrel
extends StaticBody3D

@export_category("01 - Hasar")
@export_range(1, 500, 1) var health := 35
@export_range(1.0, 12.0, 0.25) var explosion_radius := 4.5
@export_range(1, 200, 1) var maximum_damage := 70
@export_flags_3d_physics var damage_collision_mask := 2 | 4 | 8
@export_range(1, 128, 1) var max_overlap_results := 32

@export_category("02 - Patlama Görseli")
@export_range(0.1, 6.0, 0.05) var explosion_end_scale_multiplier := 2.3
@export_range(0.0, 2.0, 0.01) var explosion_scale_duration := 0.22
@export_range(0.0, 2.0, 0.01) var explosion_fade_duration := 0.28
@export_range(0.0, 2.0, 0.01) var explosion_light_fade_duration := 0.32

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var barrel_visual: Sprite3D = $BarrelVisual
@onready var explosion_visual: Sprite3D = $ExplosionVisual
@onready var explosion_light: OmniLight3D = $ExplosionLight
@onready var explosion_audio: AudioStreamPlayer3D = $ExplosionAudio

var _exploded := false
var _current_health := 0
var _base_explosion_scale := Vector3.ONE


func _ready() -> void:
	_current_health = health
	_base_explosion_scale = explosion_visual.scale
	add_to_group("damageable")


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if _exploded:
		return
	_current_health -= amount
	if _current_health <= 0:
		_explode()


func _explode() -> void:
	_exploded = true
	barrel_visual.visible = false
	explosion_visual.visible = true
	explosion_light.visible = true
	if explosion_audio.stream != null:
		explosion_audio.play()
	collision_shape.set_deferred("disabled", true)
	_apply_area_damage()
	var tween := create_tween().set_parallel(true)
	tween.tween_property(
		explosion_visual,
		"scale",
		_base_explosion_scale * explosion_end_scale_multiplier,
		explosion_scale_duration
	)
	tween.tween_property(explosion_visual, "modulate:a", 0.0, explosion_fade_duration)
	tween.tween_property(explosion_light, "light_energy", 0.0, explosion_light_fade_duration)
	await tween.finished
	if is_inside_tree():
		queue_free()


func _apply_area_damage() -> void:
	var sphere := SphereShape3D.new()
	sphere.radius = explosion_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	query.collision_mask = damage_collision_mask
	query.exclude = [get_rid()]
	query.collide_with_bodies = true
	query.collide_with_areas = true
	var results := get_world_3d().direct_space_state.intersect_shape(query, max_overlap_results)
	var damaged_ids: Dictionary = {}
	for result: Dictionary in results:
		var collider := result.get("collider") as Object
		var target := _resolve_damage_target(collider)
		_apply_damage_to_target(target, damaged_ids)

	# Hareketli CharacterBody3D'ler patlama karesinde fizik sorgusunun sınırında
	# kalırsa bile düşman ve zincir varil hasarı atlanmasın.
	for damageable: Node in get_tree().get_nodes_in_group("damageable"):
		if damageable == self or not (damageable is Node3D):
			continue
		_apply_damage_to_target(damageable as Node3D, damaged_ids)


func _apply_damage_to_target(target: Node3D, damaged_ids: Dictionary) -> void:
	if target == null or target == self or not target.has_method("take_damage"):
		return
	var target_id := target.get_instance_id()
	if damaged_ids.has(target_id):
		return
	var distance := global_position.distance_to(target.global_position)
	if distance > explosion_radius:
		return
	if not _has_explosion_line_of_sight(target):
		return
	damaged_ids[target_id] = true
	var strength := 1.0 - clampf(distance / explosion_radius, 0.0, 1.0)
	var damage := maxi(1, int(round(maximum_damage * strength)))
	target.call("take_damage", damage, target.global_position, self)


func _has_explosion_line_of_sight(target: Node3D) -> bool:
	var origin := global_position + Vector3.UP * 0.35
	var destination := target.global_position + Vector3.UP * 0.55
	var query := PhysicsRayQueryParameters3D.create(origin, destination, 1 | 8, [get_rid()])
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return true
	var collider := result.get("collider") as Object
	return collider == target or (collider is Node and target.is_ancestor_of(collider as Node))


func _resolve_damage_target(collider: Object) -> Node3D:
	if collider is Node3D and collider.has_method("take_damage"):
		return collider as Node3D
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent is Node3D and parent.has_method("take_damage"):
			return parent as Node3D
	return null
