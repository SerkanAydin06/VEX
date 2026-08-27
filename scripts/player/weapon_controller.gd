class_name VexWeaponController
extends Node

signal loadout_changed

@export_category("Başlangıç")
@export var weapon_definitions: Array[WeaponDefinition] = []
@export var initial_unlocked_weapons: Array[StringName] = [&"p01"]
@export var initial_weapon_id: StringName = &"p01"
@export var fill_initial_magazines := true
@export var initial_bullets := 48
@export var initial_shells := 0
@export var initial_rifle_ammo := 0
@export var initial_mp90_ammo := 0

@export_category("Cephanelik Taşıma Kuralı")
@export_range(1, 5, 1) var weapons_per_loadout_group := 1

@export_category("Ateş ve Geçiş")
@export_range(0.0, 2.0, 0.01) var equip_cooldown := 0.15
@export_range(0.0, 2.0, 0.01) var empty_trigger_cooldown := 0.25
@export_flags_3d_physics var hitscan_collision_mask := 1 | 4 | 8

@export_category("Silaha Bağlı Fener")
@export_node_path("SpotLight3D") var weapon_flashlight_path := NodePath("../ViewPivot/Camera3D/WeaponFlashlight")

@export_category("Otomatik Silah Sekme Birikimi")
@export_range(0.0, 2.0, 0.01) var burst_reset_min_time := 0.22
@export_range(0.0, 8.0, 0.1) var burst_reset_fire_interval_multiplier := 2.5
@export_range(0.0, 3.0, 0.01) var automatic_vertical_base_multiplier := 0.78
@export_range(0.0, 1.0, 0.01) var automatic_vertical_per_shot := 0.07
@export_range(0.0, 3.0, 0.01) var automatic_vertical_max_multiplier := 1.35
@export_range(0.0, 3.0, 0.01) var automatic_horizontal_base_multiplier := 0.68
@export_range(0.0, 1.0, 0.01) var automatic_horizontal_per_shot := 0.09
@export_range(0.0, 3.0, 0.01) var automatic_horizontal_max_multiplier := 1.45

## Göreve taşınan silahlar. Eski sahne/save uyumluluğu için ad korunmuştur.
var unlocked_weapons: Array[StringName] = []
## Oyuncunun şimdiye kadar bulduğu bütün silahlar; raftakiler de buna dahildir.
var acquired_weapons: Array[StringName] = []
var magazines: Dictionary = {}
var reserve_ammo: Dictionary = {}
var upgrade_levels: Dictionary = {}
var current_weapon_id: StringName = &""
var is_reloading := false
var flashlight_enabled := false
var _cooldown_remaining := 0.0
var _definitions_by_id: Dictionary = {}
var _player: VexPlayer
var _weapon_flashlight: SpotLight3D
var _burst_shots := 0
var _burst_reset_remaining := 0.0
var _sg04_reload_generation := 0
var _sg04_reload_fire_queued := false


