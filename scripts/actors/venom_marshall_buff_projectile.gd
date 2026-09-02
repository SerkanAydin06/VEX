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
@export_range(1.0, 30.0, 0.5) var speed := 13.0
@export_range(0.5, 8.0, 0.1) var flight_lifetime := 4.0
@export_range(0.1, 1.5, 0.05) var target_arrival_distance := 0.45
@export_flags_3d_physics var flight_collision_mask := 1
@export_flags_3d_physics var floor_collision_mask := 1
@export_range(0.0, 3.0, 0.05) var floor_probe_height := 1.6
@export_range(0.1, 8.0, 0.1) var floor_probe_depth := 5.0

@export_category("02 - Güçlendirme Alanı")
@export_range(1.0, 10.0, 0.1) var field_radius := 5.6
@export_range(1.0, 15.0, 0.1) var field_duration := 7.0
@export_range(0.1, 2.0, 0.05) var field_tick_interval := 1.0
@export_range(0.2, 3.0, 0.05) var field_fade_duration := 1.1
@export_flags_3d_physics var field_collision_mask := 4
@export_range(0.0, 0.25, 0.005) var heal_ratio_per_tick := 0.04
@export_range(1.0, 2.0, 0.05) var damage_multiplier := 1.25
@export_range(0.5, 15.0, 0.1) var buff_duration := 8.0

@export_category("03 - Görsel")
@export_range(0.0, 8.0, 0.05) var flight_light_energy := 2.6
@export_range(0.0, 8.0, 0.05) var field_light_energy := 2.2
@export_range(0.0, 20.0, 0.1) var pulse_speed := 4.8
@export_range(0.1, 2.0, 0.05) var field_visual_alpha := 0.72

@onready var field_collision: CollisionShape3D = $FieldCollision
@onready var flight_visual: AnimatedSprite3D = $FlightVisual
@onready var ground_field_visual: AnimatedSprite3D = $GroundFieldVisual
@onready var deploy_impact: AnimatedSprite3D = $DeployImpact
@onready var field_disc: MeshInstance3D = $FieldDisc
@onready var field_light: OmniLight3D = $FieldLight
@onready var deploy_audio: AudioStreamPlayer3D = $DeployAudio

var source: Node = null
var direction := Vector3.FORWARD
var _target_position := Vector3.ZERO
var _phase := Phase.INACTIVE
var _flight_remaining := 0.0
var _field_remaining := 0.0
var _field_tick_remaining := 0.0
var _pulse_time := 0.0
var _field_material: StandardMaterial3D = null


