class_name VexCrucibleWardenGroundSlam
extends Node3D

@export_category("01 - AoE")
@export_range(0.5, 12.0, 0.1) var damage_radius := 4.6
@export_range(1, 200, 1) var damage := 42
@export_flags_3d_physics var occlusion_mask := 1

@export_category("02 - Camera Shake")
@export_range(0.5, 20.0, 0.5) var shake_radius := 8.5
@export_range(0.0, 0.3, 0.005) var shake_strength := 0.075
@export_range(0.0, 1.5, 0.05) var shake_duration := 0.42

@export_category("03 - Visual")
@export_range(0.05, 1.5, 0.05) var visual_duration := 0.48
@export_range(0.01, 1.0, 0.01) var visual_start_scale := 0.12
@export_range(0.5, 12.0, 0.1) var visual_reference_radius := 4.6
@export_range(0.5, 2.0, 0.05) var impact_light_range_multiplier := 1.15
@export_range(0.1, 4.0, 0.1) var impact_light_minimum_range := 1.0

@export_category("04 - Dünya Etkileşimi")
@export_range(0.0, 2.0, 0.05) var occlusion_origin_height := 0.25
@export_range(0.0, 2.0, 0.05) var occlusion_target_height := 0.35
@export_range(0.0, 1.0, 0.05) var shake_minimum_proximity_scale := 0.30

@onready var decal_visual: AnimatedSprite3D = $DecalVisual
@onready var ring: MeshInstance3D = $Ring
@onready var impact_light: OmniLight3D = $ImpactLight

var _source: Node = null


func configure(
	new_radius: float,
	new_damage: int,
	source: Node,
	new_shake_radius: float,
	new_shake_strength: float,
	new_shake_duration: float
) -> void:
	damage_radius = maxf(0.5, new_radius)
	damage = maxi(1, new_damage)
	_source = source if is_instance_valid(source) else null
	shake_radius = maxf(damage_radius, new_shake_radius)
	shake_strength = maxf(0.0, new_shake_strength)
	shake_duration = maxf(0.0, new_shake_duration)


func _ready() -> void:
	var decal_target_scale := damage_radius / maxf(visual_reference_radius, 0.001)
	decal_visual.scale = Vector3.ONE * visual_start_scale * decal_target_scale
	ring.scale = Vector3(visual_start_scale, 1.0, visual_start_scale)
	impact_light.omni_range = maxf(
		damage_radius * impact_light_range_multiplier,
		impact_light_minimum_range
	)
	call_deferred("_resolve_impact")

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(
		ring,
		"scale",
		Vector3(damage_radius, 1.0, damage_radius),
		visual_duration
	)
	tween.parallel().tween_property(
		decal_visual,
		"scale",
		Vector3.ONE * decal_target_scale,
		visual_duration
	)
	tween.parallel().tween_property(
		impact_light,
		"light_energy",
		0.0,
		visual_duration
	)
	await tween.finished
	if is_inside_tree():
		queue_free()


func _resolve_impact() -> void:
	_apply_damage_once()
	if SettingsManager.screen_shake and shake_strength > 0.0 and shake_duration > 0.0:
		_shake_player_camera()


func _apply_damage_once() -> void:
	var player := GameState.player as Node3D
	if player == null or not is_instance_valid(player):
		return
	if VexEnemyRuntimeUtils.horizontal_distance(global_position, player.global_position) > damage_radius:
		return
	if not _has_clear_path_to_player(player):
		return
	if player.has_method("take_damage"):
		player.call("take_damage", damage, player.global_position, _valid_source())


func _has_clear_path_to_player(player: Node3D) -> bool:
	var origin := global_position + Vector3.UP * occlusion_origin_height
	var target := player.global_position + Vector3.UP * occlusion_target_height
	var exclusions: Array[RID] = []
	var damage_source := _valid_source()
	if damage_source is CollisionObject3D:
		exclusions.append((damage_source as CollisionObject3D).get_rid())
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		occlusion_mask,
		exclusions
	)
	query.collide_with_areas = false
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _valid_source() -> Node:
	if is_instance_valid(_source):
		return _source
	_source = null
	return null


func _shake_player_camera() -> void:
	var player := GameState.player as Node3D
	if player == null or not is_instance_valid(player):
		return
	var distance := VexEnemyRuntimeUtils.horizontal_distance(global_position, player.global_position)
	if distance > shake_radius:
		return
	var proximity := 1.0 - clampf(distance / maxf(shake_radius, 0.001), 0.0, 1.0)
	var effective_strength := shake_strength * lerpf(shake_minimum_proximity_scale, 1.0, proximity)
	if player.has_method("request_camera_shake"):
		player.call("request_camera_shake", effective_strength, shake_duration)
		return
	if not player.has_method("get_view_camera"):
		return
	var camera := player.call("get_view_camera") as Camera3D
	if camera == null or not is_instance_valid(camera):
		return
	var base_h_offset := camera.h_offset
	var base_v_offset := camera.v_offset
	var start_msec := Time.get_ticks_msec()

	while is_inside_tree() and is_instance_valid(camera):
		var elapsed := float(Time.get_ticks_msec() - start_msec) / 1000.0
		if elapsed >= shake_duration:
			break
		var fade := 1.0 - clampf(elapsed / maxf(shake_duration, 0.001), 0.0, 1.0)
		camera.h_offset = base_h_offset + randf_range(-effective_strength, effective_strength) * fade
		camera.v_offset = base_v_offset + randf_range(-effective_strength, effective_strength) * fade
		await get_tree().process_frame

	if is_instance_valid(camera):
		camera.h_offset = base_h_offset
		camera.v_offset = base_v_offset