func _ready() -> void:
	_player = get_parent() as VexPlayer
	_weapon_flashlight = get_node_or_null(weapon_flashlight_path) as SpotLight3D
	if _weapon_flashlight != null:
		_weapon_flashlight.visible = false
	for definition: WeaponDefinition in weapon_definitions:
		if definition == null:
			continue
		_definitions_by_id[definition.weapon_id] = definition
		upgrade_levels[definition.weapon_id] = 0
		magazines[definition.weapon_id] = 0
		if not reserve_ammo.has(definition.ammo_type):
			reserve_ammo[definition.ammo_type] = 0

	unlocked_weapons.clear()
	acquired_weapons.clear()
	for weapon_id in initial_unlocked_weapons:
		if _definitions_by_id.has(weapon_id) and not unlocked_weapons.has(weapon_id):
			unlocked_weapons.append(weapon_id)
			acquired_weapons.append(weapon_id)
	if unlocked_weapons.is_empty() and not weapon_definitions.is_empty():
		var fallback_definition := weapon_definitions[0]
		if fallback_definition != null:
			unlocked_weapons.append(fallback_definition.weapon_id)
			acquired_weapons.append(fallback_definition.weapon_id)

	if fill_initial_magazines:
		for weapon_id in unlocked_weapons:
			var definition := _definitions_by_id.get(weapon_id) as WeaponDefinition
			if definition != null:
				magazines[weapon_id] = definition.magazine_size

	reserve_ammo[&"bullets"] = initial_bullets
	reserve_ammo[&"shells"] = initial_shells
	reserve_ammo[&"rifle_ammo"] = initial_rifle_ammo
	reserve_ammo[&"mp90_ammo"] = initial_mp90_ammo
	current_weapon_id = initial_weapon_id
	if not unlocked_weapons.has(current_weapon_id):
		current_weapon_id = unlocked_weapons[0] if not unlocked_weapons.is_empty() else &""
	call_deferred("broadcast_state")


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_burst_reset_remaining = maxf(0.0, _burst_reset_remaining - delta)
	if _burst_reset_remaining <= 0.0:
		_burst_shots = 0
	if get_tree().paused or _player == null or _player.is_dead:
		return
	var weapon := get_current_weapon()
	if weapon == null or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var wants_to_fire := Input.is_action_pressed("fire") if weapon.automatic else Input.is_action_just_pressed("fire")
	if _sg04_reload_fire_queued:
		if weapon.weapon_id != &"sg04":
			_sg04_reload_fire_queued = false
		elif not is_reloading and _cooldown_remaining <= 0.0:
			_sg04_reload_fire_queued = false
			_try_fire()
			return
	if is_reloading:
		if weapon.weapon_id == &"sg04" and wants_to_fire:
			_interrupt_sg04_reload_and_fire()
		return
	if wants_to_fire:
		_try_fire()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _player == null or _player.is_dead:
		return
	if event.is_action_pressed("reload"):
		reload()
	elif (
		InputMap.has_action(&"weapon_flashlight")
		and event.is_action_pressed(&"weapon_flashlight")
	):
		toggle_weapon_flashlight()
	elif event.is_action_pressed("weapon_1"):
		switch_to_loadout_slot(1)
	elif event.is_action_pressed("weapon_2"):
		switch_to_loadout_slot(2)
	elif event.is_action_pressed("weapon_3"):
		switch_to_loadout_slot(3)
	elif event.is_action_pressed("weapon_4"):
		switch_to_loadout_slot(4)
	elif event.is_action_pressed("weapon_5"):
		switch_to_loadout_slot(5)
	elif event.is_action_pressed("weapon_next"):
		cycle_weapon(1)
	elif event.is_action_pressed("weapon_previous"):
		cycle_weapon(-1)


func canonical_weapon_id(weapon_id: StringName) -> StringName:
	match str(weapon_id):
		"pistol":
			return &"p01"
		"shotgun":
			return &"sg04"
		"ak47":
			return &"vx47"
	return weapon_id


func _canonicalize_weapon_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key: Variant in source.keys():
		var canonical := canonical_weapon_id(StringName(str(key)))
		output[canonical] = source[key]
	return output


func get_current_weapon() -> WeaponDefinition:
	return _definitions_by_id.get(current_weapon_id) as WeaponDefinition


func get_weapon_definition(weapon_id: StringName) -> WeaponDefinition:
	return _definitions_by_id.get(canonical_weapon_id(weapon_id)) as WeaponDefinition


func owns_weapon(weapon_id: StringName) -> bool:
	return acquired_weapons.has(canonical_weapon_id(weapon_id))


func is_weapon_carried(weapon_id: StringName) -> bool:
	return unlocked_weapons.has(canonical_weapon_id(weapon_id))


func has_carried_weapon() -> bool:
	return not unlocked_weapons.is_empty()


func switch_to_loadout_slot(slot: int) -> void:
	for weapon_id in unlocked_weapons:
		var definition := get_weapon_definition(weapon_id)
		if definition != null and definition.loadout_slot == slot:
			switch_to(weapon_id)
			return


func get_weapon_upgrade_track(weapon_id: StringName) -> Array:
	return VexWeaponUpgradeCatalog.get_track(weapon_id)


func get_weapon_upgrade_level(weapon_id: StringName) -> int:
	return maxi(0, int(upgrade_levels.get(weapon_id, 0)))