func _ready() -> void:
	_apply_field_radius()
	if field_disc.material_override is StandardMaterial3D:
		_field_material = (field_disc.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		field_disc.material_override = _field_material
	activate_from_pool()


func _apply_field_radius() -> void:
	if field_collision.shape is CylinderShape3D:
		var unique_shape := (field_collision.shape as CylinderShape3D).duplicate() as CylinderShape3D
		unique_shape.radius = field_radius
		field_collision.shape = unique_shape
	if field_disc.mesh is CylinderMesh:
		var unique_mesh := (field_disc.mesh as CylinderMesh).duplicate() as CylinderMesh
		unique_mesh.top_radius = field_radius
		unique_mesh.bottom_radius = field_radius
		field_disc.mesh = unique_mesh
	ground_field_visual.pixel_size = field_radius * 2.0 / 512.0
	field_light.omni_range = maxf(field_radius + 1.0, 1.0)


func activate_from_pool() -> void:
	_phase = Phase.FLIGHT
	source = null
	direction = Vector3.FORWARD
	_target_position = global_position
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
	flight_visual.frame = 0
	flight_visual.play(&"default")
	ground_field_visual.visible = false
	ground_field_visual.frame = 0
	ground_field_visual.stop()
	deploy_impact.visible = false
	deploy_impact.frame = 0
	deploy_impact.stop()
	field_disc.visible = false
	field_light.visible = true
	field_light.light_energy = flight_light_energy
	if deploy_audio.playing:
		deploy_audio.stop()


func deactivate_for_pool() -> void:
	_phase = Phase.INACTIVE
	source = null
	set_process(false)
	set_physics_process(false)
	monitoring = false
	monitorable = false
	collision_mask = 0
	field_collision.set_deferred("disabled", true)
	flight_visual.visible = false
	ground_field_visual.visible = false
	deploy_impact.visible = false
	field_disc.visible = false
	field_light.visible = false
	field_light.light_energy = 0.0
	if deploy_audio.playing:
		deploy_audio.stop()
	visible = false


func launch_to(new_target_position: Vector3, new_source: Node) -> void:
	source = new_source if is_instance_valid(new_source) else null
	_target_position = new_target_position
	var aim_position := new_target_position + Vector3.UP * 0.12
	direction = (aim_position - global_position).normalized()
	if direction.length_squared() <= 0.001:
		direction = Vector3.DOWN


func _process(delta: float) -> void:
	if _phase == Phase.INACTIVE:
		return
	_pulse_time += delta * pulse_speed
	var pulse := sin(_pulse_time) * 0.5 + 0.5
	if _phase == Phase.FLIGHT:
		field_light.light_energy = flight_light_energy * (0.82 + pulse * 0.18)
		return
	if deploy_impact.visible and not deploy_impact.is_playing():
		deploy_impact.visible = false
	var fade := 1.0
	if _field_remaining < field_fade_duration:
		fade = clampf(_field_remaining / maxf(field_fade_duration, 0.01), 0.0, 1.0)
	var alpha_pulse := (0.84 + pulse * 0.16) * fade
	ground_field_visual.modulate.a = field_visual_alpha * alpha_pulse
	ground_field_visual.scale = Vector3.ONE * (0.96 + pulse * 0.04)
	if _field_material != null:
		var disc_color := _field_material.albedo_color
		disc_color.a = 0.16 * alpha_pulse
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
	if _flight_remaining <= 0.0 or global_position.distance_to(_target_position) <= target_arrival_distance:
		_deploy_field(_target_position)
		return
	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	var valid_source := _valid_source()
	if valid_source is CollisionObject3D:
		exclusions.append((valid_source as CollisionObject3D).get_rid())
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
	_field_tick_remaining = 0.08
	flight_visual.visible = false
	ground_field_visual.visible = true
	ground_field_visual.frame = 0
	ground_field_visual.play(&"default")
	deploy_impact.visible = true
	deploy_impact.frame = 0
	deploy_impact.play(&"default")
	field_disc.visible = true
	field_light.visible = true
	field_light.light_energy = field_light_energy
	collision_mask = field_collision_mask
	monitorable = false
	monitoring = true
	field_collision.set_deferred("disabled", false)
	if deploy_audio.stream != null:
		deploy_audio.play()


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
		var target := _resolve_enemy_target(body)
		if target == null or target == _valid_source():
			continue
		_apply_support_pulse(target)


func _apply_support_pulse(target: Node) -> void:
	var maximum := maxi(1, int(target.get("_runtime_maximum_health")))
	var current := int(target.get("health"))
	if current <= 0:
		return
	var heal_amount := maxi(1, int(ceil(float(maximum) * heal_ratio_per_tick)))
	target.set("health", mini(maximum, current + heal_amount))
	var status := target.get_node_or_null("VenomMarshallBuffStatus")
	if status == null:
		status = BuffStatus.new()
		status.name = "VenomMarshallBuffStatus"
		target.add_child(status)
	status.call("refresh_buff", buff_duration, damage_multiplier)


func _ground_field_position(origin: Vector3) -> Vector3:
	var query_start := origin + Vector3.UP * floor_probe_height
	var query_end := origin - Vector3.UP * floor_probe_depth
	var exclusions: Array[RID] = [get_rid()]
	var valid_source := _valid_source()
	if valid_source is CollisionObject3D:
		exclusions.append((valid_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		query_start,
		query_end,
		floor_collision_mask,
		exclusions
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		return origin
	return (result.get("position", origin) as Vector3) + Vector3.UP * 0.035


func _resolve_enemy_target(collider: Object) -> Node:
	var current := collider as Node
	var depth := 0
	while current != null and depth < 5:
		if current.is_in_group("enemy") and current.has_method("take_damage"):
			return current
		current = current.get_parent()
		depth += 1
	return null


func _valid_source() -> Node:
	if is_instance_valid(source):
		return source
	source = null
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
