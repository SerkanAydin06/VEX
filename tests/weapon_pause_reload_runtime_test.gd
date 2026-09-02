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
	await _test_sg04_reload_pause(controller)

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
