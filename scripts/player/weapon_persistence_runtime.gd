class_name VexWeaponPersistenceRuntime
extends RefCounted


static func canonical_weapon_id(weapon_id: StringName) -> StringName:
	match str(weapon_id):
		"pistol":
			return &"p01"
		"shotgun":
			return &"sg04"
		"ak47":
			return &"vx47"
	return weapon_id


static func canonicalize_weapon_dictionary(source: Dictionary) -> Dictionary:
	var output: Dictionary = {}
	for key: Variant in source.keys():
		var canonical := canonical_weapon_id(StringName(str(key)))
		output[canonical] = source[key]
	return output


static func get_reserve_ammo_capacity(
	weapon_definitions: Array[WeaponDefinition],
	ammo_type: StringName
) -> int:
	var maximum := 0
	for definition: WeaponDefinition in weapon_definitions:
		if definition != null and definition.ammo_type == ammo_type:
			maximum = maxi(maximum, definition.reserve_ammo_capacity)
	return maximum


static func migrate_legacy_ammo_dictionary(
	source: Dictionary,
	weapon_definitions: Array[WeaponDefinition]
) -> Dictionary:
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
		get_reserve_ammo_capacity(weapon_definitions, &"bullets")
	)
	for definition: WeaponDefinition in weapon_definitions:
		if definition != null and not migrated.has(definition.ammo_type):
			migrated[definition.ammo_type] = 0
	return migrated


static func sanitize_restored_weapon_state(
	weapon_definitions: Array[WeaponDefinition],
	magazines: Dictionary,
	reserve_ammo: Dictionary,
	upgrade_levels: Dictionary
) -> Dictionary:
	var sanitized_upgrade_levels: Dictionary = {}
	for definition: WeaponDefinition in weapon_definitions:
		if definition == null:
			continue
		var maximum_upgrade_level := VexWeaponUpgradeCatalog.get_track(definition.weapon_id).size()
		sanitized_upgrade_levels[definition.weapon_id] = clampi(
			int(upgrade_levels.get(definition.weapon_id, 0)),
			0,
			maximum_upgrade_level
		)

	var sanitized_magazines: Dictionary = {}
	for definition: WeaponDefinition in weapon_definitions:
		if definition == null:
			continue
		var upgrade_level := int(sanitized_upgrade_levels.get(definition.weapon_id, 0))
		var modifiers := VexWeaponUpgradeCatalog.get_modifiers(definition.weapon_id, upgrade_level)
		var maximum_magazine := definition.magazine_size + int(modifiers.magazine)
		sanitized_magazines[definition.weapon_id] = clampi(
			int(magazines.get(definition.weapon_id, 0)),
			0,
			maximum_magazine
		)

	var sanitized_reserve_ammo: Dictionary = {}
	for definition: WeaponDefinition in weapon_definitions:
		if definition == null or sanitized_reserve_ammo.has(definition.ammo_type):
			continue
		sanitized_reserve_ammo[definition.ammo_type] = clampi(
			int(reserve_ammo.get(definition.ammo_type, 0)),
			0,
			get_reserve_ammo_capacity(weapon_definitions, definition.ammo_type)
		)

	return {
		"magazines": sanitized_magazines,
		"reserve_ammo": sanitized_reserve_ammo,
		"upgrade_levels": sanitized_upgrade_levels,
	}
