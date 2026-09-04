class_name VexVeilmaw
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

@export_category("Veilmaw - Ateş Et / Konum Değiştir")
## Atıştan sonra yeni bir görüş açısı aramak için ayrılan saldırı toparlanma süresidir.
@export_range(0.2, 1.2, 0.05) var post_shot_reposition_duration := 0.65

var _post_shot_reposition_remaining := 0.0


func _fire_projectile() -> void:
	super._fire_projectile()
	_post_shot_reposition_remaining = post_shot_reposition_duration
	_has_ranged_reposition_target = false
	_ranged_reposition_remaining = 0.0


func _move_during_attack_recovery(target: Vector3, delta: float) -> void:
	if _post_shot_reposition_remaining > 0.0:
		_post_shot_reposition_remaining = maxf(
			0.0,
			_post_shot_reposition_remaining - delta
		)
		_reposition_for_clear_shot(delta)
		return
	super._move_during_attack_recovery(target, delta)
