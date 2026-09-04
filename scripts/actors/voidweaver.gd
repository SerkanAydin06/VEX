class_name VexVoidweaver
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const ProjectileFireRuntime = preload("res://scripts/actors/enemy_projectile_fire_runtime.gd")

@export_category("Voidweaver - Enerji Örgüsü")
## Tek saldırıda aynı anda örülen projectile sayısıdır; tekli, üçlü veya beşli kullanılabilir.
@export_enum("Tekli:1", "Üçlü:3", "Beşli:5") var weave_projectile_count := 3
## En dış enerji projectile'larının merkez atıştan yatay açı farkıdır (derece).
@export_range(1.0, 12.0, 0.5) var weave_half_angle_degrees := 5.0
## Merkez dışındaki enerji projectile'larının normal saldırı hasarından aldığı paydır.
@export_range(0.2, 1.0, 0.05) var weave_side_damage_scale := 0.45

# Voidweaver'ın hareket gövdesi yerde kalır; görseli ve silah hurtbox'ı
# havada süzülen silueti temsil eder. Böylece navigation/floor snap bozulmadan
# hitscan yalnız görünen gövde hacminde hasar üretir.
@onready var _weapon_hurtbox: Area3D = $WeaponHurtbox


func accepts_weapon_hit(collider: Object, _hit_position: Vector3) -> bool:
	return state != State.DEAD and collider == _weapon_hurtbox


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	var projectile_count := maxi(1, weave_projectile_count)
	var center_index := int(projectile_count / 2)
	for shot_index: int in range(projectile_count):
		var yaw_degrees := 0.0
		if projectile_count > 1:
			var ratio := float(shot_index) / float(projectile_count - 1)
			yaw_degrees = lerpf(
				-weave_half_angle_degrees,
				weave_half_angle_degrees,
				ratio
			)
		var damage_scale := 1.0 if shot_index == center_index else weave_side_damage_scale
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
			projectile_spawn_side_offset,
			projectile_spawn_forward_offset,
			projectile_target_height,
			projectile_lead_factor,
			projectile_max_lead_time,
			shot_damage,
			yaw_degrees
		)
