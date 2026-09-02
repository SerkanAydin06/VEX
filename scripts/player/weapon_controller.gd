class_name VexWeaponController
extends Node

# Mimari sahiplik notu: penetration_power ve target_limit hesapları
# VexWeaponHitscanRuntime içindedir; legacy_magnum_count save migration'ı ise
# VexWeaponPersistenceRuntime tarafından normalize edilir.

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
var weapon_heat: Dictionary = {}
var weapon_overheated: Dictionary = {}
var _heat_cooldown_remaining: Dictionary = {}


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
		weapon_heat[definition.weapon_id] = 0.0
		weapon_overheated[definition.weapon_id] = false
		_heat_cooldown_remaining[definition.weapon_id] = 0.0
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
	_update_weapon_heat(delta)
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
	return VexWeaponPersistenceRuntime.canonical_weapon_id(weapon_id)


func _canonicalize_weapon_dictionary(source: Dictionary) -> Dictionary:
	return VexWeaponPersistenceRuntime.canonicalize_weapon_dictionary(source)


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
	await get_tree().create_timer(weapon.reload_duration * float(_modifiers(weapon).reload), false).timeout
	if not is_inside_tree() or _player.is_dead:
		is_reloading = false
		return
	# Reload sürerken ammo pickup alınmış olabilir. Başlangıçta snapshot alınan
	# reserve değerini geri yazmak yeni toplanan mermileri silebilir; bitişte
	# her iki değeri de canlı state'ten tekrar oku.
	var live_magazine := int(magazines.get(weapon.weapon_id, 0))
	var live_reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
	var live_magazine_size := _effective_magazine_size(weapon)
	var required: int = maxi(0, live_magazine_size - live_magazine)
	var loaded: int = mini(required, live_reserve)
	magazines[weapon.weapon_id] = live_magazine + loaded
	reserve_ammo[weapon.ammo_type] = live_reserve - loaded
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
		await get_tree().create_timer(shell_cycle_duration, false).timeout
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
	await get_tree().create_timer(finish_duration, false).timeout
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
	return VexWeaponPersistenceRuntime.get_reserve_ammo_capacity(weapon_definitions, ammo_type)


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

	var first_acquisition := not acquired_weapons.has(canonical_id)
	if first_acquisition:
		acquired_weapons.append(canonical_id)
	var displaced_weapon_id := _make_room_for_loadout_group(canonical_id, definition)
	if not unlocked_weapons.has(canonical_id):
		unlocked_weapons.append(canonical_id)
	# Yalnız ilk dünya pickup'ı tam şarjör verir. Daha önce taşınıp yere bırakılmış
	# boş silah tekrar alınırken eski şarjör state'i korunur; ammo çoğaltılmaz.
	if first_acquisition and int(magazines.get(canonical_id, 0)) <= 0:
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
		GameState.publish_weapon_heat(0.0, 0.0, false, false)
		return
	GameState.publish_weapon(weapon.weapon_id, weapon.display_name)
	GameState.publish_ammo(
		int(magazines.get(current_weapon_id, 0)),
		int(reserve_ammo.get(weapon.ammo_type, 0))
	)
	_publish_current_weapon_heat()


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
	for carried_weapon_id: StringName in unlocked_weapons:
		if not acquired_weapons.has(carried_weapon_id):
			acquired_weapons.append(carried_weapon_id)
	magazines = _canonicalize_weapon_dictionary((state.get("magazines", magazines) as Dictionary).duplicate(true))
	reserve_ammo = _migrate_legacy_ammo_dictionary(
		(state.get("reserve_ammo", reserve_ammo) as Dictionary).duplicate(true)
	)
	current_weapon_id = canonical_weapon_id(StringName(str(state.get("current_weapon_id", initial_weapon_id))))
	upgrade_levels = _canonicalize_weapon_dictionary((state.get("upgrade_levels", upgrade_levels) as Dictionary).duplicate(true))
	_sanitize_restored_weapon_state()
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
	return VexWeaponPersistenceRuntime.migrate_legacy_ammo_dictionary(source, weapon_definitions)


