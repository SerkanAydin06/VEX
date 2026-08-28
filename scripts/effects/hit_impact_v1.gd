class_name VexHitImpactV1
extends Node3D

const WORLD_TEXTURE_PATH := "res://assets/impacts/impact_world_v1.png"
# V1 flesh texture remains part of the asset contract, but enemy impacts no longer
# render it as a world-anchored quad. Flesh hits are transient color-matched debris.
const FLESH_TEXTURE_PATH := "res://assets/impacts/impact_flesh_v1.png"
const MAX_WORLD_IMPACTS := 72
const MAX_FLESH_IMPACTS := 24
const DEFAULT_FLESH_COLOR := Color(0.42, 0.025, 0.035, 1.0)
const FLESH_QUERY_RADIUS := 0.24


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
	effect.global_position = hit_position + normal * 0.018
	effect._align_to_normal(normal)
	var fragment_color := effect._sample_enemy_hit_color(
		hit_position - normal * 0.035
	)
	effect._build_flesh_fragment_burst(fragment_color)
	effect._schedule_free(0.48)


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


func _sample_enemy_hit_color(hit_position: Vector3) -> Color:
	var enemy := _find_enemy_near_hit(hit_position)
	if enemy == null:
		return DEFAULT_FLESH_COLOR
	var visual := _find_primary_sprite(enemy)
	if visual == null:
		return DEFAULT_FLESH_COLOR
	var texture := _current_sprite_texture(visual)
	if texture == null:
		return _fallback_visual_color(visual)
	var image := _texture_image(texture)
	if image == null or image.is_empty():
		return _fallback_visual_color(visual)

	var sampled := _sample_sprite_image_at_hit(visual, image, hit_position)
	if sampled.a <= 0.01:
		sampled = _average_opaque_color(image)
	if sampled.a <= 0.01:
		return _fallback_visual_color(visual)

	var tint := visual.modulate
	sampled.r *= tint.r
	sampled.g *= tint.g
	sampled.b *= tint.b
	sampled.a = 1.0
	return _prepare_fragment_color(sampled)


