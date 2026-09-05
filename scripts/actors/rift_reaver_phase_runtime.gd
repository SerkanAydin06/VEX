extends RefCounted

const MIN_FLOOR_NORMAL_Y := 0.65
const MIN_STEP_DISTANCE := 0.08


static func find_destination(
	source: CharacterBody3D,
	player: Node3D,
	settings: VexRiftReaverPhaseSettings,
	recovery: bool,
	preferred_side: float,
	floor_collision_mask: int,
	floor_local_y: float,
	sight_collision_mask: int,
	sight_origin_height: float,
	sight_target_height: float
) -> Dictionary:
	if source == null or player == null or settings == null:
		return {}
	if not is_instance_valid(source) or not is_instance_valid(player):
		return {}
	if not source.is_inside_tree() or not settings.enabled:
		return {}

	var radial := source.global_position - player.global_position
	radial.y = 0.0
	if radial.length_squared() <= 0.001:
		radial = source.global_transform.basis.z
		radial.y = 0.0
	if radial.length_squared() <= 0.001:
		radial = Vector3.BACK
	radial = radial.normalized()

	var angle_degrees := (
		settings.recovery_arc_degrees
		if recovery
		else settings.pre_attack_arc_degrees
	)
	var target_radius := (
		settings.recovery_radius
		if recovery
		else settings.pre_attack_radius
	)
	var primary_side := 1.0 if preferred_side >= 0.0 else -1.0
	for side_variant: Variant in [primary_side, -primary_side]:
		var side := float(side_variant)
		var rotated := radial.rotated(
			Vector3.UP,
			deg_to_rad(angle_degrees) * side
		)
		var candidate := player.global_position + rotated * target_radius
		candidate.y = source.global_position.y
		var grounded := _ground_candidate(
			source,
			candidate,
			settings,
			floor_collision_mask,
			floor_local_y
		)
		if grounded.is_empty():
			continue
		var grounded_position: Vector3 = grounded.get("position", candidate)
		candidate = grounded_position

		var horizontal_motion := candidate - source.global_position
		horizontal_motion.y = 0.0
		var step_distance := horizontal_motion.length()
		if (
			step_distance < MIN_STEP_DISTANCE
			or step_distance > settings.maximum_step_distance
		):
			continue
		if _horizontal_distance(candidate, player.global_position) < settings.minimum_player_distance:
			continue

		# Faz görsel olarak ani olsa da fiziksel yol süpürülür. Duvar, oyuncu veya
		# başka bir gövde eski ve yeni konum arasında ise teleport reddedilir.
		var motion := candidate - source.global_position
		if source.test_move(source.global_transform, motion):
			continue
		if not _has_player_line_of_sight(
			source,
			player,
			candidate,
			sight_collision_mask,
			sight_origin_height,
			sight_target_height
		):
			continue
		return {
			"position": candidate,
			"side": side,
		}
	return {}


static func _ground_candidate(
	source: CharacterBody3D,
	candidate: Vector3,
	settings: VexRiftReaverPhaseSettings,
	floor_collision_mask: int,
	floor_local_y: float
) -> Dictionary:
	var ray_start := Vector3(
		candidate.x,
		source.global_position.y + settings.floor_probe_height,
		candidate.z
	)
	var ray_end := ray_start + Vector3.DOWN * settings.floor_probe_depth
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		floor_collision_mask,
		[source.get_rid()]
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := source.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return {}
	var floor_normal: Vector3 = hit.get("normal", Vector3.UP)
	if floor_normal.y < MIN_FLOOR_NORMAL_Y:
		return {}
	var floor_position: Vector3 = hit.get("position", candidate)
	var root_y := floor_position.y - floor_local_y
	if absf(root_y - source.global_position.y) > settings.maximum_floor_height_change:
		return {}
	candidate.y = root_y
	return {"position": candidate}


static func _has_player_line_of_sight(
	source: CharacterBody3D,
	player: Node3D,
	candidate: Vector3,
	sight_collision_mask: int,
	sight_origin_height: float,
	sight_target_height: float
) -> bool:
	var origin := candidate + Vector3.UP * sight_origin_height
	var target := player.global_position + Vector3.UP * sight_target_height
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		sight_collision_mask,
		[source.get_rid()]
	)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var hit := source.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	var collider := hit.get("collider") as Node
	var current := collider
	var depth := 0
	while current != null and depth < 5:
		if current == player:
			return true
		current = current.get_parent()
		depth += 1
	return false


static func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	var delta := first - second
	delta.y = 0.0
	return delta.length()
