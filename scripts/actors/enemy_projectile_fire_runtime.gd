extends RefCounted

const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")


static func fire(
	source: Node3D,
	target: Node3D,
	projectile_scene: PackedScene,
	facing_direction: Vector3,
	spawn_height: float,
	spawn_side_offset: float,
	spawn_forward_offset: float,
	target_height: float,
	lead_factor: float,
	max_lead_time: float,
	damage: int,
	yaw_degrees := 0.0,
	speed_scale := 1.0
) -> Node3D:
	if (
		source == null
		or target == null
		or not is_instance_valid(source)
		or not is_instance_valid(target)
		or projectile_scene == null
		or not source.is_inside_tree()
	):
		return null

	var projectile_parent := source.get_tree().current_scene
	if projectile_parent == null:
		return null
	var projectile_instance := projectile_scene.instantiate()
	if not (projectile_instance is Node3D):
		if projectile_instance != null:
			projectile_instance.queue_free()
		return null
	var projectile := projectile_instance as Node3D
	if not projectile.has_method("launch"):
		projectile.queue_free()
		return null
	projectile_parent.add_child(projectile)

	var spawn_forward := facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -source.global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	var spawn_right := spawn_forward.cross(Vector3.UP)
	if spawn_right.length_squared() <= 0.001:
		spawn_right = Vector3.RIGHT
	else:
		spawn_right = spawn_right.normalized()
	projectile.global_position = (
		source.global_position
		+ Vector3.UP * spawn_height
		+ spawn_right * spawn_side_offset
		+ spawn_forward * spawn_forward_offset
	)

	var projectile_speed := maxf(float(projectile.get("speed")), 0.1)
	projectile_speed *= maxf(speed_scale, 0.1)
	projectile.set("speed", projectile_speed)

	var target_position := target.global_position + Vector3.UP * target_height
	var target_velocity := Vector3.ZERO
	if target is CharacterBody3D and lead_factor > 0.0:
		target_velocity = (target as CharacterBody3D).velocity
		target_velocity.y = 0.0
	var travel_time := minf(
		EnemyCombatRuntime.calculate_intercept_time(
			projectile.global_position,
			target_position,
			target_velocity,
			projectile_speed
		),
		maxf(max_lead_time, 0.0)
	)
	if lead_factor > 0.0:
		target_position += target_velocity * travel_time * clampf(lead_factor, 0.0, 1.0)

	var shot_direction := (target_position - projectile.global_position).normalized()
	if absf(yaw_degrees) > 0.001:
		shot_direction = shot_direction.rotated(Vector3.UP, deg_to_rad(yaw_degrees)).normalized()
	projectile.call("launch", shot_direction, source, maxi(1, damage))
	return projectile