func _texture_image(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var atlas_texture := texture as AtlasTexture
		if atlas_texture.atlas == null:
			return null
		var atlas_image := atlas_texture.atlas.get_image()
		if atlas_image == null or atlas_image.is_empty():
			return null
		var region := atlas_texture.region
		var region_rect := Rect2i(
			roundi(region.position.x),
			roundi(region.position.y),
			maxi(1, roundi(region.size.x)),
			maxi(1, roundi(region.size.y))
		)
		return atlas_image.get_region(region_rect)
	return texture.get_image()


func _find_enemy_near_hit(hit_position: Vector3) -> Node:
	var world := get_world_3d()
	if world != null:
		var sphere := SphereShape3D.new()
		sphere.radius = FLESH_QUERY_RADIUS
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = sphere
		query.transform = Transform3D(Basis.IDENTITY, hit_position)
		query.collision_mask = 4
		query.collide_with_bodies = true
		query.collide_with_areas = true
		var hits := world.direct_space_state.intersect_shape(query, 12)
		var closest: Node = null
		var closest_distance := INF
		for hit: Dictionary in hits:
			var collider := hit.get("collider") as Node
			var enemy := _enemy_ancestor(collider)
			if enemy == null:
				continue
			var enemy_3d := enemy as Node3D
			if enemy_3d == null:
				return enemy
			var distance := enemy_3d.global_position.distance_squared_to(hit_position)
			if distance < closest_distance:
				closest_distance = distance
				closest = enemy
		if closest != null:
			return closest

	# Fallback for enemies whose collider was disabled on the same hit frame.
	var tree := get_tree()
	if tree == null:
		return null
	var nearest: Node = null
	var nearest_distance := 16.0
	for candidate: Node in tree.get_nodes_in_group("enemy"):
		var candidate_3d := candidate as Node3D
		if candidate_3d == null or not is_instance_valid(candidate_3d):
			continue
		var distance := candidate_3d.global_position.distance_squared_to(hit_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest = candidate
	return nearest


func _enemy_ancestor(start: Node) -> Node:
	var current := start
	var depth := 0
	while current != null and depth < 6:
		if current.is_in_group("enemy"):
			return current
		current = current.get_parent()
		depth += 1
	return null


func _find_primary_sprite(root: Node) -> SpriteBase3D:
	var animated := _find_animated_sprite(root)
	if animated != null:
		return animated
	return _find_static_sprite(root)


func _find_animated_sprite(root: Node) -> AnimatedSprite3D:
	for child: Node in root.get_children():
		if child is AnimatedSprite3D and (child as AnimatedSprite3D).visible:
			return child as AnimatedSprite3D
	for child: Node in root.get_children():
		var nested := _find_animated_sprite(child)
		if nested != null:
			return nested
	return null


func _find_static_sprite(root: Node) -> Sprite3D:
	for child: Node in root.get_children():
		if child is Sprite3D:
			var sprite := child as Sprite3D
			if sprite.visible and sprite.texture != null and not str(sprite.name).to_lower().contains("shadow"):
				return sprite
	for child: Node in root.get_children():
		var nested := _find_static_sprite(child)
		if nested != null:
			return nested
	return null


func _current_sprite_texture(visual: SpriteBase3D) -> Texture2D:
	if visual is AnimatedSprite3D:
		var animated := visual as AnimatedSprite3D
		if animated.sprite_frames == null:
			return null
		return animated.sprite_frames.get_frame_texture(animated.animation, animated.frame)
	if visual is Sprite3D:
		return (visual as Sprite3D).texture
	return null


func _sample_sprite_image_at_hit(
	visual: SpriteBase3D,
	image: Image,
	hit_position: Vector3
) -> Color:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return Color(0.0, 0.0, 0.0, 0.0)
	var pixel_size := maxf(visual.pixel_size, 0.00001)
	var delta := hit_position - visual.global_position
	var view_right := camera.global_transform.basis.x.normalized()
	var view_up := camera.global_transform.basis.y.normalized()
	var local_x_pixels := delta.dot(view_right) / pixel_size
	var local_y_pixels := -delta.dot(view_up) / pixel_size
	var pixel_x := local_x_pixels - visual.offset.x
	var pixel_y := local_y_pixels - visual.offset.y
	if visual.centered:
		pixel_x += float(image.get_width()) * 0.5
		pixel_y += float(image.get_height()) * 0.5
	if visual.flip_h:
		pixel_x = float(image.get_width() - 1) - pixel_x
	if visual.flip_v:
		pixel_y = float(image.get_height() - 1) - pixel_y

	var center_x := clampi(roundi(pixel_x), 0, image.get_width() - 1)
	var center_y := clampi(roundi(pixel_y), 0, image.get_height() - 1)
	var sampled := _sample_opaque_neighborhood(image, center_x, center_y, 3)
	if sampled.a > 0.01:
		return sampled
	return _sample_opaque_neighborhood(image, center_x, center_y, 12)


func _sample_opaque_neighborhood(
	image: Image,
	center_x: int,
	center_y: int,
	radius: int
) -> Color:
	var rgb_sum := Vector3.ZERO
	var total_weight := 0.0
	var step := maxi(1, int(radius / 3.0))
	for y: int in range(center_y - radius, center_y + radius + 1, step):
		if y < 0 or y >= image.get_height():
			continue
		for x: int in range(center_x - radius, center_x + radius + 1, step):
			if x < 0 or x >= image.get_width():
				continue
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.12:
				continue
			var weight := pixel.a
			rgb_sum += Vector3(pixel.r, pixel.g, pixel.b) * weight
			total_weight += weight
	if total_weight <= 0.0001:
		return Color(0.0, 0.0, 0.0, 0.0)
	return Color(
		rgb_sum.x / total_weight,
		rgb_sum.y / total_weight,
		rgb_sum.z / total_weight,
		1.0
	)


func _average_opaque_color(image: Image) -> Color:
	var rgb_sum := Vector3.ZERO
	var total_weight := 0.0
	var step_x := maxi(1, int(image.get_width() / 18.0))
	var step_y := maxi(1, int(image.get_height() / 18.0))
	for y: int in range(0, image.get_height(), step_y):
		for x: int in range(0, image.get_width(), step_x):
			var pixel := image.get_pixel(x, y)
			if pixel.a < 0.18:
				continue
			var weight := pixel.a
			rgb_sum += Vector3(pixel.r, pixel.g, pixel.b) * weight
			total_weight += weight
	if total_weight <= 0.0001:
		return Color(0.0, 0.0, 0.0, 0.0)
	return Color(
		rgb_sum.x / total_weight,
		rgb_sum.y / total_weight,
		rgb_sum.z / total_weight,
		1.0
	)


func _fallback_visual_color(visual: SpriteBase3D) -> Color:
	var tint := visual.modulate
	if tint.r > 0.92 and tint.g > 0.92 and tint.b > 0.92:
		return DEFAULT_FLESH_COLOR
	tint.a = 1.0
	return _prepare_fragment_color(tint)


func _prepare_fragment_color(source: Color) -> Color:
	var result := source
	result.a = 1.0
	var peak := maxf(result.r, maxf(result.g, result.b))
	if peak <= 0.001:
		return DEFAULT_FLESH_COLOR
	if peak < 0.20:
		var boost := 0.20 / peak
		result.r = minf(1.0, result.r * boost)
		result.g = minf(1.0, result.g * boost)
		result.b = minf(1.0, result.b * boost)
	return result


func _build_flesh_fragment_burst(color: Color) -> void:
	_build_fragment_layer(
		color,
		13,
		0.34,
		1.7,
		4.9,
		Vector3(0.032, 0.022, 0.014),
		0.65,
		1.55,
		Vector3(0.0, -7.5, 0.0)
	)
	var darker := Color(color.r * 0.72, color.g * 0.72, color.b * 0.72, 1.0)
	_build_droplet_layer(
		darker,
		7,
		0.26,
		2.4,
		6.0,
		0.6,
		1.35,
		Vector3(0.0, -9.0, 0.0)
	)


func _build_fragment_layer(
	color: Color,
	amount: int,
	lifetime: float,
	velocity_min: float,
	velocity_max: float,
	mesh_size: Vector3,
	scale_min: float,
	scale_max: float,
	gravity: Vector3
) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Fragments"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.72
	particles.local_coords = false

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 74.0
	process.initial_velocity_min = velocity_min
	process.initial_velocity_max = velocity_max
	process.gravity = gravity
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.angular_velocity_min = -520.0
	process.angular_velocity_max = 520.0
	process.color = color
	particles.process_material = process

	var fragment_mesh := BoxMesh.new()
	fragment_mesh.size = mesh_size
	var fragment_material := StandardMaterial3D.new()
	fragment_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fragment_material.albedo_color = color
	fragment_mesh.material = fragment_material
	particles.draw_pass_1 = fragment_mesh

	add_child(particles)
	particles.emitting = true
	particles.restart()


func _build_droplet_layer(
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
	particles.name = "Droplets"
	particles.amount = amount
	particles.lifetime = lifetime
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.randomness = 0.78
	particles.local_coords = false

	var process := ParticleProcessMaterial.new()
	process.direction = Vector3(0.0, 0.0, 1.0)
	process.spread = 82.0
	process.initial_velocity_min = velocity_min
	process.initial_velocity_max = velocity_max
	process.gravity = gravity
	process.scale_min = scale_min
	process.scale_max = scale_max
	process.color = color
	particles.process_material = process

	var droplet_mesh := SphereMesh.new()
	droplet_mesh.radius = 0.014
	droplet_mesh.height = 0.028
	var droplet_material := StandardMaterial3D.new()
	droplet_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	droplet_material.albedo_color = color
	droplet_mesh.material = droplet_material
	particles.draw_pass_1 = droplet_mesh

	add_child(particles)
	particles.emitting = true
	particles.restart()


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