func install_next_upgrade(weapon_id: StringName) -> bool:
	if not unlocked_weapons.has(weapon_id):
		return false
	var track := get_weapon_upgrade_track(weapon_id)
	var level := get_weapon_upgrade_level(weapon_id)
	if level >= track.size():
		return false
	upgrade_levels[weapon_id] = level + 1
	var definition := _definitions_by_id.get(weapon_id) as WeaponDefinition
	if definition != null:
		magazines[weapon_id] = mini(int(magazines.get(weapon_id, 0)), _effective_magazine_size(definition))
	_sync_weapon_flashlight()
	var tier: Dictionary = track[level]
	GameState.notify(tr("WEAPON_UPGRADE_FORMAT") % tr(str(tier.get("name", "UPGRADE_GENERIC"))))
	broadcast_state()
	GameState.call_deferred("save_current_safe_progress", "weapon_upgrade")
	return true


func _modifiers(weapon: WeaponDefinition) -> Dictionary:
	return VexWeaponUpgradeCatalog.get_modifiers(weapon.weapon_id, get_weapon_upgrade_level(weapon.weapon_id))


func _effective_magazine_size(weapon: WeaponDefinition) -> int:
	return weapon.magazine_size + int(_modifiers(weapon).magazine)


func get_reload_animation_speed_multiplier(weapon_id: StringName) -> float:
	var weapon := get_weapon_definition(weapon_id)
	if weapon == null:
		return 1.0
	var reload_time_multiplier := maxf(0.01, float(_modifiers(weapon).reload))
	return 1.0 / reload_time_multiplier


func switch_to(weapon_id: StringName) -> void:
	if is_reloading or not unlocked_weapons.has(weapon_id) or not _definitions_by_id.has(weapon_id):
		return
	current_weapon_id = weapon_id
	_cooldown_remaining = equip_cooldown
	_burst_shots = 0
	_burst_reset_remaining = 0.0
	broadcast_state()
	_play_hud_action(&"equip")


func cycle_weapon(direction: int) -> void:
	if unlocked_weapons.size() < 2:
		return
	var current_index := unlocked_weapons.find(current_weapon_id)
	var next_index := wrapi(current_index + direction, 0, unlocked_weapons.size())
	switch_to(unlocked_weapons[next_index])


func toggle_armory_weapon(weapon_id: StringName) -> Dictionary:
	if is_reloading or not owns_weapon(weapon_id) or not _definitions_by_id.has(weapon_id):
		return {"success": false}
	if is_weapon_carried(weapon_id):
		unlocked_weapons.erase(weapon_id)
		_select_fallback_after_loadout_change()
		loadout_changed.emit()
		GameState.call_deferred("save_current_safe_progress", "armory_loadout")
		return {
			"success": true,
			"action": &"stored",
			"weapon_id": weapon_id,
		}

	var definition := get_weapon_definition(weapon_id)
	var displaced_weapon_id := _make_room_for_loadout_group(weapon_id, definition)
	unlocked_weapons.append(weapon_id)
	current_weapon_id = weapon_id
	_cooldown_remaining = equip_cooldown
	_burst_shots = 0
	_burst_reset_remaining = 0.0
	broadcast_state()
	_play_hud_action(&"equip")
	loadout_changed.emit()
	GameState.call_deferred("save_current_safe_progress", "armory_loadout")
	return {
		"success": true,
		"action": &"equipped",
		"weapon_id": weapon_id,
		"displaced_weapon_id": displaced_weapon_id,
	}


func _select_fallback_after_loadout_change() -> void:
	if unlocked_weapons.is_empty():
		current_weapon_id = &""
		broadcast_state()
		return
	if not unlocked_weapons.has(current_weapon_id):
		current_weapon_id = unlocked_weapons[0]
	broadcast_state()


func _loadout_group_for(definition: WeaponDefinition) -> StringName:
	if definition == null or definition.loadout_group == &"":
		return definition.weapon_id if definition != null else &""
	return definition.loadout_group


