class_name VexFurniceCarrierShockwave
extends Area3D

@export_category("01 - Thermal Burst")
@export_range(1.0, 12.0, 0.1) var burst_radius := 6.0
@export_range(1, 100, 1) var burst_damage := 22
@export_range(0.1, 2.0, 0.05) var visual_duration := 0.60
@export_range(0.0, 1.0, 0.01) var damage_time_ratio := 0.82
@export_range(0.1, 2.0, 0.05) var effect_height := 0.8
@export_flags_3d_physics var occlusion_mask := 1

@export_category("02 - Görsel")
@export_range(1.0, 12.0, 0.1) var visual_reference_radius := 6.0
@export_range(0.05, 1.0, 0.01) var visual_start_scale := 0.18
@export_range(0.2, 2.0, 0.05) var visual_end_scale := 1.20

@onready var visual: AnimatedSprite3D = $Visual
@onready var collision_shape: CollisionShape3D = $CollisionShape3D

var _source: Node = null
var _base_visual_scale := Vector3.ONE
var _damage_applied := false


func configure(new_damage: int, source: Node) -> void:
	burst_damage = maxi(1, new_damage)
	_source = source


func _ready() -> void:
	_configure_shape_and_visual()
	visual.play(&"default")
	call_deferred("_run_burst")


func _configure_shape_and_visual() -> void:
	var cylinder := collision_shape.shape as CylinderShape3D
	if cylinder != null:
		cylinder.radius = burst_radius
		cylinder.height = effect_height
		collision_shape.position.y = effect_height * 0.5
	# Base visual scale sahneden gelir. Shockwave kaynak görseli perspektif nedeniyle
	# zemin eksenlerinden birinde çok sıkışık olduğu için scene scale burada bilinçli
	# olarak telafi edilebilir; büyüme faktörü yine tüm eksenlere eşit uygulanır.
	_base_visual_scale = visual.scale
	var radius_scale := burst_radius / maxf(visual_reference_radius, 0.01)
	visual.scale = _base_visual_scale * radius_scale * visual_start_scale


func _run_burst() -> void:
	if not is_inside_tree():
		return
	var radius_scale := burst_radius / maxf(visual_reference_radius, 0.01)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(visual, "scale", _base_visual_scale * radius_scale * visual_end_scale, visual_duration)
	var damage_delay := visual_duration * clampf(damage_time_ratio, 0.0, 1.0)
	await get_tree().create_timer(damage_delay).timeout
	if not is_inside_tree():
		return
	_apply_damage_once()
	var remaining := maxf(0.0, visual_duration - damage_delay)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if is_inside_tree():
		queue_free()


func _apply_damage_once() -> void:
	if _damage_applied:
		return
	_damage_applied = true
	var player := GameState.player as Node3D
	if player == null or not is_instance_valid(player):
		return
	if not overlaps_body(player):
		return
	if not _has_clear_path_to_player(player):
		return
	if player.has_method("take_damage"):
		player.call("take_damage", burst_damage, player.global_position, _source)


func _has_clear_path_to_player(player: Node3D) -> bool:
	var origin := global_position + Vector3.UP * 0.35
	var target := player.global_position + Vector3.UP * 0.35
	var exclusions: Array[RID] = [get_rid()]
	if _source is CollisionObject3D:
		exclusions.append((_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(origin, target, occlusion_mask, exclusions)
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
