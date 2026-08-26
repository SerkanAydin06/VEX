class_name VexHudWeaponPresenter
extends Node

const ADS_RETICLE_SCENE := preload("res://scenes/ui/ads_reticle.tscn")
const ADS_SCREEN_PIVOT := Vector2(960.0, 540.0)

var _weapon_layer: Control = null
var _weapon_sprites: Dictionary = {}
var _current_weapon_id: StringName = &""
var _inactive_seconds := 0.0
var _ads_reticle: Control = null


func setup(weapon_layer: Control) -> void:
	_weapon_layer = weapon_layer
	_ensure_ads_reticle()


func set_current_weapon(weapon_id: StringName) -> void:
	_current_weapon_id = weapon_id
	_set_ads_reticle_fire_suppressed(false)
	if weapon_id == &"":
		_set_weapon_sprite_visibility(weapon_id)
		return
	var definition := _get_weapon_definition(weapon_id)
	if definition != null and definition.supports_lowered_pose:
		_inactive_seconds = 0.0
	_ensure_weapon_sprite_ready(weapon_id)
	_set_weapon_sprite_visibility(weapon_id)
	var sprite := _get_weapon_sprite(weapon_id)
	if sprite != null and sprite.animation not in [&"fire", &"aim_fire", &"reload"]:
		sprite.play(&"idle")


func play_action(weapon_id: StringName, action: StringName) -> void:
	_current_weapon_id = weapon_id
	if weapon_id == &"":
		_set_ads_reticle_fire_suppressed(false)
		_set_weapon_sprite_visibility(weapon_id)
		return
	var definition := _get_weapon_definition(weapon_id)
	if definition != null and definition.supports_lowered_pose and action in [&"equip", &"fire", &"reload", &"empty"]:
		_inactive_seconds = 0.0
	_ensure_weapon_sprite_ready(weapon_id)
	var sprite := _get_weapon_sprite(weapon_id)
	_set_weapon_sprite_visibility(weapon_id)
	if sprite == null:
		_set_ads_reticle_fire_suppressed(false)
		return
	var requested_animation := action
	if (
		action == &"fire"
		and definition != null
		and definition.supports_ads_pose
		and _is_weapon_ads_active()
		and sprite.sprite_frames != null
		and sprite.sprite_frames.has_animation(&"aim_fire")
	):
		requested_animation = &"aim_fire"
	_set_ads_reticle_fire_suppressed(requested_animation == &"aim_fire")
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(requested_animation):
		if action == &"fire":
			sprite.stop()
			sprite.frame = 0
			sprite.play(requested_animation)
		else:
			sprite.play(requested_animation)
	elif sprite.sprite_frames != null and sprite.sprite_frames.has_animation(&"idle"):
		sprite.play(&"idle")


func update(delta: float, blocked: bool) -> void:
	# ADS görseli, kamera ve hitscan aynı tek gameplay durumunu kullanır.
	# Harita/ölüm gibi bloklu durumlarda crosshair görünürlüğünü HUD yönetir.
	if not blocked:
		_sync_ads_crosshair_visibility()
	if blocked or _current_weapon_id == &"":
		return
	var definition := _get_weapon_definition(_current_weapon_id)
	if definition == null or (not definition.supports_ads_pose and not definition.supports_lowered_pose):
		return
	var sprite := _get_weapon_sprite(_current_weapon_id)
	if sprite == null or not sprite.visible:
		return
	if definition.hud_auto_lower_enabled:
		_inactive_seconds += delta
	else:
		_inactive_seconds = 0.0
	if sprite.animation in [&"fire", &"aim_fire", &"reload", &"equip"] and sprite.is_playing():
		return
	_apply_rest_pose(sprite, definition)


func _ensure_ads_reticle() -> void:
	if _ads_reticle != null and is_instance_valid(_ads_reticle):
		return
	if _weapon_layer == null:
		return
	var hud_root := _weapon_layer.get_parent() as Control
	if hud_root == null:
		return
	_ads_reticle = ADS_RETICLE_SCENE.instantiate() as Control
	if _ads_reticle == null:
		push_warning("ADS reticle sahnesinin kökü Control olmalı")
		return
	hud_root.add_child(_ads_reticle)


