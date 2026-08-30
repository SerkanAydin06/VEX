class_name VexEnemyHybridBase
extends "res://scripts/actors/enemy_combatant_base.gd"

# Menzilli saldırı ile yakın saldırıyı aynı state machine içinde güvenli biçimde
# seçen ortak aile. Görünür Inspector şeması üst sınıfta kalır; hibrit ayarlar
# 09 - Özel Yetenekler içindeki tip güvenli Resource üzerinden düzenlenir.

enum DirectionalView {
	FRONT,
	FRONT_SIDE,
	SIDE,
	BACK,
}

var _hybrid_ability: VexEnemyHybridAbilitySettings


func get_behavior_family() -> StringName:
	return &"hybrid"


func _ready() -> void:
	_hybrid_ability = special_ability_settings as VexEnemyHybridAbilitySettings
	if _hybrid_ability == null:
		_hybrid_ability = VexEnemyHybridAbilitySettings.new()
		special_ability_settings = _hybrid_ability
		push_warning("Hibrit düşman ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func _refresh_close_combat_visibility() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _is_player_in_melee_envelope(_hybrid_ability.melee_range_tolerance):
		return
	if not _check_line_of_sight():
		return
	_player_visible = true
	_alerted = true
	_seconds_without_sight = 0.0
	_last_seen_position = _player.global_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true


func _uses_cover_reposition_tactics() -> bool:
	# Oyuncu yakın saldırı alanına girdiyse kısmi görünürlük yüzünden geri/yan
	# kaçmak yerine yakın saldırı kararını state machine'e teslim et.
	if _player != null and is_instance_valid(_player) and _is_player_in_melee_envelope():
		return false
	return super._uses_cover_reposition_tactics()


func _attempt_attack() -> void:
	if _attack_locked or _player == null or not is_instance_valid(_player):
		return
	var use_melee := (
		_hybrid_ability.prefer_melee_when_close
		and _is_player_in_melee_envelope()
	)
	_begin_hybrid_attack(use_melee)


func _begin_hybrid_attack(use_melee: bool) -> void:
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	_stop_horizontal_motion()
	_face_toward_position(_player.global_position)

	var attack_animation: StringName = &"attack_close" if use_melee else &"attack"
	_set_attack_view_mirroring()
	if _has_animation(attack_animation):
		animated_sprite.play(attack_animation)
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var authored_windup := _hybrid_ability.melee_windup if use_melee else attack_windup
	var authored_cooldown := _hybrid_ability.melee_cooldown if use_melee else attack_cooldown
	var runtime_windup := maxf(0.01, authored_windup * windup_scale)
	var runtime_cooldown := maxf(runtime_windup, authored_cooldown * cooldown_scale)

	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return

	if use_melee:
		_resolve_melee_hit()
	else:
		_resolve_ranged_shot()
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")

	var recovery := maxf(0.0, runtime_cooldown - runtime_windup)
	if recovery > 0.0:
		await get_tree().create_timer(recovery).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _resolve_melee_hit() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if not _is_player_in_melee_envelope(_hybrid_ability.melee_range_tolerance):
		return
	if not _check_line_of_sight():
		return
	var runtime_damage := _scaled_hybrid_damage(_hybrid_ability.melee_damage)
	var hit_position := _player.global_position + Vector3.UP * _hybrid_ability.melee_hit_height
	if _player.has_method("take_damage"):
		_player.call("take_damage", runtime_damage, hit_position, self)
	GameState.emit_noise(global_position, _hybrid_ability.melee_noise_loudness, self)


func _resolve_ranged_shot() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var still_in_range := (
		_horizontal_distance(global_position, _player.global_position)
		<= attack_range + attack_range_tolerance
	)
	if still_in_range and _check_line_of_sight():
		_fire_projectile()


func _is_player_in_melee_envelope(extra_tolerance: float = 0.0) -> bool:
	return (
		_player != null
		and is_instance_valid(_player)
		and _horizontal_distance(global_position, _player.global_position)
		<= _hybrid_ability.melee_trigger_range + extra_tolerance
	)


func _scaled_hybrid_damage(base_damage: int) -> int:
	if not apply_difficulty_scaling:
		return maxi(1, base_damage)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	return maxi(1, int(round(float(base_damage) * damage_scale)))


func _play_directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> void:
	var target_animation := _directional_animation(front_animation, back_animation)
	if not _has_animation(target_animation):
		return
	if animated_sprite.animation == target_animation and animated_sprite.is_playing():
		return
	var previous_frame := animated_sprite.frame
	animated_sprite.play(target_animation)
	var frame_count := animated_sprite.sprite_frames.get_frame_count(target_animation)
	if frame_count > 0:
		animated_sprite.frame = mini(previous_frame, frame_count - 1)
	_apply_frame_ground_offset()


func _directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> StringName:
	var view_data := _directional_view_data()
	var view := int(view_data["view"])
	var mirror := bool(view_data["mirror"])
	animated_sprite.flip_h = mirror

	if view == DirectionalView.FRONT_SIDE:
		var diagonal := _directional_variant(front_animation, &"_front_side")
		if _has_animation(diagonal):
			return diagonal
	elif view == DirectionalView.SIDE:
		var side := _directional_variant(front_animation, &"_side")
		if _has_animation(side):
			return side
	elif view == DirectionalView.BACK and _has_animation(back_animation):
		animated_sprite.flip_h = false
		return back_animation
	return front_animation


func _directional_variant(base_animation: StringName, suffix: StringName) -> StringName:
	return StringName(String(base_animation) + String(suffix))


func _directional_view_data() -> Dictionary:
	var observer_direction := _direction_to_observer()
	if observer_direction.length_squared() <= 0.001:
		return {"view": DirectionalView.FRONT, "mirror": false}
	var facing := _facing_direction
	facing.y = 0.0
	if facing.length_squared() <= 0.001:
		facing = Vector3.FORWARD
	else:
		facing = facing.normalized()

	var dot_value := clampf(facing.dot(observer_direction), -1.0, 1.0)
	var angle := rad_to_deg(acos(dot_value))
	var side_sign := facing.cross(observer_direction).y
	var source_is_right := _hybrid_ability.source_frames_face_right
	var observer_is_right := side_sign < 0.0
	var should_mirror := (
		_hybrid_ability.mirror_opposite_directions
		and observer_is_right != source_is_right
	)

	if angle <= _hybrid_ability.front_half_angle_degrees:
		return {"view": DirectionalView.FRONT, "mirror": false}
	if angle <= _hybrid_ability.front_diagonal_limit_degrees:
		return {"view": DirectionalView.FRONT_SIDE, "mirror": should_mirror}
	if angle <= _hybrid_ability.side_limit_degrees:
		return {"view": DirectionalView.SIDE, "mirror": should_mirror}
	return {"view": DirectionalView.BACK, "mirror": false}


func _direction_to_observer() -> Vector3:
	var observer_position := Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		observer_position = camera.global_position
	elif _player != null and is_instance_valid(_player):
		observer_position = _player.global_position
	else:
		return Vector3.ZERO
	var direction := observer_position - global_position
	direction.y = 0.0
	return direction.normalized() if direction.length_squared() > 0.001 else Vector3.ZERO


func _set_attack_view_mirroring() -> void:
	var view_data := _directional_view_data()
	animated_sprite.flip_h = bool(view_data["mirror"])


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	match animation_name:
		&"idle_side":
			return _hybrid_ability.idle_side_frame_y_offsets
		&"walk_side":
			return _hybrid_ability.walk_side_frame_y_offsets
		&"idle_front_side":
			return _hybrid_ability.idle_front_side_frame_y_offsets
		&"walk_front_side":
			return _hybrid_ability.walk_front_side_frame_y_offsets
		&"attack_close":
			return _hybrid_ability.attack_close_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
