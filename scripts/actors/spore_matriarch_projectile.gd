class_name VexSporeMatriarchProjectile
extends Area3D

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")
const PoisonStatus = preload("res://scripts/actors/spore_poison_status.gd")

enum Phase {
	INACTIVE,
	FLIGHT,
	FIELD,
}

@export_category("01 - Uçuş")
@export_range(1.0, 30.0, 0.5) var speed := 10.5
@export_range(0.5, 8.0, 0.1) var flight_lifetime := 4.0
@export_flags_3d_physics var flight_collision_mask := 1 | 2
@export_flags_3d_physics var floor_collision_mask := 1
@export_range(0.0, 3.0, 0.05) var floor_probe_height := 1.4
@export_range(0.1, 8.0, 0.1) var floor_probe_depth := 4.5

@export_category("02 - Zehir Alanı")
@export_range(1.0, 10.0, 0.1) var field_radius := 5.2
@export_range(1.0, 15.0, 0.1) var field_duration := 5.8
@export_range(0.1, 2.0, 0.05) var field_tick_interval := 0.55
@export_range(0.2, 3.0, 0.05) var field_fade_duration := 1.15
@export_flags_3d_physics var field_collision_mask := 2
@export_range(0.0, 1.0, 0.05) var impact_damage_ratio := 0.25

@export_category("03 - Zehir DoT")
@export_range(0.5, 10.0, 0.1) var poison_duration := 3.4
@export_range(0.1, 2.0, 0.05) var poison_tick_interval := 0.75
@export_range(0.05, 1.0, 0.05) var poison_damage_ratio := 0.30

@export_category("04 - Görsel")
@export_range(0.0, 8.0, 0.05) var flight_light_energy := 2.1
@export_range(0.0, 8.0, 0.05) var field_light_energy := 2.8
@export_range(0.0, 20.0, 0.1) var pulse_speed := 5.2
@export_range(0.1, 2.0, 0.05) var field_visual_alpha := 0.62

@onready var field_collision: CollisionShape3D = $FieldCollision
@onready var flight_visual: AnimatedSprite3D = $FlightVisual
@onready var field_visual_center: AnimatedSprite3D = $FieldVisualCenter
@onready var field_visual_left: AnimatedSprite3D = $FieldVisualLeft
@onready var field_visual_right: AnimatedSprite3D = $FieldVisualRight
@onready var field_disc: MeshInstance3D = $FieldDisc
@onready var field_light: OmniLight3D = $FieldLight
@onready var deploy_audio: AudioStreamPlayer3D = $DeployAudio

var damage := 12
var direction := Vector3.FORWARD
var source: Node = null
var _phase := Phase.INACTIVE
var _flight_remaining := 0.0
var _field_remaining := 0.0
var _field_tick_remaining := 0.0
var _pulse_time := 0.0
var _lifecycle_generation := 0
var _field_material: StandardMaterial3D = null
var _field_visuals: Array[AnimatedSprite3D] = []


