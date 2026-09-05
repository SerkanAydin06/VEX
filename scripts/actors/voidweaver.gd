class_name VexVoidweaver
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")
const WEAVE_EMITTER_HALF_SPAN := 0.42

var _ability: VexVoidweaverAbilitySettings

# Voidweaver'ın hareket gövdesi yerde kalır; görseli ve silah hurtbox'ı
# havada süzülen silueti temsil eder. Böylece navigation/floor snap bozulmadan
# hitscan yalnız görünen gövde hacminde hasar üretir.
@onready var _weapon_hurtbox: Area3D = $WeaponHurtbox


func _ready() -> void:
	_ability = special_ability_settings as VexVoidweaverAbilitySettings
	if _ability == null:
		_ability = VexVoidweaverAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Voidweaver özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func accepts_weapon_hit(collider: Object, _hit_position: Vector3) -> bool:
	return state != State.DEAD and collider == _weapon_hurtbox


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	var projectile_count := maxi(1, _ability.weave_projectile_count)
	var center_index := int(float(projectile_count) / 2.0)
	for shot_index: int in range(projectile_count):
		var yaw_degrees := 0.0
		var emitter_side_offset := projectile_spawn_side_offset
		if projectile_count > 1:
			var ratio := float(shot_index) / float(projectile_count - 1)
			yaw_degrees = lerpf(
				-_ability.weave_half_angle_degrees,
				_ability.weave_half_angle_degrees,
				ratio
			)
			emitter_side_offset += lerpf(
				-WEAVE_EMITTER_HALF_SPAN,
				WEAVE_EMITTER_HALF_SPAN,
				ratio
			)
		var damage_scale := 1.0 if shot_index == center_index else _ability.weave_side_damage_scale
		var shot_damage := maxi(
			1,
			roundi(float(_runtime_attack_damage) * damage_scale)
		)
		ProjectileFireRuntime.fire(
			self,
			_player,
			projectile_scene,
			_facing_direction,
			projectile_spawn_height,
			emitter_side_offset,
			projectile_spawn_forward_offset,
			projectile_target_height,
			projectile_lead_factor,
			projectile_max_lead_time,
			shot_damage,
			yaw_degrees
		)