func _make_room_for_loadout_group(
	target_weapon_id: StringName,
	target_definition: WeaponDefinition
) -> StringName:
	var matching_carried: Array[StringName] = []
	for carried_id: StringName in unlocked_weapons:
		if carried_id == target_weapon_id:
			continue
		var carried_definition := get_weapon_definition(carried_id)
		if (
			carried_definition != null
			and _loadout_group_for(carried_definition) == _loadout_group_for(target_definition)
		):
			matching_carried.append(carried_id)
	var first_displaced: StringName = &""
	var group_limit := maxi(1, weapons_per_loadout_group)
	while matching_carried.size() >= group_limit:
		var displaced_id: StringName = (
			current_weapon_id
			if matching_carried.has(current_weapon_id)
			else matching_carried[0]
		)
		if first_displaced == &"":
			first_displaced = displaced_id
		unlocked_weapons.erase(displaced_id)
		matching_carried.erase(displaced_id)
	return first_displaced


func reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or is_reloading:
		return
	var magazine := int(magazines.get(current_weapon_id, 0))
	var reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
	var magazine_size := _effective_magazine_size(weapon)
	if magazine >= magazine_size or reserve <= 0:
		return
	if weapon.weapon_id == &"sg04":
		await _reload_sg04_shells(weapon, magazine_size, magazine, reserve)
		return
	is_reloading = true
	_play_hud_action(&"reload")
	await get_tree().create_timer(weapon.reload_duration * float(_modifiers(weapon).reload)).timeout
	if not is_inside_tree() or _player.is_dead:
		is_reloading = false
		return
	var required: int = magazine_size - magazine
	var loaded: int = mini(required, reserve)
	magazines[current_weapon_id] = magazine + loaded
	reserve_ammo[weapon.ammo_type] = reserve - loaded
	is_reloading = false
	broadcast_state()


func _reload_sg04_shells(
	weapon: WeaponDefinition,
	magazine_size: int,
	starting_magazine: int,
	starting_reserve: int
) -> void:
	is_reloading = true
	_sg04_reload_fire_queued = false
	_sg04_reload_generation += 1
	var reload_generation := _sg04_reload_generation
	var rounds_to_load := mini(magazine_size - starting_magazine, starting_reserve)
	var reload_time_multiplier := maxf(0.01, float(_modifiers(weapon).reload))
	# SG04 reload art has four equal-duration authored frames. Frames 1-2-3 are
	# one shell insertion cycle; frame 4 is the single final close/ready pose.
	var shell_cycle_duration := weapon.reload_duration * 0.75 * reload_time_multiplier
	var finish_duration := weapon.reload_duration * 0.25 * reload_time_multiplier

	for _round_index: int in range(rounds_to_load):
		_play_hud_action(&"reload_shell")
		await get_tree().create_timer(shell_cycle_duration).timeout
		if reload_generation != _sg04_reload_generation:
			return
		if not is_inside_tree() or _player == null or _player.is_dead:
			is_reloading = false
			return

		var current_magazine := int(magazines.get(weapon.weapon_id, 0))
		var current_reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
		if current_magazine >= magazine_size or current_reserve <= 0:
			break
		magazines[weapon.weapon_id] = current_magazine + 1
		reserve_ammo[weapon.ammo_type] = current_reserve - 1
		broadcast_state()

	if not is_inside_tree() or _player == null or _player.is_dead:
		is_reloading = false
		return
	_play_hud_action(&"reload_finish")
	await get_tree().create_timer(finish_duration).timeout
	if reload_generation != _sg04_reload_generation:
		return
	if not is_inside_tree() or _player == null or _player.is_dead:
		is_reloading = false
		return
	is_reloading = false
	broadcast_state()


func _interrupt_sg04_reload_and_fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null or weapon.weapon_id != &"sg04" or not is_reloading:
		return
	_sg04_reload_generation += 1
	is_reloading = false
	# Reload görselini anında bırak; ateş intervali bitmediyse aynı tıklamayı queue et.
	_play_hud_action(&"equip")
	if _cooldown_remaining > 0.0:
		_sg04_reload_fire_queued = true
		return
	_sg04_reload_fire_queued = false
	_try_fire()


