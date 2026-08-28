class_name VexWeaponUpgradeCatalog
extends RefCounted

# Three deterministic tiers per weapon. Visual assets are deliberately not
# referenced here, so final weapon art can be replaced without touching logic.
const TRACKS := {
	&"p01": [
		{"id": &"match_barrel", "name": "UPGRADE_MATCH_BARREL", "damage": 1.12},
		{"id": &"quick_mag", "name": "UPGRADE_QUICK_MAG", "reload": 0.82, "magazine": 3},
		{"id": &"ghost_trigger", "name": "UPGRADE_GHOST_TRIGGER", "spread": 0.55, "headshot": 1.15},
	],
	&"p07": [
		{"id": &"luma_array", "name": "UPGRADE_LUMA_ARRAY", "flashlight_range": 1.35, "flashlight_energy": 1.12},
		{"id": &"micro_compensator", "name": "UPGRADE_MICRO_COMPENSATOR", "recoil": 0.75, "recoil_recovery": 1.20},
		{"id": &"sentinel_link", "name": "UPGRADE_SENTINEL_LINK", "flashlight_damage": 1.15},
	],
	&"p14": [
		{"id": &"variable_sight", "name": "UPGRADE_VARIABLE_SIGHT", "spread": 0.80},
		{"id": &"silent_baffle", "name": "UPGRADE_SILENT_BAFFLE", "gunshot_noise": 0.40},
		{"id": &"needle_rounds", "name": "UPGRADE_NEEDLE_ROUNDS", "headshot": 1.20},
	],
	&"p20": [
		{"id": &"inertial_piston", "name": "UPGRADE_INERTIAL_PISTON", "recoil": 0.70, "recoil_recovery": 1.25},
		{"id": &"overpressure_core", "name": "UPGRADE_OVERPRESSURE_CORE", "damage": 1.20, "recoil": 1.10},
		{"id": &"rupture_round", "name": "UPGRADE_RUPTURE_ROUND", "penetration": 0.50, "headshot": 1.25},
	],
	&"sg04": [
		{"id": &"choke", "name": "UPGRADE_CHOKE", "spread": 0.72},
		{"id": &"drum_extension", "name": "UPGRADE_DRUM_EXTENSION", "magazine": 2, "reload": 0.90},
		{"id": &"breacher", "name": "UPGRADE_BREACHER", "damage": 1.18, "recoil": 1.12},
	],
	&"sg09": [
		{"id": &"aegis_gas_drive", "name": "UPGRADE_AEGIS_GAS_DRIVE", "fire_rate": 0.88, "recoil": 0.90},
		{"id": &"smart_caddy", "name": "UPGRADE_SMART_CADDY", "magazine": 2, "reload": 0.80},
		{"id": &"flechette_load", "name": "UPGRADE_FLECHETTE_LOAD", "spread": 0.85},
	],
	&"vx47": [
		{"id": &"gas_regulator", "name": "UPGRADE_GAS_REGULATOR", "recoil": 0.82},
		{"id": &"smart_feed", "name": "UPGRADE_SMART_FEED", "reload": 0.80},
		{"id": &"overpressure", "name": "UPGRADE_OVERPRESSURE", "damage": 1.16, "spread": 1.10},
	],
	&"mp90": [
		{"id": &"vector_grip", "name": "UPGRADE_VECTOR_GRIP", "recoil": 0.76},
		{"id": &"helical_feed", "name": "UPGRADE_HELICAL_FEED", "magazine": 10},
		{"id": &"phase_cycler", "name": "UPGRADE_PHASE_CYCLER", "fire_rate": 0.84, "spread": 1.12},
	],
}


static func get_track(weapon_id: StringName) -> Array:
	return (TRACKS.get(weapon_id, []) as Array).duplicate(true)


static func get_modifiers(weapon_id: StringName, level: int) -> Dictionary:
	var result := {
		"damage": 1.0,
		"reload": 1.0,
		"spread": 1.0,
		"recoil": 1.0,
		"recoil_recovery": 1.0,
		"headshot": 1.0,
		"fire_rate": 1.0,
		"magazine": 0,
		"penetration": 0.0,
		"flashlight_range": 1.0,
		"flashlight_energy": 1.0,
		"flashlight_damage": 1.0,
		"gunshot_noise": 1.0,
	}
	var track := get_track(weapon_id)
	for index in range(mini(level, track.size())):
		var tier: Dictionary = track[index]
		for key in result.keys():
			if not tier.has(key):
				continue
			if key == "magazine":
				result[key] = int(result[key]) + int(tier[key])
			elif key == "penetration":
				result[key] = float(result[key]) + float(tier[key])
			else:
				result[key] = float(result[key]) * float(tier[key])
	return result
