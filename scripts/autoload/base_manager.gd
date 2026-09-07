extends Node

signal base_state_changed
signal area_access_changed(area_id: StringName, unlocked: bool)
signal lighting_mode_changed(mode: int)
signal upgrade_level_changed(upgrade_id: StringName, level: int)

enum LightingMode {
	LEVEL_25,
	LEVEL_50,
	LEVEL_75,
	LEVEL_100,
}

const AREA_DEFINITIONS := [
	{
		"id": &"firing_range",
		"door_node": &"FiringRangeDoor",
		"required_stage": 1,
		"name_tr": "ATIŞ POLİGONU",
		"name_en": "FIRING RANGE",
		"description_tr": "Bastion-7 eğitim ve silah test alanı. VEX-01 sonrası yerel üs yönetiminden yeniden etkinleştirilebilir.",
		"description_en": "Bastion-7 training and weapon test range. It can be recommissioned from local base management after VEX-01.",
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
		"mode": LightingMode.LEVEL_25,
		"required_stage": 0,
		"name_tr": "AYDINLATMA SEVİYESİ 1",
		"name_en": "LIGHTING LEVEL 1",
		"description_tr": "Başlangıç güç bütçesi. Bastion oda armatürlerini sahnede tanımlanan değerlerin %25'i ile çalıştırır.",
		"description_en": "Initial power budget. Runs Bastion room fixtures at 25% of their scene-authored values.",
		"energy_multiplier": 0.25,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
	},
	{
		"mode": LightingMode.LEVEL_50,
		"required_stage": 1,
		"name_tr": "AYDINLATMA SEVİYESİ 2",
		"name_en": "LIGHTING LEVEL 2",
		"description_tr": "VEX-01 sonrası açılan güç kademesi. Ana oda aydınlatmasını %50 seviyesine yükseltir.",
		"description_en": "Power tier unlocked after VEX-01. Raises primary room lighting to 50%.",
		"energy_multiplier": 0.50,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
	},
	{
		"mode": LightingMode.LEVEL_75,
		"required_stage": 2,
		"name_tr": "AYDINLATMA SEVİYESİ 3",
		"name_en": "LIGHTING LEVEL 3",
		"description_tr": "VEX-02 sonrası açılan güç kademesi. Ana oda aydınlatmasını %75 seviyesine yükseltir.",
		"description_en": "Power tier unlocked after VEX-02. Raises primary room lighting to 75%.",
		"energy_multiplier": 0.75,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
	},
	{
		"mode": LightingMode.LEVEL_100,
		"required_stage": 3,
		"name_tr": "AYDINLATMA SEVİYESİ 4",
		"name_en": "LIGHTING LEVEL 4",
		"description_tr": "VEX-03 sonrası açılan tam güç kademesi. Armatürleri sahnede tanımlanan %100 authored değerlerine döndürür.",
		"description_en": "Full-power tier unlocked after VEX-03. Restores fixtures to 100% of their scene-authored values.",
		"energy_multiplier": 1.0,
		"tint": Color(1.0, 1.0, 1.0, 1.0),
		"tint_strength": 0.0,
	},
]

const UPGRADE_DEFINITIONS := [
	{
		"id": &"power_grid",
		"max_level": 3,
		"required_stage": 1,
		"name_tr": "ENERJİ DAĞITIM AĞI",
		"name_en": "POWER DISTRIBUTION GRID",
		"description_tr": "İleride üs enerji kapasitesi, oda aktivasyonu ve gelişmiş sistem maliyetleri için kullanılacak temel geliştirme hattı.",
		"description_en": "Foundation upgrade track for future base energy capacity, room activation and advanced-system costs.",
	},
	{
		"id": &"security_grid",
		"max_level": 3,
		"required_stage": 2,
		"name_tr": "GÜVENLİK AĞI",
		"name_en": "SECURITY GRID",
		"description_tr": "Kapı yetkileri, alarm durumları ve ileride eklenecek üs savunma sistemleri için ayrılmış geliştirme hattı.",
		"description_en": "Upgrade track reserved for door permissions, alarm states and future base-defense systems.",
	},
	{
		"id": &"research_infrastructure",
		"max_level": 3,
		"required_stage": 3,
		"name_tr": "ARAŞTIRMA ALTYAPISI",
		"name_en": "RESEARCH INFRASTRUCTURE",
		"description_tr": "Xeno arşivi, araştırma laboratuvarı ve ileride açılacak teknoloji geliştirmeleri için altyapı yuvası.",
		"description_en": "Infrastructure slot for the xeno archive, research lab and future technology progression.",
	},
]

var _unlocked_areas: Dictionary = {}
var _lighting_mode: LightingMode = LightingMode.LEVEL_25
var _upgrade_levels: Dictionary = {}


func reset_campaign_state(emit_changes := true) -> void:
	_unlocked_areas.clear()
	_upgrade_levels.clear()
	_lighting_mode = LightingMode.LEVEL_25
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
	_lighting_mode = LightingMode.LEVEL_25
	var unlocked_values: Array = state.get("unlocked_areas", []) as Array
	for value: Variant in unlocked_values:
		var area_id := StringName(str(value))
		if not get_area_definition(area_id).is_empty():
			_unlocked_areas[area_id] = true
	var restored_mode := int(state.get("lighting_mode", LightingMode.LEVEL_25))
	if restored_mode >= LightingMode.LEVEL_25 and restored_mode <= LightingMode.LEVEL_100:
		_lighting_mode = restored_mode as LightingMode
	var restored_upgrades: Variant = state.get("upgrade_levels", {})
	if restored_upgrades is Dictionary:
		var upgrade_dictionary := restored_upgrades as Dictionary
		for key: Variant in upgrade_dictionary.keys():
			var upgrade_id := StringName(str(key))
			var definition := get_upgrade_definition(upgrade_id)
			if definition.is_empty():
				continue
			_upgrade_levels[upgrade_id] = clampi(
				int(upgrade_dictionary.get(key, 0)),
				0,
				int(definition.get("max_level", 0))
			)
	_emit_full_state()


func sanitize_for_campaign_stage(campaign_stage: int) -> void:
	if can_use_lighting_mode(int(_lighting_mode), campaign_stage):
		return
	_lighting_mode = get_highest_available_lighting_mode(campaign_stage) as LightingMode
	lighting_mode_changed.emit(int(_lighting_mode))
	base_state_changed.emit()


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


func get_lighting_required_stage(mode: int) -> int:
	var definition := get_lighting_definition(mode)
	return int(definition.get("required_stage", 999)) if not definition.is_empty() else 999


func can_use_lighting_mode(mode: int, campaign_stage: int) -> bool:
	var definition := get_lighting_definition(mode)
	return not definition.is_empty() and campaign_stage >= int(definition.get("required_stage", 0))


func get_highest_available_lighting_mode(campaign_stage: int) -> int:
	var highest := int(LightingMode.LEVEL_25)
	for definition: Dictionary in LIGHTING_DEFINITIONS:
		var mode := int(definition.get("mode", LightingMode.LEVEL_25))
		if can_use_lighting_mode(mode, campaign_stage):
			highest = maxi(highest, mode)
	return highest


func set_lighting_mode(mode: int, campaign_stage: int) -> bool:
	if not can_use_lighting_mode(mode, campaign_stage) or mode == int(_lighting_mode):
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


func is_upgrade_available(upgrade_id: StringName, campaign_stage: int) -> bool:
	var definition := get_upgrade_definition(upgrade_id)
	return not definition.is_empty() and campaign_stage >= int(definition.get("required_stage", 0))


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