func _sanitize_restored_weapon_state() -> void:
	var sanitized := VexWeaponPersistenceRuntime.sanitize_restored_weapon_state(
		weapon_definitions,
		magazines,
		reserve_ammo,
		upgrade_levels
	)
	magazines = sanitized.get("magazines", {}) as Dictionary
	reserve_ammo = sanitized.get("reserve_ammo", {}) as Dictionary
	upgrade_levels = sanitized.get("upgrade_levels", {}) as Dictionary


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


func _effective_heat_capacity(weapon: WeaponDefinition) -> float:
	return weapon.heat_capacity * float(_modifiers(weapon).heat_capacity)


func _publish_current_weapon_heat() -> void:
	var weapon := get_current_weapon()
	if weapon == null or not weapon.uses_heat:
		GameState.publish_weapon_heat(0.0, 0.0, false, false)
		return
	GameState.publish_weapon_heat(
		float(weapon_heat.get(current_weapon_id, 0.0)),
		_effective_heat_capacity(weapon),
		bool(weapon_overheated.get(current_weapon_id, false)),
		true
	)


func _update_weapon_heat(delta: float) -> void:
	for weapon_id: StringName in _definitions_by_id.keys():
		var weapon := _definitions_by_id.get(weapon_id) as WeaponDefinition
		if weapon == null or not weapon.uses_heat:
			continue
		var cooldown := maxf(0.0, float(_heat_cooldown_remaining.get(weapon_id, 0.0)) - delta)
		_heat_cooldown_remaining[weapon_id] = cooldown
		var current_heat := float(weapon_heat.get(weapon_id, 0.0))
		if cooldown <= 0.0:
			var cooling := weapon.heat_cooling_per_second * float(_modifiers(weapon).heat_cooling)
			current_heat = maxf(0.0, current_heat - cooling * delta)
			weapon_heat[weapon_id] = current_heat
		if (
			bool(weapon_overheated.get(weapon_id, false))
			and current_heat <= _effective_heat_capacity(weapon) * weapon.heat_unlock_ratio
		):
			weapon_overheated[weapon_id] = false
			if weapon_id == current_weapon_id:
				GameState.notify(tr("WEAPON_COOLED"))
	if get_current_weapon() != null and get_current_weapon().uses_heat:
		_publish_current_weapon_heat()


func _try_fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null or _cooldown_remaining > 0.0 or is_reloading:
		return
	if weapon.uses_heat:
		var heat_capacity := _effective_heat_capacity(weapon)
		var current_heat := float(weapon_heat.get(current_weapon_id, 0.0))
		if current_heat >= heat_capacity:
			weapon_overheated[current_weapon_id] = true
		if bool(weapon_overheated.get(current_weapon_id, false)):
			_play_hud_action(&"empty")
			GameState.notify(tr("WEAPON_OVERHEATED"))
			_cooldown_remaining = empty_trigger_cooldown
			_publish_current_weapon_heat()
			return
	var magazine := int(magazines.get(current_weapon_id, 0))
	if magazine <= 0:
		_play_hud_action(&"empty")
		GameState.notify(tr("WEAPON_EMPTY_RELOAD"))
		_cooldown_remaining = empty_trigger_cooldown
		return
	magazines[current_weapon_id] = magazine - 1
	if weapon.uses_heat:
		var shot_heat_capacity := _effective_heat_capacity(weapon)
		var next_heat := minf(
			shot_heat_capacity,
			float(weapon_heat.get(current_weapon_id, 0.0)) + weapon.heat_per_shot
		)
		weapon_heat[current_weapon_id] = next_heat
		_heat_cooldown_remaining[current_weapon_id] = weapon.heat_cooldown_delay
		if next_heat >= shot_heat_capacity:
			weapon_overheated[current_weapon_id] = true
			GameState.notify(tr("WEAPON_OVERHEATED"))
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
	VexWeaponHitscanRuntime.shoot(
		weapon,
		_player,
		hitscan_collision_mask,
		_modifiers(weapon),
		_is_weapon_flashlight_active(weapon)
	)


func _play_hud_action(action: StringName) -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("play_weapon_action"):
		GameState.hud.call("play_weapon_action", current_weapon_id, action)
