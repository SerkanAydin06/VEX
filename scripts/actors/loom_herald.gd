class_name VexLoomHerald
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

var _ability: VexLoomHeraldAbilitySettings

# Loom Herald'ın hareket gövdesi navigation için zeminde kalır; görünen yaratık
# enerji kuyruğuyla havada süzüldüğü için hitscan hacmi sprite'ın gerçek gövdesini izler.
@onready var _weapon_hurtbox: Area3D = $WeaponHurtbox


func _ready() -> void:
	_ability = special_ability_settings as VexLoomHeraldAbilitySettings
	if _ability == null:
		_ability = VexLoomHeraldAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Loom Herald özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func accepts_weapon_hit(collider: Object, _hit_position: Vector3) -> bool:
	return state != State.DEAD and collider == _weapon_hurtbox


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	for shot_index: int in range(2):
		var side_sign := -1.0 if shot_index == 0 else 1.0
		var shot_damage := maxi(
			1,
			roundi(float(_runtime_attack_damage) * _ability.projectile_damage_scale)
		)
		ProjectileFireRuntime.fire(
			self,
			_player,
			projectile_scene,
			_facing_direction,
			projectile_spawn_height,
			projectile_spawn_side_offset + side_sign * _ability.emitter_half_span,
			projectile_spawn_forward_offset,
			projectile_target_height,
			projectile_lead_factor,
			projectile_max_lead_time,
			shot_damage,
			side_sign * _ability.volley_half_angle_degrees
		)
