class_name VexPlayerPickupRuntime
extends RefCounted

const AMMO_PICKUPS: Array[StringName] = [
	&"bullets",
	&"shells",
	&"rifle_ammo",
	&"mp90_ammo",
]
const WORLD_WEAPON_PICKUPS: Array[StringName] = [
	&"p01",
	&"p07",
	&"p14",
	&"p20",
	&"sg04",
	&"sg09",
	&"sg15",
]
const DIRECT_WEAPON_PICKUPS: Array[StringName] = [
	&"vx47",
	&"mp90",
]
const VALID_KEYS: Array[StringName] = [
	&"blue",
	&"red",
	&"yellow",
]

var _keys: Array[StringName] = []
var _night_vision_owned := false


func initialize(initial_keys: Array[StringName], night_vision_owned: bool) -> void:
	sync_state(initial_keys, night_vision_owned)


func sync_state(current_keys: Array[StringName], night_vision_owned: bool) -> void:
	_keys.clear()
	for key_id: StringName in current_keys:
		if VALID_KEYS.has(key_id) and not _keys.has(key_id):
			_keys.append(key_id)
	_night_vision_owned = night_vision_owned


func restore_state(stored_keys: Array, night_vision_owned: bool) -> void:
	_keys.clear()
	for stored_key: Variant in stored_keys:
		var key_id := StringName(str(stored_key))
		if VALID_KEYS.has(key_id) and not _keys.has(key_id):
			_keys.append(key_id)
	_night_vision_owned = night_vision_owned


func collect_pickup(
	pickup_type: StringName,
	amount: int,
	survivability: VexPlayerSurvivabilityRuntime,
	weapon_controller: Object
) -> Dictionary:
	if pickup_type == &"health":
		if survivability == null:
			return _failure()
		var collected_health := survivability.collect_health(amount)
		return _amount_result(&"health", pickup_type, collected_health)

	if pickup_type == &"armor":
		if survivability == null:
			return _failure()
		var collected_armor := survivability.collect_armor(amount)
		return _amount_result(&"armor", pickup_type, collected_armor)

	if AMMO_PICKUPS.has(pickup_type):
		if weapon_controller == null or not weapon_controller.has_method("add_ammo"):
			return _failure()
		var collected_ammo := int(weapon_controller.call("add_ammo", pickup_type, amount))
		return _amount_result(&"ammo", pickup_type, collected_ammo)

	if WORLD_WEAPON_PICKUPS.has(pickup_type):
		if weapon_controller == null or not weapon_controller.has_method("equip_world_weapon"):
			return _failure()
		var weapon_result := weapon_controller.call(
			"equip_world_weapon",
			pickup_type,
			amount
		) as Dictionary
		if not bool(weapon_result.get("success", false)):
			return _failure()
		return {
			"success": true,
			"kind": &"world_weapon",
			"pickup_type": pickup_type,
			"weapon_id": StringName(str(weapon_result.get("weapon_id", pickup_type))),
			"displaced_weapon_id": StringName(str(weapon_result.get("displaced_weapon_id", ""))),
		}

	if DIRECT_WEAPON_PICKUPS.has(pickup_type):
		if weapon_controller == null or not weapon_controller.has_method("unlock_weapon"):
			return _failure()
		weapon_controller.call("unlock_weapon", pickup_type, amount)
		return {
			"success": true,
			"kind": &"direct_weapon",
			"pickup_type": pickup_type,
			"weapon_id": pickup_type,
		}

	if pickup_type == &"night_vision":
		if _night_vision_owned:
			return _failure()
		_night_vision_owned = true
		return {
			"success": true,
			"kind": &"equipment",
			"pickup_type": pickup_type,
		}

	var key_id := _key_id_for_pickup(pickup_type)
	if key_id != &"":
		if _keys.has(key_id):
			return _failure()
		_keys.append(key_id)
		return {
			"success": true,
			"kind": &"key",
			"pickup_type": pickup_type,
			"key_id": key_id,
		}

	return _failure()


func has_key(key_id: StringName) -> bool:
	return _keys.has(key_id)


func get_keys() -> Array[StringName]:
	return _keys.duplicate()


func owns_night_vision() -> bool:
	return _night_vision_owned


func _amount_result(kind: StringName, pickup_type: StringName, collected_amount: int) -> Dictionary:
	if collected_amount <= 0:
		return _failure()
	return {
		"success": true,
		"kind": kind,
		"pickup_type": pickup_type,
		"collected_amount": collected_amount,
	}


func _key_id_for_pickup(pickup_type: StringName) -> StringName:
	match pickup_type:
		&"key_blue":
			return &"blue"
		&"key_red":
			return &"red"
		&"key_yellow":
			return &"yellow"
	return &""


func _failure() -> Dictionary:
	return {"success": false}
