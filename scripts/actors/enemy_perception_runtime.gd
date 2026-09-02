class_name VexEnemyPerceptionRuntime
extends RefCounted


static func active_detection_range(
	alerted: bool,
	runtime_detection_range: float,
	runtime_pursuit_range: float,
	damage_reaction_remaining: float,
	damage_reaction_range: float
) -> float:
	var active_range := runtime_pursuit_range if alerted else runtime_detection_range
	if damage_reaction_remaining > 0.0:
		active_range = maxf(active_range, damage_reaction_range)
	return active_range


static func is_player_inside_initial_view(
	enemy_position: Vector3,
	facing_direction: Vector3,
	player_position: Vector3,
	initial_view_angle: float
) -> bool:
	var player_direction := player_position - enemy_position
	player_direction.y = 0.0
	if player_direction.length_squared() <= 0.001:
		return true
	player_direction = player_direction.normalized()
	var view_threshold := cos(deg_to_rad(initial_view_angle * 0.5))
	return facing_direction.dot(player_direction) >= view_threshold


static func passes_crouch_detection(
	alerted: bool,
	is_crouching: bool,
	player_distance: float,
	guaranteed_detection_distance: float,
	detection_chance: float
) -> bool:
	if alerted or not is_crouching:
		return true
	if player_distance <= guaranteed_detection_distance:
		return true
	return randf() <= detection_chance


static func has_visual_contact(
	enemy: Node3D,
	player: Node3D,
	origin: Vector3,
	sight_collision_mask: int,
	sight_target_height: float,
	visibility_vertical_span_scale: float,
	visibility_vertical_span_min: float,
	visibility_vertical_span_max: float,
	visibility_lateral_span_scale: float,
	visibility_lateral_span_min: float,
	visibility_lateral_span_max: float,
	visibility_shoulder_height_ratio: float,
	visibility_lower_body_ratio: float
) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	if player == null or not is_instance_valid(player):
		return false
	return VexEnemyRuntimeUtils.has_visual_contact(
		enemy.get_world_3d(),
		origin,
		player,
		sight_collision_mask,
		enemy.get_rid(),
		sight_target_height,
		visibility_vertical_span_scale,
		visibility_vertical_span_min,
		visibility_vertical_span_max,
		visibility_lateral_span_scale,
		visibility_lateral_span_min,
		visibility_lateral_span_max,
		visibility_shoulder_height_ratio,
		visibility_lower_body_ratio
	)


static func crouched_sight_target_height(
	player: Node3D,
	sight_target_height: float,
	crouched_target_height_scale: float,
	crouched_target_min_height: float
) -> float:
	if player == null or not is_instance_valid(player):
		return 0.0
	var shape_node := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			var top_height := shape_node.position.y + (capsule.height * 0.5)
			return clampf(
				top_height * crouched_target_height_scale,
				crouched_target_min_height,
				sight_target_height
			)
	return 0.0


