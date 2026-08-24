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
	&"sg04": [
		{"id": &"choke", "name": "UPGRADE_CHOKE", "spread": 0.72},
		{"id": &"drum_extension", "name": "UPGRADE_DRUM_EXTENSION", "magazine": 2, "reload": 0.90},
		{"id": &"breacher", "name": "UPGRADE_BREACHER", "damage": 1.18, "recoil": 1.12},
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
	var result := {"damage": 1.0, "reload": 1.0, "spread": 1.0, "recoil": 1.0, "headshot": 1.0, "fire_rate": 1.0, "magazine": 0}
	var track := get_track(weapon_id)
	for index in range(mini(level, track.size())):
		var tier: Dictionary = track[index]
		for key in result.keys():
			if not tier.has(key):
				continue
			if key == "magazine":
				result[key] = int(result[key]) + int(tier[key])
			else:
				result[key] = float(result[key]) * float(tier[key])
	return result