func _set_ads_reticle_fire_suppressed(suppressed: bool) -> void:
	if _ads_reticle == null or not is_instance_valid(_ads_reticle):
		return
	if _ads_reticle.has_method("set_fire_animation_suppressed"):
		_ads_reticle.call("set_fire_animation_suppressed", suppressed)


func _ensure_weapon_sprite_ready(weapon_id: StringName) -> void:
	if weapon_id == &"" or _weapon_sprites.has(weapon_id) or _weapon_layer == null:
		return
	var definition := _get_weapon_definition(weapon_id)
	if definition == null or definition.hud_view_scene == null:
		push_warning("HUD weapon presentation missing for %s" % str(weapon_id))
		return
	var sprite := definition.hud_view_scene.instantiate() as AnimatedSprite2D
	if sprite == null:
		push_warning("HUD weapon presentation root must be AnimatedSprite2D for %s" % str(weapon_id))
		return
	sprite.name = "WeaponView_%s" % str(weapon_id)
	_weapon_layer.add_child(sprite)
	_weapon_sprites[weapon_id] = sprite
	var finished_callable := _on_weapon_animation_finished.bind(sprite, weapon_id)
	if not sprite.animation_finished.is_connected(finished_callable):
		sprite.animation_finished.connect(finished_callable)
	_configure_weapon_frame_alignment(sprite, definition)


func _get_weapon_sprite(weapon_id: StringName) -> AnimatedSprite2D:
	return _weapon_sprites.get(weapon_id) as AnimatedSprite2D


func _set_weapon_sprite_visibility(weapon_id: StringName) -> void:
	for stored_id: Variant in _weapon_sprites.keys():
		var sprite := _weapon_sprites[stored_id] as AnimatedSprite2D
		if sprite != null:
			sprite.visible = StringName(str(stored_id)) == weapon_id


func _configure_weapon_frame_alignment(sprite: AnimatedSprite2D, definition: WeaponDefinition) -> void:
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(&"idle"):
		return
	var idle_texture := sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if idle_texture == null:
		return
	sprite.set_meta("vex_base_position", sprite.position)
	sprite.set_meta("vex_base_scale", sprite.scale)
	sprite.set_meta("vex_ads_scale_multiplier", definition.hud_ads_scale_multiplier)
	var reference_anchor := _get_texture_visual_anchor(idle_texture)
	var zoom_visual_anchor := reference_anchor
	if definition.supports_ads_pose and sprite.sprite_frames.has_animation(&"zoom"):
		var zoom_texture := sprite.sprite_frames.get_frame_texture(&"zoom", 0)
		if zoom_texture != null:
			zoom_visual_anchor = _get_texture_visual_anchor(zoom_texture) + definition.hud_zoom_offset
	var offsets: Dictionary = {}
	for animation_name: StringName in sprite.sprite_frames.get_animation_names():
		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		for frame_index: int in range(frame_count):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			if texture == null:
				continue
			var frame_key := _weapon_frame_key(animation_name, frame_index)
			if definition.supports_ads_pose and animation_name == &"aim_fire":
				offsets[frame_key] = zoom_visual_anchor - _get_texture_visual_anchor(texture) + definition.hud_aim_fire_offset
			elif definition.supports_ads_pose and animation_name == &"zoom":
				offsets[frame_key] = definition.hud_zoom_offset
			elif definition.supports_lowered_pose and animation_name == &"lowered":
				offsets[frame_key] = definition.hud_lowered_offset
			else:
				offsets[frame_key] = reference_anchor - _get_texture_visual_anchor(texture)
	sprite.set_meta("vex_frame_offsets", offsets)
	var animation_callable := _apply_weapon_frame_alignment.bind(sprite)
	if not sprite.animation_changed.is_connected(animation_callable):
		sprite.animation_changed.connect(animation_callable)
	var frame_callable := _apply_weapon_frame_alignment.bind(sprite)
	if not sprite.frame_changed.is_connected(frame_callable):
		sprite.frame_changed.connect(frame_callable)
	_apply_weapon_frame_alignment(sprite)