func add_ammo(ammo_type: StringName, amount: int) -> int:
	var maximum := _get_reserve_ammo_capacity(ammo_type)
	if maximum <= 0:
		return 0
	var current := int(reserve_ammo.get(ammo_type, 0))
	if current >= maximum or amount <= 0:
		return 0
	var accepted := mini(amount, maximum - current)
	reserve_ammo[ammo_type] = current + accepted
	broadcast_state()
	return accepted


func _get_reserve_ammo_capacity(ammo_type: StringName) -> int:
	var maximum := 0
	for definition: WeaponDefinition in weapon_definitions:
		if definition != null and definition.ammo_type == ammo_type:
			maximum = maxi(maximum, definition.reserve_ammo_capacity)
	return maximum


func unlock_weapon(weapon_id: StringName, bonus_ammo: int) -> void:
	var definition := _definitions_by_id.get(weapon_id) as WeaponDefinition
	if definition == null:
		return
	if not acquired_weapons.has(weapon_id):
		acquired_weapons.append(weapon_id)
	_make_room_for_loadout_group(weapon_id, definition)
	if not unlocked_weapons.has(weapon_id):
		unlocked_weapons.append(weapon_id)
	if int(magazines.get(weapon_id, 0)) <= 0:
		magazines[weapon_id] = definition.magazine_size
	add_ammo(definition.ammo_type, bonus_ammo)
	switch_to(weapon_id)
	loadout_changed.emit()


## Görev içindeki fiziksel silah pickup'ları için kullanılır. Cephanelik rafı
## davranışından farklı olarak, yer açılan silağın kimliğini çağırana döndürür;
## Player bu modeli aynı noktada tekrar toplanabilir bir pickup olarak üretir.
func equip_world_weapon(weapon_id: StringName, bonus_ammo: int) -> Dictionary:
	var canonical_id := canonical_weapon_id(weapon_id)
	var definition := _definitions_by_id.get(canonical_id) as WeaponDefinition
	if definition == null or is_reloading:
		return {"success": false}

	if not acquired_weapons.has(canonical_id):
		acquired_weapons.append(canonical_id)
	var displaced_weapon_id := _make_room_for_loadout_group(canonical_id, definition)
	if not unlocked_weapons.has(canonical_id):
		unlocked_weapons.append(canonical_id)
	if int(magazines.get(canonical_id, 0)) <= 0:
		magazines[canonical_id] = definition.magazine_size
	add_ammo(definition.ammo_type, bonus_ammo)
	switch_to(canonical_id)
	loadout_changed.emit()
	return {
		"success": true,
		"weapon_id": canonical_id,
		"displaced_weapon_id": displaced_weapon_id,
	}


func broadcast_state() -> void:
	_sync_weapon_flashlight()
	var weapon := get_current_weapon()
	if weapon == null:
		GameState.publish_weapon(&"", "UI_UNARMED")
		GameState.publish_ammo(0, 0)
		return
	GameState.publish_weapon(weapon.weapon_id, weapon.display_name)
	GameState.publish_ammo(
		int(magazines.get(current_weapon_id, 0)),
		int(reserve_ammo.get(weapon.ammo_type, 0))
	)


func capture_state() -> Dictionary:
	return {
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"acquired_weapons": acquired_weapons.duplicate(),
		"magazines": magazines.duplicate(true),
		"reserve_ammo": reserve_ammo.duplicate(true),
		"current_weapon_id": current_weapon_id,
		"upgrade_levels": upgrade_levels.duplicate(true),
		"flashlight_enabled": flashlight_enabled,
	}


