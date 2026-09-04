class_name VexVoidweaver
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

# Voidweaver'ın hareket gövdesi yerde kalır; görseli ve silah hurtbox'ı
# havada süzülen silueti temsil eder. Böylece navigation/floor snap bozulmadan
# hitscan yalnız görünen gövde hacminde hasar üretir.
@onready var _weapon_hurtbox: Area3D = $WeaponHurtbox


func accepts_weapon_hit(collider: Object, _hit_position: Vector3) -> bool:
	return state != State.DEAD and collider == _weapon_hurtbox