func _get_texture_visual_anchor(texture: Texture2D) -> Vector2:
	var texture_size := texture.get_size()
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2.ZERO
	var used_rect := image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Vector2.ZERO
	return Vector2(
		float(used_rect.position.x) + float(used_rect.size.x) * 0.5 - texture_size.x * 0.5,
		float(used_rect.position.y + used_rect.size.y) - texture_size.y * 0.5
	)


func _apply_weapon_frame_alignment(sprite: AnimatedSprite2D) -> void:
	if sprite == null or not sprite.has_meta("vex_frame_offsets"):
		return
	var offsets := sprite.get_meta("vex_frame_offsets") as Dictionary
	var frame_offset: Vector2 = offsets.get(_weapon_frame_key(sprite.animation, sprite.frame), Vector2.ZERO)
	sprite.offset = frame_offset
	_apply_weapon_pose_transform(sprite)


func _apply_weapon_pose_transform(sprite: AnimatedSprite2D) -> void:
	if sprite == null or not sprite.has_meta("vex_base_position") or not sprite.has_meta("vex_base_scale"):
		return
	var base_position: Vector2 = sprite.get_meta("vex_base_position", sprite.position)
	var base_scale: Vector2 = sprite.get_meta("vex_base_scale", sprite.scale)
	var ads_scale_multiplier := float(sprite.get_meta("vex_ads_scale_multiplier", 1.0))
	var uses_ads_transform := sprite.animation in [&"zoom", &"aim_fire"] and ads_scale_multiplier > 1.0
	if not uses_ads_transform:
		sprite.position = base_position
		sprite.scale = base_scale
		return
	# Sprite'ı ekran merkezindeki gerçek ADS hedef noktası etrafında büyüt.
	# Böylece + / arpacık / optik merkezi sabit kalırken silah gövdesi alta doğru büyür.
	sprite.position = ADS_SCREEN_PIVOT + (base_position - ADS_SCREEN_PIVOT) * ads_scale_multiplier
	sprite.scale = base_scale * ads_scale_multiplier


func _weapon_frame_key(animation_name: StringName, frame_index: int) -> String:
	return "%s:%d" % [String(animation_name), frame_index]


func _on_weapon_animation_finished(sprite: AnimatedSprite2D, weapon_id: StringName) -> void:
	if weapon_id != _current_weapon_id or sprite != _get_weapon_sprite(_current_weapon_id):
		return
	if sprite.animation == &"aim_fire":
		_set_ads_reticle_fire_suppressed(false)
	var definition := _get_weapon_definition(weapon_id)
	if definition != null and (definition.supports_ads_pose or definition.supports_lowered_pose):
		_apply_rest_pose(sprite, definition)
	elif sprite.animation != &"idle":
		sprite.play(&"idle")


func _apply_rest_pose(sprite: AnimatedSprite2D, definition: WeaponDefinition) -> void:
	if sprite == null or definition == null:
		return
	var target_animation: StringName = &"idle"
	if definition.supports_ads_pose and _is_weapon_ads_active() and sprite.sprite_frames.has_animation(&"zoom"):
		target_animation = &"zoom"
	elif (
		definition.supports_lowered_pose
		and definition.hud_auto_lower_enabled
		and _inactive_seconds >= definition.hud_lower_after_seconds
		and sprite.sprite_frames.has_animation(&"lowered")
	):
		target_animation = &"lowered"
	if sprite.animation != target_animation:
		sprite.play(target_animation)


func _is_weapon_ads_active() -> bool:
	var player := GameState.player as VexPlayer
	return player != null and is_instance_valid(player) and player.is_aiming


func _sync_ads_crosshair_visibility() -> void:
	if GameState.hud == null or not is_instance_valid(GameState.hud):
		return
	var crosshair_node := GameState.hud.get("crosshair") as TextureRect
	if crosshair_node != null:
		crosshair_node.visible = not _is_weapon_ads_active()


func _get_weapon_definition(weapon_id: StringName) -> WeaponDefinition:
	if GameState.player == null or not is_instance_valid(GameState.player):
		return null
	var controller := GameState.player.get_node_or_null("WeaponController") as VexWeaponController
	if controller == null:
		return null
	return controller.get_weapon_definition(weapon_id)
