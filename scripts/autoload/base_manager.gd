extends Node

signal base_state_changed
signal area_access_changed(area_id: StringName, unlocked: bool)
signal lighting_mode_changed(mode: int)
signal upgrade_level_changed(upgrade_id: StringName, level: int)

enum LightingMode {
	STANDARD,
	LOW_POWER,
	EMERGENCY,
}

const AREA_DEFINITIONS := [
	{
		"id": &"firing_range",
		"door_node": &"FiringRangeDoor",
		"required_stage": 0,
		"name_tr": "ATIŞ POLİGONU",
		"name_en": "FIRING RANGE",
		"description_tr": "Bastion-7 eğitim ve silah test alanı. Erişim yerel üs yönetiminden yeniden etkinleştirilebilir.",
		"description_en": "Bastion-7 training and weapon test range. Access can be restored from local base management.",
	},
	{
		"id": &"research_lab",
		"door_node": &"ResearchDoor",
		"required_stage": 1,
		"name_tr": "ARAŞTIRMA LABORATUVARI",
		"name_en": "RESEARCH LAB",
		"description_tr": "Xeno örnekleri ve boyutsal materyal analizi için ayrılmış laboratuvar. VEX-01 saha verisi sonrası yeniden devreye alınabilir.",
		"description_en": "Laboratory reserved for xeno samples and dimensional-material analysis. It can be recommissioned after VEX-01 field data is secured.",
	},
	{
		"id": &"weapon_workshop",
		"door_node": &"WorkshopDoor",
		"required_stage": 2,
		"name_tr": "SİLAH ATÖLYESİ",
		"name_en": "WEAPON WORKSHOP",
		"description_tr": "Silah bakım, modifikasyon ve ileride kurulacak üretim/geliştirme sistemleri için ayrılmış teknik alan.",
		"description_en": "Technical area reserved for weapon maintenance, modification and future fabrication/upgrade systems.",
	},
	{
		"id": &"engineering_bay",
		"door_node": &"EngineeringDoor",
		"required_stage": 2,
		"name_tr": "MÜHENDİSLİK BÖLMESİ",
		"name_en": "ENGINEERING BAY",
		"description_tr": "Üs güç dağıtımı, kapı ağı ve ileride eklenecek Bastion geliştirmeleri için ana teknik bölüm.",
		"description_en": "Primary technical bay for base power distribution, the door network and future Bastion upgrades.",
	},
]

const LIGHTING_DEFINITIONS := [
	{
		"mode": LightingMode.STANDARD,
		"name_tr": "STANDART AYDINLATMA",
		"name_en": "STANDARD LIGHTING",
		"description_tr": "Oda armatürlerini sahnede tanımlanan normal enerji ve renk değerlerinde çalıştırır.",
		"description_en": "Runs room fixtures at their normal scene-authored energy and color values.",
		"energy_multiplier": 1.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
	},
	{
		"mode": LightingMode.LOW_POWER,
		"name_tr": "DÜŞÜK GÜÇ MODU",
		"name_en": "LOW POWER MODE",
		"description_tr": "Ana oda ışıklarını yaklaşık yarı güçte çalıştırır. Gelecekte enerji ekonomisi bu moda bağlanabilir.",
		"description_en": "Runs primary room lighting at roughly half power. A future energy economy can hook into this mode.",
		"energy_multiplier": 0.48,
		"tint": Color(0.72, 0.88, 1.0, 1.0),
		"tint_strength": 0.16,
	},
	{
		"mode": LightingMode.EMERGENCY,
		"name_tr": "ACİL DURUM MODU",
		"name_en": "EMERGENCY MODE",
		"description_tr": "Ana aydınlatmayı düşük seviyeye indirir ve kırmızı acil durum tonuna çeker. Oynanış alarm sistemleri daha sonra bu profile bağlanabilir.",
		"description_en": "Reduces primary lighting and shifts it toward an emergency red tone. Future gameplay alarm systems can hook into this profile.",
		"energy_multiplier": 0.28,
		"tint": Color(1.0, 0.18, 0.12, 1.0),
		"tint_strength": 0.72,
	},
]

const UPGRADE_DEFINITIONS := [
	{
		"id": &"power_grid",
		"max_level": 3,
		"name_tr": "ENERJİ DAĞITIM AĞI",
		"name_en": "POWER DISTRIBUTION GRID",
		"description_tr": "İleride üs enerji kapasitesi, oda aktivasyonu ve gelişmiş sistem maliyetleri için kullanılacak temel geliştirme hattı.",
		"description_en": "Foundation upgrade track for future base energy capacity, room activation and advanced-system costs.",
	},
	{
		"id": &"security_grid",
		"max_level": 3,
		"name_tr": "GÜVENLİK AĞI",
		"name_en": "SECURITY GRID",
		"description_tr": "Kapı yetkileri, alarm durumları ve ileride eklenecek üs savunma sistemleri için ayrılmış geliştirme hattı.",
		"description_en": "Upgrade track reserved for door permissions, alarm states and future base-defense systems.",
	},
	{
		"id": &"research_infrastructure",
		"max_level": 3,
		"name_tr": "ARAŞTIRMA ALTYAPISI",
		"name_en": "RESEARCH INFRASTRUCTURE",
		"description_tr": "Xeno arşivi, araştırma laboratuvarı ve ileride açılacak teknoloji geliştirmeleri için altyapı yuvası.",
		"description_en": "Infrastructure slot for the xeno archive, research lab and future technology progression.",
	},
]

