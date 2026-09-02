class_name VexVenomMarshallBuffStatus
extends Node

var _target: Node = null
var _remaining := 0.0
var _damage_multiplier := 1.0
var _speed_multiplier := 1.0
var _original_values: Dictionary = {}
var _applied := false


func _ready() -> void:
	_target = get_parent()
	set_process(true)


func refresh_buff(
	duration: float,
	damage_multiplier: float,
	speed_multiplier: float
) -> void:
	_target = get_parent()
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	_remaining = maxf(_remaining, maxf(0.05, duration))
	_damage_multiplier = maxf(_damage_multiplier, maxf(1.0, damage_multiplier))
	_speed_multiplier = maxf(_speed_multiplier, maxf(1.0, speed_multiplier))
	if not _applied:
		_capture_original_values()
		_applied = true
	_apply_scaled_values()
	_target.set_meta("vex_venom_marshall_buffed", true)


func _process(delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		queue_free()
		return
	_remaining = maxf(0.0, _remaining - delta)
	if _remaining > 0.0:
		return
	_restore_original_values()
	queue_free()


func get_remaining_time() -> float:
	return _remaining


func get_damage_multiplier() -> float:
	return _damage_multiplier


func get_speed_multiplier() -> float:
	return _speed_multiplier


func _capture_original_values() -> void:
	_original_values.clear()
	_capture_if_present(&"_runtime_attack_damage")
	_capture_if_present(&"_runtime_move_speed")
	_capture_if_present(&"_runtime_chase_speed")


func _capture_if_present(property_name: StringName) -> void:
	if _has_property(_target, property_name):
		_original_values[String(property_name)] = _target.get(property_name)


func _apply_scaled_values() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if _original_values.has("_runtime_attack_damage"):
		var base_damage := int(_original_values["_runtime_attack_damage"])
		_target.set(
			"_runtime_attack_damage",
			maxi(1, int(round(float(base_damage) * _damage_multiplier)))
		)
	if _original_values.has("_runtime_move_speed"):
		_target.set(
			"_runtime_move_speed",
			float(_original_values["_runtime_move_speed"]) * _speed_multiplier
		)
	if _original_values.has("_runtime_chase_speed"):
		_target.set(
			"_runtime_chase_speed",
			float(_original_values["_runtime_chase_speed"]) * _speed_multiplier
		)


func _restore_original_values() -> void:
	if not _applied:
		return
	if _target != null and is_instance_valid(_target):
		for key: String in _original_values:
			_target.set(key, _original_values[key])
		if _target.has_meta("vex_venom_marshall_buffed"):
			_target.remove_meta("vex_venom_marshall_buffed")
	_applied = false
	_original_values.clear()


func _exit_tree() -> void:
	_restore_original_values()


func _has_property(target: Object, property_name: StringName) -> bool:
	if target == null:
		return false
	for property: Dictionary in target.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false
