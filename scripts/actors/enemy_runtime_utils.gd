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