func restore_state(state: Dictionary) -> void:
	if state.is_empty():
		broadcast_state()
		return
	unlocked_weapons.clear()
	var stored_weapons: Array = state.get("unlocked_weapons", initial_unlocked_weapons) as Array
	for stored_weapon: Variant in stored_weapons:
		var stored_weapon_id := canonical_weapon_id(StringName(str(stored_weapon)))
		if _definitions_by_id.has(stored_weapon_id) and not unlocked_weapons.has(stored_weapon_id):
			unlocked_weapons.append(stored_weapon_id)
	acquired_weapons.clear()
	var stored_acquired: Array = state.get("acquired_weapons", stored_weapons) as Array
	for stored_weapon: Variant in stored_acquired:
		var stored_weapon_id := canonical_weapon_id(StringName(str(stored_weapon)))
		if _definitions_by_id.has(stored_weapon_id) and not acquired_weapons.has(stored_weapon_id):
			acquired_weapons.append(stored_weapon_id)
	if acquired_weapons.is_empty():
		for weapon_id in initial_unlocked_weapons:
			if _definitions_by_id.has(weapon_id):
				acquired_weapons.append(weapon_id)
				if unlocked_weapons.is_empty():
					unlocked_weapons.append(weapon_id)
				break
	magazines = _canonicalize_weapon_dictionary((state.get("magazines", magazines) as Dictionary).duplicate(true))
	reserve_ammo = _migrate_legacy_ammo_dictionary(
		(state.get("reserve_ammo", reserve_ammo) as Dictionary).duplicate(true)
	)
	current_weapon_id = canonical_weapon_id(StringName(str(state.get("current_weapon_id", initial_weapon_id))))
	upgrade_levels = _canonicalize_weapon_dictionary((state.get("upgrade_levels", upgrade_levels) as Dictionary).duplicate(true))
	flashlight_enabled = bool(state.get("flashlight_enabled", false))
	if not unlocked_weapons.has(current_weapon_id):
		current_weapon_id = (
			unlocked_weapons[0]
			if not unlocked_weapons.is_empty()
			else &""
		)
	broadcast_state()
	loadout_changed.emit()


func _migrate_legacy_ammo_dictionary(source: Dictionary) -> Dictionary:
	var migrated := source.duplicate(true)
	var bullet_count := int(migrated.get(&"bullets", migrated.get("bullets", 0)))
	var legacy_magnum_count := int(
		migrated.get(&"magnum_ammo", migrated.get("magnum_ammo", 0))
	)
	migrated.erase(&"bullets")
	migrated.erase("bullets")
	migrated.erase(&"magnum_ammo")
	migrated.erase("magnum_ammo")
	migrated[&"bullets"] = clampi(
		bullet_count + legacy_magnum_count,
		0,
		_get_reserve_ammo_capacity(&"bullets")
	)
	for definition: WeaponDefinition in weapon_definitions:
		if definition != null and not migrated.has(definition.ammo_type):
			migrated[definition.ammo_type] = 0
	return migrated


func toggle_weapon_flashlight() -> void:
	var weapon := get_current_weapon()
	if weapon == null or not weapon.supports_flashlight:
		GameState.notify("WEAPON_FLASHLIGHT_UNAVAILABLE")
		return
	flashlight_enabled = not flashlight_enabled
	_sync_weapon_flashlight()
	GameState.notify(
		"WEAPON_FLASHLIGHT_ACTIVE"
		if flashlight_enabled
		else "WEAPON_FLASHLIGHT_INACTIVE"
	)
	GameState.call_deferred("save_current_safe_progress", "weapon_flashlight")


func _sync_weapon_flashlight() -> void:
	if _weapon_flashlight == null or not is_instance_valid(_weapon_flashlight):
		return
	var weapon := get_current_weapon()
	var active := weapon != null and weapon.supports_flashlight and flashlight_enabled
	_weapon_flashlight.visible = active
	if weapon == null or not weapon.supports_flashlight:
		return
	var modifiers := _modifiers(weapon)
	_weapon_flashlight.light_color = weapon.flashlight_color
	_weapon_flashlight.light_energy = weapon.flashlight_energy * float(modifiers.flashlight_energy)
	_weapon_flashlight.spot_range = weapon.flashlight_range * float(modifiers.flashlight_range)
	_weapon_flashlight.spot_angle = weapon.flashlight_angle_degrees


func _is_weapon_flashlight_active(weapon: WeaponDefinition) -> bool:
	return (
		weapon != null
		and weapon.supports_flashlight
		and flashlight_enabled
		and _weapon_flashlight != null
		and _weapon_flashlight.visible
	)


