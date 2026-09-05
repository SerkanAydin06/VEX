class_name VexBriarSkulkerProjectile
extends Area3D

@export_category("01 - Uçuş")
## Diken küresinin doğrusal uçuş hızıdır (metre/saniye).
@export_range(1.0, 40.0, 0.5) var speed := 15.0
## Hedefe çarpmazsa otomatik silineceği süredir (saniye).
@export_range(0.2, 10.0, 0.1) var lifetime := 4.0
## Uçuş sırasında görselin kendi çevresindeki dönüş hızıdır (derece/saniye).
@export_range(0.0, 1080.0, 5.0) var spin_speed_degrees := 420.0
## Çarpma görselini yüzeyden ayıran küçük mesafedir (metre).
@export_range(0.0, 0.5, 0.01) var impact_surface_offset := 0.08

@export_category("02 - Çarpma Görseli")
## Çarpma anında diken küresinin ulaşacağı ölçek çarpanıdır.
@export_range(0.1, 5.0, 0.05) var impact_scale_multiplier := 1.85
## Çarpma ölçeklenmesi ve ışık sönmesinin süresidir (saniye).
@export_range(0.03, 1.5, 0.01) var impact_duration := 0.18
## Uçuş ışığının titreşim genliğidir.
@export_range(0.0, 4.0, 0.05) var light_pulse_amplitude := 0.45
## Uçuş ışığının titreşim hızıdır.
@export_range(0.0, 30.0, 0.1) var light_pulse_speed := 10.0

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual_root: Node3D = $VisualRoot
@onready var projectile_light: OmniLight3D = $Light

var damage := 10
var direction := Vector3.FORWARD
var source: Node = null
var _active := true
var _remaining_lifetime := 0.0
var _pulse_time := 0.0
var _base_light_energy := 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_remaining_lifetime = lifetime
	_base_light_energy = projectile_light.light_energy


func launch(new_direction: Vector3, new_source: Node, new_damage: int) -> void:
	direction = new_direction.normalized()
	source = new_source if is_instance_valid(new_source) else null
	damage = maxi(1, new_damage)
	_active = direction.length_squared() > 0.001


func _process(delta: float) -> void:
	if not _active:
		return
	visual_root.rotate_y(deg_to_rad(spin_speed_degrees) * delta)
	visual_root.rotate_x(deg_to_rad(spin_speed_degrees * 0.37) * delta)
	_pulse_time += delta * light_pulse_speed
	projectile_light.light_energy = (
		_base_light_energy
		+ (sin(_pulse_time) * 0.5 + 0.5) * light_pulse_amplitude
	)


func _physics_process(delta: float) -> void:
	if not _active:
		return
	_remaining_lifetime -= delta
	if _remaining_lifetime <= 0.0:
		queue_free()
		return

	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	var damage_source := _valid_source()
	if damage_source is CollisionObject3D:
		exclusions.append((damage_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		start_position,
		end_position,
		collision_mask,
		exclusions
	)
	query.hit_from_inside = true
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		global_position = end_position
		return

	var hit_position: Vector3 = hit.get("position", end_position)
	var hit_normal: Vector3 = hit.get("normal", -direction)
	if hit_normal.length_squared() <= 0.001:
		hit_normal = -direction
	global_position = hit_position + hit_normal.normalized() * impact_surface_offset
	_apply_damage(hit.get("collider") as Object)
	_begin_impact()


func _on_body_entered(body: Node3D) -> void:
	if not _active:
		return
	var damage_source := _valid_source()
	if body == damage_source:
		return
	_apply_damage(body)
	_begin_impact()


func _apply_damage(collider: Object) -> void:
	var damage_target := _resolve_damage_target(collider)
	if damage_target != null:
		damage_target.call("take_damage", damage, global_position, _valid_source())


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _valid_source() -> Node:
	if is_instance_valid(source):
		return source
	source = null
	return null


func _begin_impact() -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	var target_scale := visual_root.scale * impact_scale_multiplier
	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual_root, "scale", target_scale, impact_duration)
	tween.tween_property(projectile_light, "light_energy", 0.0, impact_duration)
	for child: Node in visual_root.get_children():
		if child is GeometryInstance3D:
			var geometry := child as GeometryInstance3D
			tween.tween_property(geometry, "transparency", 1.0, impact_duration)
	await tween.finished
	if is_inside_tree():
		queue_free()