func _ready() -> void:
	_field_visuals = [field_visual_center, field_visual_left, field_visual_right]
	if field_disc.material_override is StandardMaterial3D:
		_field_material = (field_disc.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		field_disc.material_override = _field_material
	activate_from_pool()


func activate_from_pool() -> void:
	_lifecycle_generation += 1
	_phase = Phase.FLIGHT
	direction = Vector3.FORWARD
	source = null
	damage = 12
	_flight_remaining = flight_lifetime
	_field_remaining = 0.0
	_field_tick_remaining = 0.0
	_pulse_time = 0.0
	visible = true
	set_process(true)
	set_physics_process(true)
	monitoring = false
	monitorable = false
	collision_mask = 0
	field_collision.set_deferred("disabled", true)
	flight_visual.visible = true
	flight_visual.modulate = Color.WHITE
	flight_visual.scale = Vector3.ONE
	flight_visual.frame = 0
	flight_visual.play(&"default")
	for visual in _field_visuals:
		visual.visible = false
		visual.modulate = Color(1.0, 1.0, 1.0, field_visual_alpha)
		visual.scale = Vector3.ONE
		visual.frame = 0
		visual.stop()
	field_disc.visible = false
	field_light.visible = true
	field_light.light_energy = flight_light_energy
	if _field_material != null:
		var color := _field_material.albedo_color
		color.a = 0.20
		_field_material.albedo_color = color
	if deploy_audio.playing:
		deploy_audio.stop()


func deactivate_for_pool() -> void:
	_lifecycle_generation += 1
	_phase = Phase.INACTIVE
	source = null
	set_process(false)
	set_physics_process(false)
	monitoring = false
	monitorable = false
	collision_mask = 0
	field_collision.set_deferred("disabled", true)
	flight_visual.visible = false
	for visual in _field_visuals:
		visual.visible = false
	field_disc.visible = false
	field_light.visible = false
	field_light.light_energy = 0.0
	if deploy_audio.playing:
		deploy_audio.stop()
	visible = false


func launch(new_direction: Vector3, new_source: Node, new_damage: int) -> void:
	direction = new_direction.normalized()
	source = new_source
	damage = maxi(1, new_damage)


func _process(delta: float) -> void:
	if _phase == Phase.INACTIVE:
		return
	_pulse_time += delta * pulse_speed
	var pulse := sin(_pulse_time) * 0.5 + 0.5
	if _phase == Phase.FLIGHT:
		field_light.light_energy = flight_light_energy * (0.82 + pulse * 0.18)
		return

	var fade := 1.0
	if _field_remaining < field_fade_duration:
		fade = clampf(_field_remaining / maxf(field_fade_duration, 0.01), 0.0, 1.0)
	var alpha_pulse := (0.84 + pulse * 0.16) * fade
	for index in range(_field_visuals.size()):
		var visual := _field_visuals[index]
		visual.modulate.a = field_visual_alpha * alpha_pulse
		var scale_pulse := 1.0 + sin(_pulse_time + float(index) * 1.8) * 0.06
		visual.scale = Vector3.ONE * scale_pulse
	if _field_material != null:
		var disc_color := _field_material.albedo_color
		disc_color.a = 0.20 * alpha_pulse
		_field_material.albedo_color = disc_color
	field_light.light_energy = field_light_energy * alpha_pulse


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.FLIGHT:
			_update_flight(delta)
		Phase.FIELD:
			_update_field(delta)


func _update_flight(delta: float) -> void:
	_flight_remaining = maxf(0.0, _flight_remaining - delta)
	if _flight_remaining <= 0.0:
		_deploy_field(global_position, null)
		return

	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D:
		exclusions.append((source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		start_position,
		end_position,
		flight_collision_mask,
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
	var hit_target := _resolve_damage_target(result.get("collider") as Object)
	_deploy_field(hit_position, hit_target)


func _deploy_field(origin: Vector3, impact_target: Node) -> void:
	if _phase != Phase.FLIGHT:
		return
	_phase = Phase.FIELD
	global_position = _ground_field_position(origin)
	_field_remaining = field_duration
	_field_tick_remaining = 0.12
	flight_visual.visible = false
	for visual in _field_visuals:
		visual.visible = true
		visual.frame = 0
		visual.play(&"default")
	field_disc.visible = true
	field_light.visible = true
	field_light.light_energy = field_light_energy
	collision_mask = field_collision_mask
	monitorable = false
	monitoring = true
	field_collision.set_deferred("disabled", false)
	if deploy_audio.stream != null:
		deploy_audio.play()
	if impact_target != null and impact_target != source and impact_target.is_in_group("player"):
		var impact_damage := maxi(1, int(round(float(damage) * impact_damage_ratio)))
		impact_target.call("take_damage", impact_damage, global_position, source)
		_apply_poison(impact_target)


func _update_field(delta: float) -> void:
	_field_remaining = maxf(0.0, _field_remaining - delta)
	if _field_remaining <= 0.0:
		_recycle_or_free()
		return
	_field_tick_remaining -= delta
	if _field_tick_remaining > 0.0:
		return
	_field_tick_remaining += field_tick_interval
	for body in get_overlapping_bodies():
		var target := _resolve_damage_target(body)
		if target == null or target == source or not target.is_in_group("player"):
			continue
		target.call("take_damage", damage, global_position, source)
		_apply_poison(target)


func _apply_poison(target: Node) -> void:
	var status := target.get_node_or_null("SporePoisonStatus")
	if status == null:
		status = PoisonStatus.new()
		status.name = "SporePoisonStatus"
		target.add_child(status)
	var poison_damage := maxi(1, int(round(float(damage) * poison_damage_ratio)))
	status.call(
		"refresh_poison",
		poison_duration,
		poison_damage,
		poison_tick_interval,
		source
	)


func _ground_field_position(origin: Vector3) -> Vector3:
	var query_start := origin + Vector3.UP * floor_probe_height
	var query_end := origin - Vector3.UP * floor_probe_depth
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D:
		exclusions.append((source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		query_start,
		query_end,
		floor_collision_mask,
		exclusions
	)
	query.hit_from_inside = false
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return origin
	return (result.get("position", origin) as Vector3) + Vector3.UP * 0.03


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func is_field_active() -> bool:
	return _phase == Phase.FIELD


func get_field_radius() -> float:
	return field_radius


func _recycle_or_free() -> void:
	if has_meta("vex_projectile_pool_key"):
		EnemyProjectilePool.recycle(self)
	else:
		queue_free()
