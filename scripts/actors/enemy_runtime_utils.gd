class_name VexEnemyRuntimeUtils
extends RefCounted

static func difficulty_multiplier(values: PackedFloat32Array, difficulty_index: int) -> float:
	if values.is_empty():
		return 1.0
	var resolved := clampi(difficulty_index, 0, values.size() - 1)
	return maxf(0.0, values[resolved])

static func horizontal_distance(first: Vector3, second: Vector3) -> float:
	var difference := first - second
	difference.y = 0.0
	return difference.length()

static func collision_floor_local_y(collision_shape: CollisionShape3D) -> float:
	if collision_shape == null or collision_shape.shape == null:
		return 0.0
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return collision_shape.position.y
	return collision_shape.position.y - capsule.height * 0.5

static func has_clear_acoustic_path(
	world: World3D,
	listener_position: Vector3,
	source_position: Vector3,
	occlusion_mask: int = 1
) -> bool:
	if world == null:
		return false
	var query := PhysicsRayQueryParameters3D.create(
		listener_position,
		source_position,
		occlusion_mask
	)
	return world.direct_space_state.intersect_ray(query).is_empty()



static func has_visual_contact(
	world: World3D,
	observer_position: Vector3,
	target: Node3D,
	collision_mask: int,
	observer_rid: RID,
	fallback_target_height: float = 0.45,
	vertical_span_scale: float = 0.55,
	vertical_span_min: float = 0.20,
	vertical_span_max: float = 0.68,
	lateral_span_scale: float = 0.82,
	lateral_span_min: float = 0.15,
	lateral_span_max: float = 0.38,
	shoulder_height_ratio: float = 0.08,
	lower_body_ratio: float = 0.45
) -> bool:
	if world == null or target == null or not is_instance_valid(target):
		return false

	var target_center := target.global_position + Vector3.UP * fallback_target_height
	var half_height := maxf(fallback_target_height, 0.45)
	var lateral_radius := 0.28
	var shape_node := target.get_node_or_null("CollisionShape3D") as CollisionShape3D
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

	var toward_target := target.global_position - observer_position
	toward_target.y = 0.0
	if toward_target.length_squared() <= 0.0001:
		toward_target = Vector3.FORWARD
	else:
		toward_target = toward_target.normalized()
	var side := Vector3.UP.cross(toward_target).normalized()
	var vertical_span := clampf(
		half_height * vertical_span_scale,
		vertical_span_min,
		maxf(vertical_span_min, vertical_span_max)
	)
	var lateral_span := clampf(
		lateral_radius * lateral_span_scale,
		lateral_span_min,
		maxf(lateral_span_min, lateral_span_max)
	)

	# Merkez ilk sırada: açık görüşte eski tek-ray maliyeti korunur. Ek örnekler
	# yalnız merkez kapı/duvar tarafından kesildiğinde omuz/üst gövde görünürlüğünü
	# yakalamak için çalışır.
	var samples: Array[Vector3] = [
		target_center,
		target_center + Vector3.UP * vertical_span,
		target_center + side * lateral_span + Vector3.UP * (vertical_span * shoulder_height_ratio),
		target_center - side * lateral_span + Vector3.UP * (vertical_span * shoulder_height_ratio),
		target_center - Vector3.UP * (vertical_span * lower_body_ratio),
	]
	var space_state := world.direct_space_state
	for sample: Vector3 in samples:
		var query := PhysicsRayQueryParameters3D.create(
			observer_position,
			sample,
			collision_mask,
			[observer_rid]
		)
		query.collide_with_areas = true
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var collider := result.get("collider") as Node
		if _node_belongs_to_target(collider, target):
			return true
	return false


static func investigation_probe(
	center: Vector3,
	forward_hint: Vector3,
	probe_index: int,
	radius: float,
	diagonal_weight: float = 0.85
) -> Vector3:
	var forward := forward_hint
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = Vector3.FORWARD
	else:
		forward = forward.normalized()
	var right := Vector3(-forward.z, 0.0, forward.x).normalized()
	var directions: Array[Vector3] = [
		forward,
		(forward + right * diagonal_weight).normalized(),
		(forward - right * diagonal_weight).normalized(),
		right,
		-right,
		-forward,
	]
	var direction := directions[probe_index % directions.size()]
	var result := center + direction * maxf(radius, 0.1)
	result.y = center.y
	return result


static func _node_belongs_to_target(collider: Node, target: Node) -> bool:
	var current := collider
	var depth := 0
	while current != null and depth < 6:
		if current == target:
			return true
		current = current.get_parent()
		depth += 1
	return false