var _unlocked_areas: Dictionary = {}
var _lighting_mode: LightingMode = LightingMode.STANDARD
var _upgrade_levels: Dictionary = {}


func reset_campaign_state(emit_changes := true) -> void:
	_unlocked_areas.clear()
	_upgrade_levels.clear()
	_lighting_mode = LightingMode.STANDARD
	if emit_changes:
		_emit_full_state()


func capture_state() -> Dictionary:
	var unlocked: Array[String] = []
	for definition: Dictionary in AREA_DEFINITIONS:
		var area_id := StringName(str(definition.get("id", "")))
		if is_area_unlocked(area_id):
			unlocked.append(str(area_id))
	return {
		"unlocked_areas": unlocked,
		"lighting_mode": int(_lighting_mode),
		"upgrade_levels": _upgrade_levels.duplicate(true),
	}


func restore_state(state: Dictionary) -> void:
	_unlocked_areas.clear()
	_upgrade_levels.clear()
	_lighting_mode = LightingMode.STANDARD
	for value: Variant in state.get("unlocked_areas", []) as Array:
		var area_id := StringName(str(value))
		if not get_area_definition(area_id).is_empty():
			_unlocked_areas[area_id] = true
	var restored_mode := int(state.get("lighting_mode", LightingMode.STANDARD))
	if restored_mode >= LightingMode.STANDARD and restored_mode <= LightingMode.EMERGENCY:
		_lighting_mode = restored_mode as LightingMode
	var restored_upgrades: Variant = state.get("upgrade_levels", {})
	if restored_upgrades is Dictionary:
		for key: Variant in (restored_upgrades as Dictionary).keys():
			var upgrade_id := StringName(str(key))
			var definition := get_upgrade_definition(upgrade_id)
			if definition.is_empty():
				continue
			_upgrade_levels[upgrade_id] = clampi(
				int((restored_upgrades as Dictionary).get(key, 0)),
				0,
				int(definition.get("max_level", 0))
			)
	_emit_full_state()


func get_area_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in AREA_DEFINITIONS:
		result.append(definition.duplicate(true))
	return result


func get_area_definition(area_id: StringName) -> Dictionary:
	for definition: Dictionary in AREA_DEFINITIONS:
		if StringName(str(definition.get("id", ""))) == area_id:
			return definition
	return {}


func is_area_unlocked(area_id: StringName) -> bool:
	return bool(_unlocked_areas.get(area_id, false))


func can_unlock_area(area_id: StringName, campaign_stage: int) -> bool:
	var definition := get_area_definition(area_id)
	if definition.is_empty() or is_area_unlocked(area_id):
		return false
	return campaign_stage >= int(definition.get("required_stage", 0))


func unlock_area(area_id: StringName, campaign_stage: int) -> bool:
	if not can_unlock_area(area_id, campaign_stage):
		return false
	_unlocked_areas[area_id] = true
	area_access_changed.emit(area_id, true)
	base_state_changed.emit()
	return true


func get_lighting_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in LIGHTING_DEFINITIONS:
		result.append(definition.duplicate(true))
	return result


func get_lighting_definition(mode: int) -> Dictionary:
	for definition: Dictionary in LIGHTING_DEFINITIONS:
		if int(definition.get("mode", -1)) == mode:
			return definition
	return {}


func get_lighting_mode() -> int:
	return int(_lighting_mode)


func set_lighting_mode(mode: int) -> bool:
	if get_lighting_definition(mode).is_empty() or mode == int(_lighting_mode):
		return false
	_lighting_mode = mode as LightingMode
	lighting_mode_changed.emit(mode)
	base_state_changed.emit()
	return true


func get_upgrade_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for definition: Dictionary in UPGRADE_DEFINITIONS:
		result.append(definition.duplicate(true))
	return result


func get_upgrade_definition(upgrade_id: StringName) -> Dictionary:
	for definition: Dictionary in UPGRADE_DEFINITIONS:
		if StringName(str(definition.get("id", ""))) == upgrade_id:
			return definition
	return {}


func get_upgrade_level(upgrade_id: StringName) -> int:
	return int(_upgrade_levels.get(upgrade_id, 0))


func set_upgrade_level(upgrade_id: StringName, level: int) -> bool:
	var definition := get_upgrade_definition(upgrade_id)
	if definition.is_empty():
		return false
	var safe_level := clampi(level, 0, int(definition.get("max_level", 0)))
	if safe_level == get_upgrade_level(upgrade_id):
		return false
	_upgrade_levels[upgrade_id] = safe_level
	upgrade_level_changed.emit(upgrade_id, safe_level)
	base_state_changed.emit()
	return true


func _emit_full_state() -> void:
	for definition: Dictionary in AREA_DEFINITIONS:
		var area_id := StringName(str(definition.get("id", "")))
		area_access_changed.emit(area_id, is_area_unlocked(area_id))
	lighting_mode_changed.emit(int(_lighting_mode))
	for definition: Dictionary in UPGRADE_DEFINITIONS:
		var upgrade_id := StringName(str(definition.get("id", "")))
		upgrade_level_changed.emit(upgrade_id, get_upgrade_level(upgrade_id))
	base_state_changed.emit()
