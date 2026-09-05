extends RefCounted

const AETHER_CYAN := Color(0.24, 0.86, 1.0, 1.0)
const AETHER_WHITE := Color(0.72, 0.96, 1.0, 1.0)


static func spawn_attack_start(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.46, 0.92, 1.0, 0.48), 0.18, 1.14)
	_spawn_light(source, AETHER_CYAN, 2.6, 1.7, 0.16)


static func spawn_wake(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.20, 0.78, 1.0, 0.30), 0.15, 1.08)


static func spawn_impact(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.72, 0.97, 1.0, 0.64), 0.22, 1.30)
	_spawn_light(source, AETHER_WHITE, 4.4, 2.4, 0.22)


static func spawn_phase_departure(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.18, 0.74, 1.0, 0.54), 0.16, 1.24)
	_spawn_light(source, AETHER_CYAN, 3.2, 1.9, 0.14)


static func spawn_phase_arrival(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.82, 0.98, 1.0, 0.70), 0.18, 1.18)
	_spawn_light(source, AETHER_WHITE, 4.0, 2.2, 0.18)


static func spawn_hurt(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.46, 0.88, 1.0, 0.42), 0.12, 1.05)
	_spawn_light(source, AETHER_CYAN, 1.8, 1.25, 0.10)


static func spawn_death(source: Node3D, sprite: AnimatedSprite3D) -> void:
	_spawn_ghost(source, sprite, Color(0.70, 0.97, 1.0, 0.68), 0.42, 1.52)
	_spawn_ghost(source, sprite, Color(0.22, 0.72, 1.0, 0.44), 0.55, 1.72)
	_spawn_light(source, AETHER_WHITE, 5.2, 3.0, 0.42)


static func _spawn_ghost(
	source: Node3D,
	sprite: AnimatedSprite3D,
	tint: Color,
	duration: float,
	scale_multiplier: float
) -> void:
	if not _can_spawn(source, sprite):
		return
	var texture := sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	if texture == null:
		return
	var parent := source.get_tree().current_scene
	if parent == null:
		return

	var ghost := Sprite3D.new()
	ghost.texture = texture
	ghost.pixel_size = sprite.pixel_size
	ghost.billboard = sprite.billboard
	ghost.centered = sprite.centered
	ghost.offset = sprite.offset
	ghost.flip_h = sprite.flip_h
	ghost.flip_v = sprite.flip_v
	ghost.shaded = false
	ghost.alpha_cut = sprite.alpha_cut
	ghost.texture_filter = sprite.texture_filter
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ghost.render_priority = sprite.render_priority + 1
	ghost.modulate = tint
	parent.add_child(ghost)
	ghost.global_transform = sprite.global_transform
	ghost.scale = sprite.scale

	var target_scale := ghost.scale * scale_multiplier
	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, duration)
	tween.tween_property(ghost, "scale", target_scale, duration)
	tween.set_parallel(false)
	tween.tween_callback(Callable(ghost, "queue_free"))


static func _spawn_light(
	source: Node3D,
	color: Color,
	energy: float,
	light_range: float,
	duration: float
) -> void:
	if source == null or not is_instance_valid(source) or not source.is_inside_tree():
		return
	var parent := source.get_tree().current_scene
	if parent == null:
		return
	var light := OmniLight3D.new()
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = source.global_position + Vector3.UP * 0.72

	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, duration)
	tween.tween_callback(Callable(light, "queue_free"))


static func _can_spawn(source: Node3D, sprite: AnimatedSprite3D) -> bool:
	return (
		source != null
		and sprite != null
		and is_instance_valid(source)
		and is_instance_valid(sprite)
		and source.is_inside_tree()
		and sprite.sprite_frames != null
		and sprite.sprite_frames.has_animation(sprite.animation)
		and sprite.frame >= 0
		and sprite.frame < sprite.sprite_frames.get_frame_count(sprite.animation)
	)
