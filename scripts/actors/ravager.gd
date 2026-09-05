class_name VexRavager
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

var _ability: VexRavagerAbilitySettings


func _ready() -> void:
	_ability = special_ability_settings as VexRavagerAbilitySettings
	if _ability == null:
		_ability = VexRavagerAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Ravager özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


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
		_ability.precision_projectile_speed_scale
	)
