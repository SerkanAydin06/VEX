class_name VexCinderSpitter
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

@export_category("Cinder Spitter - Kısa Seri")
## Tek saldırı komutunda çıkarılan sıcak projectile sayısıdır.
@export_range(1, 3, 1) var burst_shot_count := 2
## Seri içindeki projectile'lar arasındaki süredir.
@export_range(0.05, 0.35, 0.01) var burst_interval := 0.12
## Her seri projectile'ının normal saldırı hasarından aldığı paydır.
@export_range(0.25, 1.0, 0.05) var burst_damage_scale := 0.60


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	_fire_burst_shot()
	var combat_generation := _combat_interrupt_generation
	for shot_index: int in range(1, burst_shot_count):
		var timer := get_tree().create_timer(burst_interval * float(shot_index))
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
		roundi(float(_runtime_attack_damage) * burst_damage_scale)
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
