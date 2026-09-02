class_name VexVenomMarshallBuffProjectile
extends Area3D

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")
const BuffStatus = preload("res://scripts/actors/venom_marshall_buff_status.gd")

enum Phase {
	INACTIVE,
	FLIGHT,
	FIELD,
}

@export_category("01 - Uçuş")
@export_range(1.0, 30.0, 0.5) var speed := 12.0
@export_range(0.5, 8.0, 0.1) var flight_lifetime := 4.0
@export_flags_3d_physics var flight_collision_mask := 1
@export_flags_3d_physics var floor_collision_mask := 1
@export_range(0.0, 3.0, 0.05) var floor_probe_height := 1.6
@export_range(0.1, 8.0, 0.1) var floor_probe_depth := 5.0

@export_category("02 - Destek Alanı")
@export_range(1.0, 12.0, 0.1) var field_radius := 6.5
@export_range(0.5, 20.0, 0.1) var field_duration := 8.0
@export_range(0.1, 2.0, 0.05) var field_tick_interval := 0.30
@export_range(0.5, 5.0, 0.1) var field_height := 3.0
@export_flags_3d_physics var enemy_collision_mask := 4
@export_range(0.0, 1.0, 0.05) var heal_ratio := 0.30
@export_range(1.0, 3.0, 0.05) var damage_multiplier := 1.25
@export_range(1.0, 3.0, 0.05) var speed_multiplier := 1.20
@export_range(0.1, 4.0, 0.05) var buff_grace_duration := 1.25
@export_range(0.1, 3.0, 0.05) var field_fade_duration := 1.0

@export_category("03 - Görsel")
@export_range(0.0, 8.0, 0.05) var flight_light_energy := 2.2
@export_range(0.0, 8.0, 0.05) var field_light_energy := 2.6
@export_range(0.0, 20.0, 0.1) var pulse_speed := 4.5
@export_range(0.1, 1.0, 0.05) var field_visual_alpha := 0.70

@onready var field_collision: CollisionShape3D = $FieldCollision
@onready var flight_visual: AnimatedSprite3D = $FlightVisual
@onready var field_visual: AnimatedSprite3D = $FieldVisual
@onready var field_light: OmniLight3D = $FieldLight

var source: Node = null
var _phase := Phase.INACTIVE
var _flight_remaining := 0.0
var _field_remaining := 0.0
var _field_tick_remaining := 0.0
var _target_position := Vector3.ZERO
var _pulse_time := 0.0
var _generation := 0
var _healed_enemy_ids: Dictionary = {}


func _ready() -> void:
	_apply_field_radius()
	activate_from_pool()


func activate_from_pool() -> void:
	_generation += 1
	_phase = Phase.FLIGHT
	source = null
	_target_position = global_position
	_flight_remaining = flight_lifetime
	_field_remaining = 0.0
	_field_tick_remaining = 0.0
	_pulse_time = 0.0
	_healed_enemy_ids.clear()
	visible = true
	set_process(true)
	set_physics_process(true)
	monitoring = false
	monitorable = false
	collision_mask = 0
	field_collision.set_deferred("disabled", true)
	flight_visual.visible = true
	flight_visual.modulate = Color.WHITE
	flight_visual.frame = 0
	flight_visual.play(&"2nd_projectile")
	field_visual.visible = false
	field_visual.stop()
	field_light.visible = true
	field_light.light_energy = flight_light_energy
	_apply_field_radius()


func deactivate_for_pool() -> void:
	_generation += 1
	_phase = Phase.INACTIVE
	source = null
	set_process(false)
	set_physics_process(false)
	monitoring = false
	monitorable = false
	collision_mask = 0
	field_collision.set_deferred("disabled", true)
	flight_visual.visible = false
	field_visual.visible = false
	field_light.visible = false
	field_light.light_energy = 0.0
	visible = false
	_healed_enemy_ids.clear()


func launch_toward(target_position: Vector3, new_source: Node) -> void:
	_target_position = target_position
	source = new_source
	_flight_remaining = flight_lifetime


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
	field_visual.modulate.a = field_visual_alpha * (0.82 + pulse * 0.18) * fade
	field_light.light_energy = field_light_energy * (0.80 + pulse * 0.20) * fade


