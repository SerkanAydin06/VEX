class_name VexRavagerProjectile
extends Area3D

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")

@export_category("01 - Uçuş")
@export_range(1.0, 40.0, 0.5) var speed := 11.0
@export_range(0.2, 10.0, 0.1) var lifetime := 4.0
@export_range(0.0, 1.0, 0.01) var impact_surface_offset := 0.32
@export_range(0.0, 0.2, 0.01) var player_impact_surface_offset := 0.04

@export_category("02 - Işık")
@export_range(0.0, 6.0, 0.05) var light_pulse_amplitude := 0.32
@export_range(0.0, 20.0, 0.1) var light_pulse_speed := 8.0
@export_range(0.0, 8.0, 0.05) var impact_light_energy := 4.4
@export_range(0.0, 2.0, 0.01) var impact_light_fade_duration := 0.26

@export_category("03 - Impact Animasyonu")
@export_range(0.05, 3.0, 0.01) var impact_start_scale_multiplier := 0.92
@export_range(0.05, 4.0, 0.01) var impact_end_scale_multiplier := 1.08
@export_range(0.0, 2.0, 0.01) var impact_scale_duration := 0.22
@export_range(0.0, 2.0, 0.01) var impact_fade_delay := 0.14
@export_range(0.0, 2.0, 0.01) var impact_fade_duration := 0.12

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: SpriteBase3D = $Visual
@onready var impact_visual: SpriteBase3D = $ImpactVisual
@onready var projectile_light: OmniLight3D = $Light
@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio

var damage := 10
var direction := Vector3.FORWARD
var source: Node = null
var _active := false
var _base_light_energy := 0.0
var _base_impact_scale := Vector3.ONE
var _base_impact_modulate := Color.WHITE
var _pulse_time := 0.0
var _lifecycle_generation := 0


func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	_base_light_energy = projectile_light.light_energy
	_base_impact_scale = impact_visual.scale
	_base_impact_modulate = impact_visual.modulate
	activate_from_pool()


func activate_from_pool() -> void:
	_lifecycle_generation += 1
	var generation := _lifecycle_generation
	_active = true
	direction = Vector3.FORWARD
	source = null
	damage = 10
	_pulse_time = 0.0
	visible = true
	set_process(true)
	set_physics_process(true)
	set_deferred("monitoring", true)
	collision_shape.set_deferred("disabled", false)
	visual.visible = true
	impact_visual.visible = false
	impact_visual.modulate = _base_impact_modulate
	impact_visual.scale = _base_impact_scale
	projectile_light.light_energy = _base_light_energy
	if impact_audio.playing:
		impact_audio.stop()
	if visual is AnimatedSprite3D:
		var animated_visual := visual as AnimatedSprite3D
		animated_visual.frame = 0
		animated_visual.play(&"default")
	if impact_visual is AnimatedSprite3D:
		var animated_impact := impact_visual as AnimatedSprite3D
		animated_impact.stop()
		animated_impact.frame = 0
	_expire_later(generation)


func deactivate_for_pool() -> void:
	_lifecycle_generation += 1
	_active = false
	source = null
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.visible = false
	impact_visual.visible = false
	projectile_light.light_energy = 0.0
	if impact_audio.playing:
		impact_audio.stop()
	visible = false


func launch(new_direction: Vector3, new_source: Node, new_damage: int) -> void:
	direction = new_direction.normalized()
	source = new_source
	damage = new_damage


func _process(delta: float) -> void:
	if not _active:
		return
	_pulse_time += delta * light_pulse_speed
	projectile_light.light_energy = _base_light_energy + (sin(_pulse_time) * 0.5 + 0.5) * light_pulse_amplitude


func _physics_process(delta: float) -> void:
	if not _active:
		return

	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D:
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
	var hit_normal: Vector3 = result.get("normal", -direction)
	if hit_normal.length_squared() <= 0.001:
		hit_normal = -direction
	var damage_target := _resolve_damage_target(result.get("collider") as Object)
	global_position = (
		hit_position
		+ hit_normal.normalized() * _impact_offset_for_target(damage_target)
	)
	if damage_target != null:
		damage_target.call("take_damage", damage, global_position, source)
	_impact()


func _on_body_entered(body: Node3D) -> void:
	if not _active or body == source:
		return
	var damage_target := _resolve_damage_target(body)
	global_position -= direction * _impact_offset_for_target(damage_target)
	if damage_target != null:
		damage_target.call("take_damage", damage, global_position, source)
	_impact()


func _impact_offset_for_target(target: Node) -> float:
	if target != null and target.is_in_group("player"):
		return player_impact_surface_offset
	return impact_surface_offset


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _impact() -> void:
	if not _active:
		return
	var generation := _lifecycle_generation
	_active = false
	set_process(false)
	set_physics_process(false)
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.visible = false
	impact_visual.visible = true
	impact_visual.modulate = _base_impact_modulate
	impact_visual.scale = _base_impact_scale * impact_start_scale_multiplier
	projectile_light.light_energy = impact_light_energy
	if impact_audio.stream != null:
		impact_audio.play()

	var impact_tween := create_tween().set_parallel(true)
	impact_tween.tween_property(
		impact_visual,
		"scale",
		_base_impact_scale * impact_end_scale_multiplier,
		impact_scale_duration
	)
	impact_tween.tween_property(
		projectile_light,
		"light_energy",
		0.0,
		impact_light_fade_duration
	)
	var fade_track := impact_tween.tween_property(
		impact_visual,
		"modulate:a",
		0.0,
		impact_fade_duration
	)
	fade_track.set_delay(impact_fade_delay)

	if impact_visual is AnimatedSprite3D:
		var animated_impact := impact_visual as AnimatedSprite3D
		animated_impact.frame = 0
		animated_impact.play(&"default")
		await animated_impact.animation_finished
	if not is_inside_tree() or generation != _lifecycle_generation:
		return
	await impact_tween.finished
	if not is_inside_tree() or generation != _lifecycle_generation:
		return

	if impact_audio.stream != null and impact_audio.playing:
		await impact_audio.finished
	if is_inside_tree() and generation == _lifecycle_generation:
		_recycle_or_free()


func _expire_later(generation: int) -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree() and _active and generation == _lifecycle_generation:
		_recycle_or_free()


func _recycle_or_free() -> void:
	if has_meta("vex_projectile_pool_key"):
		EnemyProjectilePool.recycle(self)
	else:
		queue_free()