func _try_fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null or _cooldown_remaining > 0.0 or is_reloading:
		return
	var magazine := int(magazines.get(current_weapon_id, 0))
	if magazine <= 0:
		_play_hud_action(&"empty")
		GameState.notify(tr("WEAPON_EMPTY_RELOAD"))
		_cooldown_remaining = empty_trigger_cooldown
		return
	magazines[current_weapon_id] = magazine - 1
	_cooldown_remaining = weapon.fire_interval * float(_modifiers(weapon).fire_rate)
	_play_hud_action(&"fire")
	_shoot_hitscan(weapon)
	GameState.emit_gunshot(
		_player.global_position,
		weapon.gunshot_noise_multiplier * float(_modifiers(weapon).gunshot_noise),
		_player
	)
	_apply_recoil(weapon)
	broadcast_state()


func _apply_recoil(weapon: WeaponDefinition) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_burst_shots += 1
	_burst_reset_remaining = maxf(
		burst_reset_min_time,
		weapon.fire_interval * float(_modifiers(weapon).fire_rate) * burst_reset_fire_interval_multiplier
	)

	var vertical_multiplier := 1.0
	var horizontal_multiplier := 1.0
	if weapon.automatic:
		vertical_multiplier = minf(
			automatic_vertical_max_multiplier,
			automatic_vertical_base_multiplier
			+ float(_burst_shots) * automatic_vertical_per_shot
		)
		horizontal_multiplier = minf(
			automatic_horizontal_max_multiplier,
			automatic_horizontal_base_multiplier
			+ float(_burst_shots) * automatic_horizontal_per_shot
		)

	var vertical_kick: float = (
		float(weapon.recoil_vertical_degrees) * float(_modifiers(weapon).recoil)
		* vertical_multiplier
		* _player.get_weapon_recoil_multiplier()
	)
	var horizontal_kick: float = randf_range(
		-float(weapon.recoil_horizontal_degrees) * float(_modifiers(weapon).recoil)
		* horizontal_multiplier
		* _player.get_weapon_recoil_multiplier(),
		float(weapon.recoil_horizontal_degrees) * float(_modifiers(weapon).recoil)
		* horizontal_multiplier
		* _player.get_weapon_recoil_multiplier()
	)

	_player.apply_weapon_recoil(
		vertical_kick,
		horizontal_kick,
		weapon.recoil_max_vertical_degrees,
		weapon.recoil_max_horizontal_degrees,
		weapon.recoil_recovery_degrees_per_second * float(_modifiers(weapon).recoil_recovery)
	)


