class_name VexWeaponUpgradeCatalog
extends RefCounted

# Three deterministic tiers per weapon. Visual assets are deliberately not
# referenced here, so final weapon art can be replaced without touching logic.
const TRACKS := {
	&"pistol": [
		{"id": &"match_barrel", "name": "EŞLEŞTİRİLMİŞ NAMLU", "damage": 1.12},
		{"id": &"quick_mag", "name": "HIZLI ŞARJÖR", "reload": 0.82, "magazine": 3},
		{"id": &"ghost_trigger", "name": "HAYALET TETİK", "spread": 0.55, "headshot": 1.15},
	],
	&"shotgun": [
		{"id": &"choke", "name": "DAR ŞOK", "spread": 0.72},
		{"id": &"drum_extension", "name": "TÜP UZATMA", "magazine": 2, "reload": 0.90},
		{"id": &"breacher", "name": "YARICI YÜK", "damage": 1.18, "recoil": 1.12},
	],
	&"ak47": [
		{"id": &"gas_regulator", "name": "GAZ REGÜLATÖRÜ", "recoil": 0.82},
		{"id": &"smart_feed", "name": "AKILLI BESLEME", "reload": 0.80},
		{"id": &"overpressure", "name": "YÜKSEK BASINÇ", "damage": 1.16, "spread": 1.10},
	],
	&"mp90": [
		{"id": &"vector_grip", "name": "VEKTÖR KABZA", "recoil": 0.76},
		{"id": &"helical_feed", "name": "HELİSEL BESLEME", "magazine": 10},
		{"id": &"phase_cycler", "name": "FAZ ÇEVRİCİ", "fire_rate": 0.84, "spread": 1.12},
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
