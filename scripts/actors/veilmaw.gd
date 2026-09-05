class_name VexVeilmaw
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

var _ability: VexVeilmawAbilitySettings
var _post_shot_reposition_remaining := 0.0


func _ready() -> void:
	_ability = special_ability_settings as VexVeilmawAbilitySettings
	if _ability == null:
		_ability = VexVeilmawAbilitySettings.new()
		special_ability_settings = _ability
		push_warning("Veilmaw özel yetenek ayarları eksikti; güvenli varsayılanlar kullanılıyor.")
	super._ready()


func _fire_projectile() -> void:
	super._fire_projectile()
	_post_shot_reposition_remaining = _ability.post_shot_reposition_duration
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
