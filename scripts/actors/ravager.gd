class_name VexRavager
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

@export_category("Ravager - Avcı Atışı")
## Uzun menzilli tek atışın normal projectile hızına uyguladığı çarpandır.
@export_range(1.0, 1.5, 0.01) var precision_projectile_speed_scale := 1.18


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
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
		_runtime_attack_damage,
		0.0,
		precision_projectile_speed_scale
	)