static func is_player_collider(player: Node3D, collider: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var current := collider
	var depth := 0
	while current != null and depth < 6:
		if current == player:
			return true
		current = current.get_parent()
		depth += 1
	return false


static func ranged_visibility_ratio_from(
	enemy: Node3D,
	player: Node3D,
	observer_position: Vector3,
	sight_collision_mask: int,
	sight_target_height: float,
	visibility_vertical_span_scale: float,
	visibility_vertical_span_min: float,
	visibility_vertical_span_max: float,
	visibility_lateral_span_scale: float,
	visibility_lateral_span_min: float,
	visibility_lateral_span_max: float,
	visibility_shoulder_height_ratio: float,
	visibility_lower_body_ratio: float
) -> float:
	if enemy == null or not is_instance_valid(enemy):
		return 0.0
	if player == null or not is_instance_valid(player):
		return 0.0

	var target_center := player.global_position + Vector3.UP * sight_target_height
	var half_height := maxf(sight_target_height, 0.45)
	var lateral_radius := 0.28
	var shape_node := player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape != null and not shape_node.disabled:
		target_center = shape_node.global_position
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			half_height = maxf(capsule.height * 0.5, capsule.radius)
			lateral_radius = capsule.radius
		else:
			var box := shape_node.shape as BoxShape3D
			if box != null:
				half_height = box.size.y * 0.5
				lateral_radius = minf(box.size.x, box.size.z) * 0.5

	var toward_target := player.global_position - observer_position
	toward_target.y = 0.0
	if toward_target.length_squared() <= 0.0001:
		toward_target = Vector3.FORWARD
	else:
		toward_target = toward_target.normalized()
	var side := Vector3.UP.cross(toward_target).normalized()
	var vertical_span := clampf(
		half_height * visibility_vertical_span_scale,
		visibility_vertical_span_min,
		maxf(visibility_vertical_span_min, visibility_vertical_span_max)
	)
	var lateral_span := clampf(
		lateral_radius * visibility_lateral_span_scale,
		visibility_lateral_span_min,
		maxf(visibility_lateral_span_min, visibility_lateral_span_max)
	)
	var samples: Array[Vector3] = [
		target_center,
		target_center + Vector3.UP * vertical_span,
		target_center + side * lateral_span
			+ Vector3.UP * (vertical_span * visibility_shoulder_height_ratio),
		target_center - side * lateral_span
			+ Vector3.UP * (vertical_span * visibility_shoulder_height_ratio),
		target_center - Vector3.UP * (vertical_span * visibility_lower_body_ratio),
	]
	var visible_samples := 0
	var space_state := enemy.get_world_3d().direct_space_state
	for sample: Vector3 in samples:
		var query := PhysicsRayQueryParameters3D.create(
			observer_position,
			sample,
			sight_collision_mask,
			[enemy.get_rid()]
		)
		query.collide_with_areas = true
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var collider := result.get("collider") as Node
		if is_player_collider(player, collider):
			visible_samples += 1
	return float(visible_samples) / float(samples.size())


static func horizontal_distance(first_position: Vector3, second_position: Vector3) -> float:
	var offset := second_position - first_position
	offset.y = 0.0
	return offset.length()


static func is_within_horizontal_range(
	first_position: Vector3,
	second_position: Vector3,
	maximum_range: float
) -> bool:
	return horizontal_distance(first_position, second_position) <= maximum_range


static func effective_hearing_range(
	hearing_radius: float,
	loudness: float,
	hearing_loudness_scale: float
) -> float:
	return hearing_radius * maxf(loudness * hearing_loudness_scale, 0.1)


static func should_hear_noise(
	enemy_position: Vector3,
	noise_position: Vector3,
	hearing_radius: float,
	loudness: float,
	hearing_loudness_scale: float
) -> bool:
	return is_within_horizontal_range(
		enemy_position,
		noise_position,
		effective_hearing_range(hearing_radius, loudness, hearing_loudness_scale)
	)


static func should_broadcast_noise_alert(loudness: float, alert_threshold: float) -> bool:
	return loudness >= alert_threshold


static func should_accept_ally_alert(
	is_dead: bool,
	player_visible: bool,
	receive_ally_alerts: bool
) -> bool:
	return not is_dead and not player_visible and receive_ally_alerts


static func ally_alert_facing_direction(
	enemy_position: Vector3,
	suspected_position: Vector3,
	current_facing_direction: Vector3
) -> Vector3:
	var alert_direction := suspected_position - enemy_position
	alert_direction.y = 0.0
	if alert_direction.length_squared() <= 0.001:
		return current_facing_direction
	return alert_direction.normalized()


static func should_skip_idle_sight(
	alerted: bool,
	player_distance: float,
	runtime_detection_range: float,
	idle_detection_margin: float
) -> bool:
	return not alerted and player_distance > runtime_detection_range + idle_detection_margin


static func sight_interval(
	player_distance: float,
	alerted: bool,
	runtime_detection_range: float,
	distant_think_distance: float,
	near_sight_interval: float,
	medium_sight_interval: float,
	distant_sight_interval: float,
	idle_far_sight_interval: float
) -> float:
	if player_distance > distant_think_distance:
		return distant_sight_interval if alerted else idle_far_sight_interval
	if player_distance > runtime_detection_range:
		return medium_sight_interval
	return near_sight_interval


static func is_sight_check_due(sight_check_remaining: float, delta: float) -> bool:
	return sight_check_remaining - delta <= 0.0


static func next_sight_check_remaining(
	sight_check_remaining: float,
	delta: float,
	reset_interval: float
) -> float:
	var next_remaining := sight_check_remaining - delta
	return reset_interval if next_remaining <= 0.0 else next_remaining