func _shoot_hitscan(weapon: WeaponDefinition) -> void:
	var camera: Camera3D = _player.get_view_camera()
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state

	# ADS sırasında optik/arpacık ekran merkezini temsil eder; hitscan da tam
	# bu merkezden hesaplanır. Hip-fire sırasında ise hareketli HUD crosshair'i
	# atış otoritesi olmaya devam eder.
	var aim_screen_position: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	var uses_ads_optical_center := _player.is_aiming and weapon.supports_ads_pose
	if (
		not uses_ads_optical_center
		and GameState.hud != null
		and is_instance_valid(GameState.hud)
		and GameState.hud.has_method("get_crosshair_screen_position")
	):
		var hud_aim_position: Variant = GameState.hud.call("get_crosshair_screen_position")
		if typeof(hud_aim_position) == TYPE_VECTOR2:
			aim_screen_position = hud_aim_position

	var origin: Vector3 = camera.project_ray_origin(aim_screen_position)
	var forward: Vector3 = camera.project_ray_normal(aim_screen_position).normalized()
	var right: Vector3 = camera.global_transform.basis.x
	var up: Vector3 = camera.global_transform.basis.y
	var spread_multiplier := _player.get_weapon_spread_multiplier()
	if _player.is_aiming and weapon.supports_ads_pose:
		spread_multiplier = weapon.ads_spread_multiplier
	var spread_tangent: float = tan(
		deg_to_rad(weapon.spread_degrees * float(_modifiers(weapon).spread) * spread_multiplier)
	)
	var hit_something := false
	var damage_multiplier := float(_modifiers(weapon).damage)
	if _is_weapon_flashlight_active(weapon):
		damage_multiplier *= float(_modifiers(weapon).flashlight_damage)
	# Aynı tetik çekişinde bir hedefe isabet eden saçmaları tek hasar çağrısında
	# birleştir. Böylece pompalı 6-8 ayrı take_damage() çağrısıyla düşmanın
	# vurulma tepkisini spamlamaz; toplam hasar değişmez.
	var pending_damage: Dictionary = {}
	var pending_hit_positions: Dictionary = {}
	var penetration_power := maxf(
		0.0,
		weapon.penetration_power + float(_modifiers(weapon).penetration)
	)
	var extra_target_count := floori(penetration_power)
	var penetration_chance := penetration_power - float(extra_target_count)
	if penetration_chance > 0.0 and randf() < penetration_chance:
		extra_target_count += 1
	var target_limit := 1 + extra_target_count
	for _pellet: int in weapon.pellet_count:
		var direction: Vector3 = (
			forward
			+ right * randf_range(-spread_tangent, spread_tangent)
			+ up * randf_range(-spread_tangent, spread_tangent)
		).normalized()
		var exclusions: Array[RID] = [_player.get_rid()]
		var ray_origin := origin
		var target_hits := 0
		var ray_casts := 0
		var hit_targets: Array[Node] = []
		while target_hits < target_limit and ray_casts < target_limit + 4:
			ray_casts += 1
			var query := PhysicsRayQueryParameters3D.create(
				ray_origin,
				origin + direction * weapon.maximum_range,
				hitscan_collision_mask,
				exclusions
			)
			query.collide_with_areas = true
			var result := space_state.intersect_ray(query)
			if result.is_empty():
				break
			var collider := result.get("collider") as Object
			var damage_target := _resolve_damage_target(collider)
			# Delme yalnızca canlı/hedef nesneler arasında devam eder. Duvar ve
			# kapılar mermiyi durdurur; böylece arka odalardaki hedefler vurulmaz.
			if damage_target == null:
				break
			if collider is CollisionObject3D:
				exclusions.append((collider as CollisionObject3D).get_rid())
			var hit_position: Vector3 = result.get("position", Vector3.ZERO)
			ray_origin = hit_position + direction * 0.05
			if hit_targets.has(damage_target):
				continue
			hit_targets.append(damage_target)
			target_hits += 1
			var distance_damage_multiplier := _get_distance_damage_multiplier(
				weapon,
				origin.distance_to(hit_position)
			)
			var pellet_damage := maxi(
				1,
				roundi(float(weapon.damage_per_pellet) * damage_multiplier * distance_damage_multiplier)
			)
			var was_headshot := false
			if damage_target.has_method("get_weapon_hit_multiplier"):
				var upgraded_headshot := weapon.headshot_multiplier * float(_modifiers(weapon).headshot)
				var hit_multiplier := float(damage_target.call("get_weapon_hit_multiplier", hit_position, upgraded_headshot))
				pellet_damage = maxi(1, int(round(float(pellet_damage) * hit_multiplier)))
				was_headshot = hit_multiplier > 1.01
			if was_headshot:
				GameState.confirm_headshot()
			pending_damage[damage_target] = int(pending_damage.get(damage_target, 0)) + pellet_damage
			pending_hit_positions[damage_target] = hit_position
			hit_something = true

	for damage_target_variant: Variant in pending_damage:
		var damage_target := damage_target_variant as Node
		if damage_target == null or not is_instance_valid(damage_target):
			continue
		damage_target.call(
			"take_damage",
			int(pending_damage.get(damage_target, 0)),
			pending_hit_positions.get(damage_target, Vector3.ZERO),
			_player
		)

	if hit_something:
		GameState.confirm_hit()


func _get_distance_damage_multiplier(weapon: WeaponDefinition, distance: float) -> float:
	var start := maxf(0.0, weapon.damage_falloff_start_distance)
	var finish := maxf(0.0, weapon.damage_falloff_end_distance)
	if finish <= start or distance <= start:
		return 1.0
	var ratio := clampf((distance - start) / (finish - start), 0.0, 1.0)
	return lerpf(1.0, weapon.damage_falloff_min_multiplier, ratio)


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _play_hud_action(action: StringName) -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("play_weapon_action"):
		GameState.hud.call("play_weapon_action", current_weapon_id, action)
