class_name VexCinderSpitter
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

var _ability: VexCinderSpitterAbilitySettings


func _ready() -> void:
	_ability = special_ability_settings as VexCinderSpitterAbilitySettings
	if _ability == null:
		_ability = VexCinderSpitterAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Cinder Spitter özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	_fire_burst_shot()
	var combat_generation := _combat_interrupt_generation
	for shot_index: int in range(1, _ability.burst_shot_count):
		var timer := get_tree().create_timer(_ability.burst_interval * float(shot_index))
		timer.timeout.connect(_fire_burst_followup.bind(combat_generation))


func _fire_burst_followup(combat_generation: int) -> void:
	if (
		not is_inside_tree()
		or state == State.DEAD
		or combat_generation != _combat_interrupt_generation
		or _player == null
		or not is_instance_valid(_player)
	):
		return
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	if player_distance > attack_range + attack_range_tolerance:
		return
	if not _check_line_of_sight():
		return
	if _has_animation(&"attack"):
		animated_sprite.play(&"attack")
		_apply_frame_ground_offset()
	_fire_burst_shot()


func _fire_burst_shot() -> void:
	var burst_damage := maxi(
		1,
		roundi(float(_runtime_attack_damage) * _ability.burst_damage_scale)
	)
	ProjectileFireRuntime.fire(
		self,
		_player,
		projectile_scene,
		_facing_direction,
		projectile_spawn_height,
		projectile_spawn_side_offset,
		projectile_spawn_forward_offset,
		projectile_target_height,
		projectile_lead_factor,
		projectile_max_lead_time,
		burst_damage
	)
