class_name VexHitImpactV1
extends Node3D

const WORLD_TEXTURE_PATH := "res://assets/impacts/impact_world_v1.png"
const FLESH_TEXTURE_PATH := "res://assets/impacts/impact_flesh_v1.png"
const MAX_WORLD_IMPACTS := 72
const MAX_FLESH_IMPACTS := 24


static func spawn_world(
	parent: Node,
	hit_position: Vector3,
	hit_normal: Vector3,
	shot_direction: Vector3 = Vector3.ZERO
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	_prune_group(parent, &"vex_world_impacts", MAX_WORLD_IMPACTS)
	var effect := VexHitImpactV1.new()
	effect.name = "WorldHitImpactV1"
	parent.add_child(effect)
	effect.add_to_group(&"vex_world_impacts")
	var normal := _safe_normal(hit_normal, -shot_direction)
	effect.global_position = hit_position + normal * 0.012
	effect._align_to_normal(normal)
	effect._build_world_visual()
	effect._build_particle_burst(
		Color(0.70, 0.64, 0.55, 1.0),
		9,
		0.34,
		1.4,
		3.8,
		0.012,
		0.032,
		Vector3(0.0, -5.0, 0.0)
	)
	effect._schedule_free(7.0)


static func spawn_flesh(
	parent: Node,
	hit_position: Vector3,
	hit_normal: Vector3,
	shot_direction: Vector3 = Vector3.ZERO
) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	_prune_group(parent, &"vex_flesh_impacts", MAX_FLESH_IMPACTS)
	var effect := VexHitImpactV1.new()
	effect.name = "FleshHitImpactV1"
	parent.add_child(effect)
	effect.add_to_group(&"vex_flesh_impacts")
	var normal := _safe_normal(hit_normal, -shot_direction)
	effect.global_position = hit_position + normal * 0.025
	effect._align_to_normal(normal)
	effect._build_flesh_visual()
	effect._build_particle_burst(
		Color(0.42, 0.012, 0.018, 1.0),
		14,
		0.48,
		1.8,
		4.8,
		0.018,
		0.055,
		Vector3(0.0, -8.5, 0.0)
	)
	effect._schedule_free(0.62)


static func _safe_normal(primary: Vector3, fallback: Vector3) -> Vector3:
	if primary.length_squared() > 0.000001:
		return primary.normalized()
	if fallback.length_squared() > 0.000001:
		return fallback.normalized()
	return Vector3.UP


static func _prune_group(parent: Node, group_name: StringName, limit: int) -> void:
	var tree := parent.get_tree()
	if tree == null:
		return
	var active := tree.get_nodes_in_group(group_name)
	while active.size() >= limit:
		var oldest := active.pop_front() as Node
		if oldest != null and is_instance_valid(oldest):
			oldest.queue_free()


func _align_to_normal(normal: Vector3) -> void:
	var z_axis := normal.normalized()
	var helper := Vector3.UP
	if absf(z_axis.dot(helper)) > 0.96:
		helper = Vector3.FORWARD
	var x_axis := helper.cross(z_axis).normalized()
	var y_axis := z_axis.cross(x_axis).normalized()
	global_transform = Transform3D(Basis(x_axis, y_axis, z_axis), global_position)


func _build_world_visual() -> void:
	var texture := _load_optional_texture(WORLD_TEXTURE_PATH)
	if texture == null:
		return
	var mark := MeshInstance3D.new()
	mark.name = "BulletMark"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.12, 0.12)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE
	quad.material = material
	mark.mesh = quad
	add_child(mark)


func _build_flesh_visual() -> void:
	var texture := _load_optional_texture(FLESH_TEXTURE_PATH)
	if texture == null:
		return
	var splash := MeshInstance3D.new()
	splash.name = "FleshSplash"
	var quad := QuadMesh.new()
	quad.size = Vector2(0.34, 0.34)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.albedo_texture = texture
	material.albedo_color = Color.WHITE
	quad.material = material
	splash.mesh = quad
	add_child(splash)


func _build_particle_burst(
	color: Color,
	amount: int,
	lifetime: float,
	velocity_min: float,
	velocity_max: float,
	scale_min: float,
	scale_max: float,
	gravity: Vector3
) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Burst"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.45
	particles.local_coords = false

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 58.0
	process.initial_velocity_min = velocity_min
	process.initial_velocity_max = velocity_max
	process.gravity = gravity
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.color = color
	particles.process_material = process

	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.018
	particle_mesh.height = 0.036
	var particle_material := StandardMaterial3D.new()
	particle_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	particle_material.albedo_color = color
	particle_mesh.material = particle_material
	particles.draw_pass_1 = particle_mesh

	add_child(particles)
	particles.emitting = true
	particles.restart()


func _load_optional_texture(path: String) -> Texture2D:
	if not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


func _schedule_free(seconds: float) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.wait_time = seconds
	timer.timeout.connect(queue_free)
	add_child(timer)
	timer.start()
