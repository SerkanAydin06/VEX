class_name VexWeaponHeatRuntime
extends RefCounted


static func initialize_weapon_state(
	weapon: WeaponDefinition,
	weapon_heat: Dictionary,
	weapon_overheated: Dictionary,
	heat_cooldown_remaining: Dictionary
) -> void:
	if weapon == null:
		return
	weapon_heat[weapon.weapon_id] = 0.0
	weapon_overheated[weapon.weapon_id] = false
	heat_cooldown_remaining[weapon.weapon_id] = 0.0


static func effective_capacity(weapon: WeaponDefinition, modifiers: Dictionary) -> float:
	if weapon == null:
		return 0.0
	return weapon.heat_capacity * float(modifiers.heat_capacity)


static func publish_current(
	weapon: WeaponDefinition,
	weapon_id: StringName,
	weapon_heat: Dictionary,
	weapon_overheated: Dictionary,
	modifiers: Dictionary
) -> void:
	if weapon == null or not weapon.uses_heat:
		GameState.publish_weapon_heat(0.0, 0.0, false, false)
		return
	GameState.publish_weapon_heat(
		float(weapon_heat.get(weapon_id, 0.0)),
		effective_capacity(weapon, modifiers),
		bool(weapon_overheated.get(weapon_id, false)),
		true
	)


static func update(
	delta: float,
	definitions_by_id: Dictionary,
	current_weapon_id: StringName,
	weapon_heat: Dictionary,
	weapon_overheated: Dictionary,
	heat_cooldown_remaining: Dictionary,
	upgrade_levels: Dictionary
) -> bool:
	var current_weapon_cooled := false
	for weapon_id: StringName in definitions_by_id.keys():
		var weapon := definitions_by_id.get(weapon_id) as WeaponDefinition
		if weapon == null or not weapon.uses_heat:
			continue
		var modifiers := VexWeaponUpgradeCatalog.get_modifiers(
			weapon.weapon_id,
			maxi(0, int(upgrade_levels.get(weapon.weapon_id, 0)))
		)
		var cooldown := maxf(
			0.0,
			float(heat_cooldown_remaining.get(weapon_id, 0.0)) - delta
		)
		heat_cooldown_remaining[weapon_id] = cooldown
		var current_heat := float(weapon_heat.get(weapon_id, 0.0))
		if cooldown <= 0.0:
			var cooling := weapon.heat_cooling_per_second * float(modifiers.heat_cooling)
			current_heat = maxf(0.0, current_heat - cooling * delta)
			weapon_heat[weapon_id] = current_heat
		if (
			bool(weapon_overheated.get(weapon_id, false))
			and current_heat <= effective_capacity(weapon, modifiers) * weapon.heat_unlock_ratio
		):
			weapon_overheated[weapon_id] = false
			if weapon_id == current_weapon_id:
				current_weapon_cooled = true
	return current_weapon_cooled


static func can_fire(
	weapon: WeaponDefinition,
	weapon_id: StringName,
	weapon_heat: Dictionary,
	weapon_overheated: Dictionary,
	modifiers: Dictionary
) -> bool:
	if weapon == null or not weapon.uses_heat:
		return true
	var heat_capacity := effective_capacity(weapon, modifiers)
	var current_heat := float(weapon_heat.get(weapon_id, 0.0))
	if current_heat >= heat_capacity:
		weapon_overheated[weapon_id] = true
	return not bool(weapon_overheated.get(weapon_id, false))


static func register_shot(
	weapon: WeaponDefinition,
	weapon_id: StringName,
	weapon_heat: Dictionary,
	weapon_overheated: Dictionary,
	heat_cooldown_remaining: Dictionary,
	modifiers: Dictionary
) -> bool:
	if weapon == null or not weapon.uses_heat:
		return false
	var heat_capacity := effective_capacity(weapon, modifiers)
	var next_heat := minf(
		heat_capacity,
		float(weapon_heat.get(weapon_id, 0.0)) + weapon.heat_per_shot
	)
	weapon_heat[weapon_id] = next_heat
	heat_cooldown_remaining[weapon_id] = weapon.heat_cooldown_delay
	if next_heat >= heat_capacity:
		weapon_overheated[weapon_id] = true
		return true
	return false
