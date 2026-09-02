class_name VexPlayerSurvivabilityRuntime
extends RefCounted

var health := 0
var armor := 0
var is_dead := false

var _maximum_health := 100
var _maximum_armor := 100
var _armor_absorption_ratio := 0.60
var _hurt_audio_cooldown := 0.90
var _hurt_audio_cooldown_remaining := 0.0


func initialize(
	maximum_health: int,
	maximum_armor: int,
	initial_armor: int,
	armor_absorption_ratio: float,
	hurt_audio_cooldown: float
) -> void:
	_maximum_health = maxi(1, maximum_health)
	_maximum_armor = maxi(0, maximum_armor)
	_armor_absorption_ratio = clampf(armor_absorption_ratio, 0.0, 1.0)
	_hurt_audio_cooldown = maxf(0.0, hurt_audio_cooldown)
	health = _maximum_health
	armor = clampi(initial_armor, 0, _maximum_armor)
	is_dead = false
	_hurt_audio_cooldown_remaining = 0.0


func update(delta: float) -> void:
	_hurt_audio_cooldown_remaining = maxf(
		0.0,
		_hurt_audio_cooldown_remaining - maxf(0.0, delta)
	)


func sync_state(current_health: int, current_armor: int, current_is_dead: bool) -> void:
	health = clampi(current_health, 0, _maximum_health)
	armor = clampi(current_armor, 0, _maximum_armor)
	is_dead = current_is_dead or health <= 0


func restore_state(stored_health: int, stored_armor: int) -> void:
	health = clampi(stored_health, 1, _maximum_health)
	armor = clampi(stored_armor, 0, _maximum_armor)
	is_dead = false
	_hurt_audio_cooldown_remaining = 0.0


func collect_health(amount: int) -> int:
	if amount <= 0 or health >= _maximum_health:
		return 0
	var collected := mini(amount, _maximum_health - health)
	health += collected
	return collected


func collect_armor(amount: int) -> int:
	if amount <= 0 or armor >= _maximum_armor:
		return 0
	var collected := mini(amount, _maximum_armor - armor)
	armor += collected
	return collected


func apply_damage(amount: int, hurt_feedback_available: bool) -> Dictionary:
	if is_dead or amount <= 0:
		return {
			"applied": false,
			"absorbed": 0,
			"health_damage": 0,
			"play_hurt_feedback": false,
			"died": false,
		}

	var absorbed := mini(
		armor,
		int(round(float(amount) * _armor_absorption_ratio))
	)
	armor -= absorbed
	var health_damage := amount - absorbed
	health = maxi(0, health - health_damage)
	var died := health <= 0
	if died:
		is_dead = true

	var play_hurt_feedback := (
		health_damage > 0
		and hurt_feedback_available
		and _hurt_audio_cooldown_remaining <= 0.0
	)
	if play_hurt_feedback:
		_hurt_audio_cooldown_remaining = _hurt_audio_cooldown

	return {
		"applied": true,
		"absorbed": absorbed,
		"health_damage": health_damage,
		"play_hurt_feedback": play_hurt_feedback,
		"died": died,
	}


func force_dead() -> void:
	is_dead = true


func get_health() -> int:
	return health


func get_armor() -> int:
	return armor


func get_is_dead() -> bool:
	return is_dead


func get_hurt_audio_cooldown_remaining() -> float:
	return _hurt_audio_cooldown_remaining