func _physics_process(delta: float) -> void:
	match _phase:
		Phase.FLIGHT:
			_update_flight(delta)
		Phase.FIELD:
			_update_field(delta)


func _update_flight(delta: float) -> void:
	_flight_remaining = maxf(0.0, _flight_remaining - delta)
	if _flight_remaining <= 0.0:
		_deploy_field(_target_position)
		return

	var to_target := _target_position - global_position
	var distance := to_target.length()
	if distance <= maxf(speed * delta, 0.05):
		_deploy_field(_target_position)
		return
	var direction := to_target.normalized()
	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D and is_instance_valid(source):
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
	_deploy_field(result.get("position", end_position) as Vector3)


func _deploy_field(origin: Vector3) -> void:
	if _phase != Phase.FLIGHT:
		return
	_phase = Phase.FIELD
	global_position = _ground_field_position(origin)
	_field_remaining = field_duration
	_field_tick_remaining = 0.0
	flight_visual.visible = false
	field_visual.visible = true
	field_visual.frame = 0
	field_visual.play(&"impact")
	field_light.visible = true
	field_light.light_energy = field_light_energy
	collision_mask = enemy_collision_mask
	monitorable = false
	monitoring = true
	field_collision.set_deferred("disabled", false)
	_apply_field_radius()


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
		if body is Node3D:
			_apply_buff_to_enemy(body as Node3D)


func _apply_buff_to_enemy(enemy: Node3D) -> void:
	if not _is_living_enemy(enemy):
		return
	if source != null and is_instance_valid(source) and enemy == source:
		return
	var instance_id := enemy.get_instance_id()
	if not _healed_enemy_ids.has(instance_id):
		_heal_enemy(enemy)
		_healed_enemy_ids[instance_id] = true

	var status := enemy.get_node_or_null("VenomMarshallBuffStatus")
	if status == null:
		status = BuffStatus.new()
		status.name = "VenomMarshallBuffStatus"
		enemy.add_child(status)
	status.call(
		"refresh_buff",
		buff_grace_duration,
		damage_multiplier,
		speed_multiplier
	)


func _heal_enemy(enemy: Node) -> void:
	if not _has_property(enemy, &"health"):
		return
	var maximum := 1
	if _has_property(enemy, &"_runtime_maximum_health"):
		maximum = maxi(1, int(enemy.get("_runtime_maximum_health")))
	elif _has_property(enemy, &"maximum_health"):
		maximum = maxi(1, int(enemy.get("maximum_health")))
	var current := clampi(int(enemy.get("health")), 0, maximum)
	var heal_amount := maxi(1, int(round(float(maximum) * heal_ratio)))
	enemy.set("health", mini(maximum, current + heal_amount))


func _is_living_enemy(enemy: Node3D) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		return false
	if not enemy.is_in_group("enemy"):
		return false
	if _has_property(enemy, &"_dead") and bool(enemy.get("_dead")):
		return false
	if _has_property(enemy, &"state") and int(enemy.get("state")) == 6:
		return false
	if _has_property(enemy, &"health") and int(enemy.get("health")) <= 0:
		return false
	return true


func _ground_field_position(origin: Vector3) -> Vector3:
	var query_start := origin + Vector3.UP * floor_probe_height
	var query_end := origin - Vector3.UP * floor_probe_depth
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D and is_instance_valid(source):
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


func _apply_field_radius() -> void:
	if field_collision != null and field_collision.shape is CylinderShape3D:
		var cylinder := field_collision.shape as CylinderShape3D
		cylinder.radius = field_radius
		cylinder.height = field_height
	if field_visual != null:
		field_visual.pixel_size = (field_radius * 2.0) / 512.0
	if field_light != null:
		field_light.omni_range = field_radius * 1.15


func get_field_radius() -> float:
	return field_radius


func is_field_active() -> bool:
	return _phase == Phase.FIELD


func _has_property(target: Object, property_name: StringName) -> bool:
	if target == null:
		return false
	for property: Dictionary in target.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _recycle_or_free() -> void:
	if has_meta("vex_projectile_pool_key"):
		EnemyProjectilePool.recycle(self)
	else:
		queue_free()
