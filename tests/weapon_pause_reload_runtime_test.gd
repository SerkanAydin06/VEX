extends Node

const PLAYER_SCENE := preload("res://scenes/player/player.tscn")


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var player := PLAYER_SCENE.instantiate() as VexPlayer
	assert(player != null)
	add_child(player)
	await get_tree().process_frame

	var controller := player.weapon_controller as VexWeaponController
	assert(controller != null)
	await _test_standard_reload_pause(controller)
	await _test_standard_reload_preserves_mid_reload_pickup(controller)
	await _test_sg04_reload_pause(controller)
	_test_world_weapon_repickup_preserves_empty_magazine(controller)

	get_tree().paused = false
	player.free()
	for _frame: int in range(3):
		await get_tree().process_frame
	print("Weapon pause reload runtime test passed")
	get_tree().quit(0)


func _test_standard_reload_pause(controller: VexWeaponController) -> void:
	var weapon := controller.get_weapon_definition(&"p01")
	assert(weapon != null)
	var original_duration := weapon.reload_duration
	weapon.reload_duration = 0.10
	controller.current_weapon_id = &"p01"
	controller.magazines[&"p01"] = 0
	controller.reserve_ammo[weapon.ammo_type] = 3
	controller.reload()
	assert(controller.is_reloading)

	get_tree().paused = true
	await get_tree().create_timer(0.22, true).timeout
	assert(controller.is_reloading)
	assert(int(controller.magazines.get(&"p01", -1)) == 0)

	get_tree().paused = false
	await get_tree().create_timer(0.18, true).timeout
	assert(not controller.is_reloading)
	assert(int(controller.magazines.get(&"p01", 0)) > 0)
	weapon.reload_duration = original_duration


func _test_standard_reload_preserves_mid_reload_pickup(controller: VexWeaponController) -> void:
	var weapon := controller.get_weapon_definition(&"p01")
	assert(weapon != null)
	var original_duration := weapon.reload_duration
	weapon.reload_duration = 0.16
	controller.current_weapon_id = &"p01"
	controller.magazines[&"p01"] = 0
	controller.reserve_ammo[weapon.ammo_type] = 3
	controller.reload()
	assert(controller.is_reloading)

	await get_tree().create_timer(0.05, true).timeout
	var collected := controller.add_ammo(weapon.ammo_type, 5)
	assert(collected == 5)
	assert(int(controller.reserve_ammo.get(weapon.ammo_type, -1)) == 8)

	await get_tree().create_timer(0.20, true).timeout
	assert(not controller.is_reloading)
	assert(int(controller.magazines.get(&"p01", -1)) == 8)
	assert(int(controller.reserve_ammo.get(weapon.ammo_type, -1)) == 0)
	weapon.reload_duration = original_duration


func _test_sg04_reload_pause(controller: VexWeaponController) -> void:
	var weapon := controller.get_weapon_definition(&"sg04")
	assert(weapon != null)
	var original_duration := weapon.reload_duration
	weapon.reload_duration = 0.12
	if not controller.unlocked_weapons.has(&"sg04"):
		controller.unlocked_weapons.append(&"sg04")
	controller.current_weapon_id = &"sg04"
	controller.magazines[&"sg04"] = 0
	controller.reserve_ammo[weapon.ammo_type] = 1
	controller.reload()
	assert(controller.is_reloading)

	get_tree().paused = true
	await get_tree().create_timer(0.22, true).timeout
	assert(controller.is_reloading)
	assert(int(controller.magazines.get(&"sg04", -1)) == 0)

	get_tree().paused = false
	await get_tree().create_timer(0.24, true).timeout
	assert(not controller.is_reloading)
	assert(int(controller.magazines.get(&"sg04", 0)) == 1)
	weapon.reload_duration = original_duration


func _test_world_weapon_repickup_preserves_empty_magazine(controller: VexWeaponController) -> void:
	var p20 := controller.get_weapon_definition(&"p20")
	var p01 := controller.get_weapon_definition(&"p01")
	assert(p20 != null)
	assert(p01 != null)

	controller.acquired_weapons.erase(&"p20")
	controller.unlocked_weapons.erase(&"p20")
	if not controller.acquired_weapons.has(&"p01"):
		controller.acquired_weapons.append(&"p01")
	if not controller.unlocked_weapons.has(&"p01"):
		controller.unlocked_weapons.append(&"p01")
	controller.current_weapon_id = &"p01"
	controller.magazines[&"p20"] = 0

	var first_pickup := controller.equip_world_weapon(&"p20", 0)
	assert(bool(first_pickup.get("success", false)))
	assert(int(controller.magazines.get(&"p20", -1)) == p20.magazine_size)
	assert(StringName(str(first_pickup.get("displaced_weapon_id", ""))) == &"p01")

	controller.magazines[&"p20"] = 0
	var swap_back := controller.equip_world_weapon(&"p01", 0)
	assert(bool(swap_back.get("success", false)))
	assert(StringName(str(swap_back.get("displaced_weapon_id", ""))) == &"p20")

	var repick := controller.equip_world_weapon(&"p20", 0)
	assert(bool(repick.get("success", false)))
	assert(StringName(str(repick.get("displaced_weapon_id", ""))) == &"p01")
	assert(int(controller.magazines.get(&"p20", -1)) == 0)
