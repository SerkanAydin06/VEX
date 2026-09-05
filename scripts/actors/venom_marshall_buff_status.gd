class_name VexVenomMarshallBuffStatus
extends Node

# Aynı hedefteki Venom Marshall güçlendirmeleri üst üste katlanmaz. Süre
# yenilenir ve bonus, hedefin zorlukla ölçeklenmiş gerçek hasarı üzerinden
# tekrar hesaplanır. Özel saldırılar da aynı aktif çarpanı bu status üzerinden
# okuyarak normal saldırıyla aynı destek bonusunu kullanır.

var _target: Node = null
var _remaining_time := 0.0
var _damage_bonus := 0
var _damage_multiplier := 1.0
var _glow: OmniLight3D = null
var _pulse_time := 0.0


func _ready() -> void:
	_target = get_parent()
	_glow = OmniLight3D.new()
	_glow.name = "VenomBuffGlow"
	_glow.light_color = Color(0.72, 0.20, 1.0, 1.0)
	_glow.light_energy = 0.42
	_glow.omni_range = 2.4
	_glow.shadow_enabled = false
	_glow.distance_fade_enabled = true
	_glow.distance_fade_begin = 18.0
	_glow.distance_fade_length = 5.0
	add_child(_glow)
	set_process(false)


func refresh_buff(duration: float, damage_multiplier: float) -> void:
	if _target == null or not is_instance_valid(_target):
		return
	var current_damage := maxi(1, int(_target.get("_runtime_attack_damage")))
	var base_damage := maxi(1, current_damage - _damage_bonus)
	_damage_multiplier = maxf(damage_multiplier, 1.0)
	var buffed_damage := maxi(
		base_damage,
		int(ceil(float(base_damage) * _damage_multiplier))
	)
	_damage_bonus = buffed_damage - base_damage
	_target.set("_runtime_attack_damage", buffed_damage)
	_remaining_time = maxf(_remaining_time, duration)
	set_process(true)


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	if int(_target.get("health")) <= 0:
		_restore_damage()
		queue_free()
		return
	_remaining_time = maxf(0.0, _remaining_time - delta)
	_pulse_time += delta * 5.5
	if _glow != null:
		_glow.light_energy = 0.34 + (sin(_pulse_time) * 0.5 + 0.5) * 0.18
	if _remaining_time <= 0.0:
		_restore_damage()
		queue_free()


func get_remaining_time() -> float:
	return _remaining_time


func get_damage_bonus() -> int:
	return _damage_bonus


func get_damage_multiplier() -> float:
	return _damage_multiplier


func _restore_damage() -> void:
	if _damage_bonus <= 0 or _target == null or not is_instance_valid(_target):
		_damage_bonus = 0
		_damage_multiplier = 1.0
		return
	var current_damage := maxi(1, int(_target.get("_runtime_attack_damage")))
	_target.set("_runtime_attack_damage", maxi(1, current_damage - _damage_bonus))
	_damage_bonus = 0
	_damage_multiplier = 1.0


func _exit_tree() -> void:
	_restore_damage()
