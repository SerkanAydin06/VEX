class_name VexEnemyHybridBase
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

# Menzilli saldırı ile yakın saldırıyı aynı state machine içinde güvenli biçimde
# seçen ortak aile. Görünür Inspector şeması üst sınıfta kalır; hibrit ayarlar
# 09 - Özel Yetenekler içindeki tip güvenli Resource üzerinden düzenlenir.

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


func _melee_attack_playback_scale(animation_name: StringName, runtime_windup: float) -> float:
	if animated_sprite == null or not _has_animation(animation_name):
		return 1.0
	var frames := animated_sprite.sprite_frames
	if frames == null or frames.get_frame_count(animation_name) < 2:
		return 1.0
	var animation_fps := maxf(frames.get_animation_speed(animation_name), 0.001)
	var release_units := (
		frames.get_frame_duration(animation_name, 0)
		+ frames.get_frame_duration(animation_name, 1) * 0.5
	)
	var authored_release_time := release_units / animation_fps
	return maxf(authored_release_time / maxf(runtime_windup, 0.001), 0.01)


func _begin_hybrid_attack(use_melee: bool) -> void:
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	_stop_horizontal_motion()
	_face_toward_position(_player.global_position)
	animated_sprite.flip_h = false

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var authored_windup := _hybrid_ability.melee_windup if use_melee else attack_windup
	var authored_cooldown := _hybrid_ability.melee_cooldown if use_melee else attack_cooldown
	var runtime_windup := maxf(0.01, authored_windup * windup_scale)
	var runtime_cooldown := maxf(runtime_windup, authored_cooldown * cooldown_scale)

	var attack_animation: StringName = &"attack_close" if use_melee else &"attack"
	if _has_animation(attack_animation):
		if use_melee:
			animated_sprite.play(
				attack_animation,
				_melee_attack_playback_scale(attack_animation, runtime_windup)
			)
		else:
			animated_sprite.play(attack_animation)
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()

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
	var scaled_damage := maxi(1, base_damage)
	if apply_difficulty_scaling:
		var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
		scaled_damage = maxi(1, int(round(float(base_damage) * damage_scale)))
	return _apply_active_damage_support(scaled_damage)


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	match animation_name:
		&"attack_close":
			return _hybrid_ability.attack_close_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
