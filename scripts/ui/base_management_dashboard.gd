@tool
class_name VexBaseManagementDashboard
extends PanelContainer

@export_category("Editor Preview")
@export var editor_preview := true

const COLOR_ONLINE := Color(0.30, 1.0, 0.62, 1.0)
const COLOR_READY := Color(1.0, 0.72, 0.24, 1.0)
const COLOR_LOCKED := Color(1.0, 0.30, 0.20, 1.0)
const COLOR_SYSTEM := Color(0.35, 0.88, 1.0, 1.0)
const COLOR_MUTED := Color(0.45, 0.58, 0.62, 1.0)

var base_tab: Button
var index_panel: Control
var detail_margin: Control
var _last_dashboard_active := false

@onready var dashboard_title: Label = %BaseDashboardTitle
@onready var dashboard_subtitle: Label = %BaseDashboardSubtitle
@onready var stage_badge: Label = %BaseStageBadge
@onready var access_value: Label = %BaseAccessValue
@onready var lighting_value: Label = %BaseLightingValue
@onready var lighting_load_value: Label = %BaseLightingLoadValue
@onready var upgrade_value: Label = %BaseUpgradeValue
@onready var facility_map_title: Label = %BaseFacilityMapTitle
@onready var lighting_title: Label = %BaseLightingTitle
@onready var upgrade_title: Label = %BaseUpgradeTitle
@onready var status_hint: Label = %BaseDashboardStatusHint

@onready var firing_range_button: Button = %FiringRangeAreaButton
@onready var research_button: Button = %ResearchAreaButton
@onready var workshop_button: Button = %WorkshopAreaButton
@onready var engineering_button: Button = %EngineeringAreaButton
@onready var armory_button: Button = %ArmoryAreaButton
@onready var command_button: Button = %CommandAreaButton
@onready var south_corridor_button: Button = %SouthCorridorAreaButton
@onready var operator_button: Button = %OperatorAreaButton

@onready var standard_lighting_button: Button = %StandardLightingButton
@onready var low_power_lighting_button: Button = %LowPowerLightingButton
@onready var emergency_lighting_button: Button = %EmergencyLightingButton
@onready var power_upgrade_button: Button = %PowerGridUpgradeButton
@onready var security_upgrade_button: Button = %SecurityGridUpgradeButton
@onready var research_upgrade_button: Button = %ResearchInfrastructureUpgradeButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_archive_nodes()
	if Engine.is_editor_hint():
		call_deferred("_apply_editor_preview")
		return
	firing_range_button.pressed.connect(_activate_area.bind(&"firing_range"))
	research_button.pressed.connect(_activate_area.bind(&"research_lab"))
	workshop_button.pressed.connect(_activate_area.bind(&"weapon_workshop"))
	engineering_button.pressed.connect(_activate_area.bind(&"engineering_bay"))
	standard_lighting_button.pressed.connect(_apply_lighting.bind(BaseManager.LightingMode.STANDARD))
	low_power_lighting_button.pressed.connect(_apply_lighting.bind(BaseManager.LightingMode.LOW_POWER))
	emergency_lighting_button.pressed.connect(_apply_lighting.bind(BaseManager.LightingMode.EMERGENCY))
	if not BaseManager.base_state_changed.is_connected(_on_base_state_changed):
		BaseManager.base_state_changed.connect(_on_base_state_changed)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	_sync_section_visibility(true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_sync_section_visibility()


func _resolve_archive_nodes() -> void:
	var current := get_parent()
	while current != null:
		if current is VexArchiveTerminal:
			base_tab = current.find_child("BaseManagementTab", true, false) as Button
			index_panel = current.find_child("IndexPanel", true, false) as Control
			detail_margin = current.find_child("DetailMargin", true, false) as Control
			return
		current = current.get_parent()


func _apply_editor_preview() -> void:
	visible = editor_preview
	if base_tab != null and editor_preview:
		base_tab.button_pressed = true
	if index_panel != null:
		index_panel.visible = not editor_preview
	if detail_margin != null:
		detail_margin.visible = not editor_preview
	_refresh_editor_text()


func _sync_section_visibility(force := false) -> void:
	if base_tab == null:
		return
	var active := base_tab.button_pressed
	if not force and active == _last_dashboard_active:
		return
	_last_dashboard_active = active
	visible = active
	if index_panel != null:
		index_panel.visible = not active
	if detail_margin != null:
		detail_margin.visible = not active
	if active:
		_refresh_dashboard()


func _refresh_dashboard() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_text()
		return
	_refresh_static_labels()
	_refresh_status_cards()
	_refresh_facility_map()
	_refresh_lighting_controls()
	_refresh_upgrade_controls()


func _refresh_static_labels() -> void:
	dashboard_title.text = _t("BASTION-7 // ÜS KONTROLÜ", "BASTION-7 // BASE CONTROL")
	dashboard_subtitle.text = _t(
		"YEREL TESİS AĞI // KAPI YETKİSİ // AYDINLATMA // GELİŞTİRME OMURGASI",
		"LOCAL FACILITY GRID // ACCESS // LIGHTING // UPGRADE BACKBONE"
	)
	facility_map_title.text = _t("TESİS ŞEMASI // CANLI DURUM", "FACILITY SCHEMATIC // LIVE STATUS")
	lighting_title.text = _t("AYDINLATMA DAĞITIMI", "LIGHTING DISTRIBUTION")
	upgrade_title.text = _t("GELİŞTİRME OMURGASI // GELECEK SİSTEM", "UPGRADE BACKBONE // FUTURE SYSTEM")
	status_hint.text = _t(
		"YEŞİL: AKTİF  //  TURUNCU: AKTİVASYONA HAZIR  //  KIRMIZI: YETKİ KİLİTLİ",
		"GREEN: ONLINE  //  AMBER: READY TO ACTIVATE  //  RED: CLEARANCE LOCKED"
	)


func _refresh_status_cards() -> void:
	var areas := BaseManager.get_area_definitions()
	var unlocked_count := 0
	for definition: Dictionary in areas:
		if BaseManager.is_area_unlocked(StringName(str(definition.get("id", "")))):
			unlocked_count += 1
	access_value.text = _t(
		"BÖLGE ERİŞİMİ\n%d / %d" % [unlocked_count, areas.size()],
		"AREA ACCESS\n%d / %d" % [unlocked_count, areas.size()]
	)
	access_value.add_theme_color_override("font_color", COLOR_ONLINE if unlocked_count == areas.size() else COLOR_SYSTEM)

	var lighting := BaseManager.get_lighting_definition(BaseManager.get_lighting_mode())
	lighting_value.text = "%s\n%s" % [_t("AYDINLATMA", "LIGHTING"), _localized(lighting, "name")]
	lighting_value.add_theme_color_override("font_color", _lighting_color(BaseManager.get_lighting_mode()))
	lighting_load_value.text = "%s\n%d%%" % [
		_t("IŞIK YÜKÜ", "LIGHT LOAD"),
		roundi(float(lighting.get("energy_multiplier", 1.0)) * 100.0),
	]
	lighting_load_value.add_theme_color_override("font_color", COLOR_SYSTEM)

	var upgrade_total := 0
	var upgrade_capacity := 0
	for definition: Dictionary in BaseManager.get_upgrade_definitions():
		var upgrade_id := StringName(str(definition.get("id", "")))
		upgrade_total += BaseManager.get_upgrade_level(upgrade_id)
		upgrade_capacity += int(definition.get("max_level", 0))
	upgrade_value.text = _t(
		"GELİŞTİRME\n%d / %d" % [upgrade_total, upgrade_capacity],
		"UPGRADES\n%d / %d" % [upgrade_total, upgrade_capacity]
	)
	upgrade_value.add_theme_color_override("font_color", COLOR_MUTED)
	stage_badge.text = _t(
		"KAMPANYA // AŞAMA %02d" % GameState.campaign_stage,
		"CAMPAIGN // STAGE %02d" % GameState.campaign_stage
	)


func _refresh_facility_map() -> void:
	_refresh_managed_area_button(firing_range_button, &"firing_range")
	_refresh_managed_area_button(research_button, &"research_lab")
	_refresh_managed_area_button(workshop_button, &"weapon_workshop")
	_refresh_managed_area_button(engineering_button, &"engineering_bay")
	_refresh_static_area_button(armory_button, _t("SİLAH DEPOSU", "ARMORY"))
	_refresh_static_area_button(command_button, _t("KOMUTA MERKEZİ", "COMMAND CORE"))
	_refresh_static_area_button(south_corridor_button, _t("GÜNEY KORİDORU", "SOUTH CORRIDOR"))
	_refresh_static_area_button(operator_button, _t("OPERATÖR PLATFORMU", "OPERATOR PLATFORM"))


func _refresh_managed_area_button(button: Button, area_id: StringName) -> void:
	var definition := BaseManager.get_area_definition(area_id)
	var unlocked := BaseManager.is_area_unlocked(area_id)
	var ready := BaseManager.can_unlock_area(area_id, GameState.campaign_stage)
	var status := _t("YETKİ KİLİTLİ", "CLEARANCE LOCKED")
	var color := COLOR_LOCKED
	button.disabled = true
	if unlocked:
		status = _t("ERİŞİM AÇIK", "ACCESS ONLINE")
		color = COLOR_ONLINE
	elif ready:
		status = _t("AKTİVASYONA HAZIR", "READY TO ACTIVATE")
		color = COLOR_READY
		button.disabled = false
	else:
		status = _t(
			"KİLİTLİ // VEX-%02d" % int(definition.get("required_stage", 0)),
			"LOCKED // VEX-%02d" % int(definition.get("required_stage", 0))
		)
	button.text = "%s\n%s" % [_localized(definition, "name"), status]
	_set_button_color(button, color)


func _refresh_static_area_button(button: Button, title: String) -> void:
	button.disabled = true
	button.text = "%s\n%s" % [title, _t("SİSTEM AKTİF", "SYSTEM ONLINE")]
	_set_button_color(button, COLOR_SYSTEM)


func _refresh_lighting_controls() -> void:
	_refresh_lighting_button(standard_lighting_button, BaseManager.LightingMode.STANDARD)
	_refresh_lighting_button(low_power_lighting_button, BaseManager.LightingMode.LOW_POWER)
	_refresh_lighting_button(emergency_lighting_button, BaseManager.LightingMode.EMERGENCY)


func _refresh_lighting_button(button: Button, mode: int) -> void:
	var definition := BaseManager.get_lighting_definition(mode)
	var active := BaseManager.get_lighting_mode() == mode
	button.text = "%s\n%s // %d%%" % [
		_localized(definition, "name"),
		_t("AKTİF", "ACTIVE") if active else _t("UYGULA", "APPLY"),
		roundi(float(definition.get("energy_multiplier", 1.0)) * 100.0),
	]
	button.disabled = active
	_set_button_color(button, _lighting_color(mode) if active else COLOR_SYSTEM)


func _refresh_upgrade_controls() -> void:
	_refresh_upgrade_button(power_upgrade_button, &"power_grid")
	_refresh_upgrade_button(security_upgrade_button, &"security_grid")
	_refresh_upgrade_button(research_upgrade_button, &"research_infrastructure")


func _refresh_upgrade_button(button: Button, upgrade_id: StringName) -> void:
	var definition := BaseManager.get_upgrade_definition(upgrade_id)
	button.disabled = true
	button.text = "%s\n%s %d / %d // %s" % [
		_localized(definition, "name"),
		_t("SV", "LVL"),
		BaseManager.get_upgrade_level(upgrade_id),
		int(definition.get("max_level", 0)),
		_t("YAKINDA", "FUTURE"),
	]
	_set_button_color(button, COLOR_MUTED)


func _activate_area(area_id: StringName) -> void:
	if not BaseManager.can_unlock_area(area_id, GameState.campaign_stage):
		return
	var previous_state := BaseManager.capture_state()
	if not BaseManager.unlock_area(area_id, GameState.campaign_stage):
		return
	if not GameState.save_current_safe_progress("base_dashboard_area"):
		BaseManager.restore_state(previous_state)
		GameState.notify(GameState.get_save_failure_message())
		return
	GameState.notify(_t("BASTION-7 // BÖLGE ERİŞİMİ YENİDEN ETKİN", "BASTION-7 // AREA ACCESS RESTORED"))
	_refresh_dashboard()


func _apply_lighting(mode: int) -> void:
	if BaseManager.get_lighting_mode() == mode:
		return
	var previous_state := BaseManager.capture_state()
	if not BaseManager.set_lighting_mode(mode):
		return
	if not GameState.save_current_safe_progress("base_dashboard_lighting"):
		BaseManager.restore_state(previous_state)
		GameState.notify(GameState.get_save_failure_message())
		return
	GameState.notify(_t("BASTION-7 // AYDINLATMA PROFİLİ GÜNCELLENDİ", "BASTION-7 // LIGHTING PROFILE UPDATED"))
	_refresh_dashboard()


func _on_base_state_changed() -> void:
	if visible:
		_refresh_dashboard()


func _on_language_changed(_locale: String) -> void:
	if visible:
		_refresh_dashboard()


func _set_button_color(button: Button, color: Color) -> void:
	for state_name in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		button.add_theme_color_override(state_name, color)


func _lighting_color(mode: int) -> Color:
	match mode:
		BaseManager.LightingMode.EMERGENCY:
			return Color(1.0, 0.35, 0.25, 1.0)
		BaseManager.LightingMode.LOW_POWER:
			return Color(0.55, 0.78, 1.0, 1.0)
		_:
			return COLOR_ONLINE


func _localized(entry: Dictionary, key: String) -> String:
	var suffix := "_tr" if TranslationServer.get_locale().begins_with("tr") else "_en"
	return str(entry.get(key + suffix, entry.get(key, "")))


func _t(turkish: String, english: String) -> String:
	return turkish if TranslationServer.get_locale().begins_with("tr") else english


func _refresh_editor_text() -> void:
	dashboard_title.text = "BASTION-7 // ÜS KONTROLÜ"
	dashboard_subtitle.text = "YEREL TESİS AĞI // KAPI YETKİSİ // AYDINLATMA // GELİŞTİRME OMURGASI"
	stage_badge.text = "KAMPANYA // AŞAMA 00"
	access_value.text = "BÖLGE ERİŞİMİ\n0 / 4"
	lighting_value.text = "AYDINLATMA\nSTANDART"
	lighting_load_value.text = "IŞIK YÜKÜ\n100%"
	upgrade_value.text = "GELİŞTİRME\n0 / 9"
	facility_map_title.text = "TESİS ŞEMASI // CANLI DURUM"
	lighting_title.text = "AYDINLATMA DAĞITIMI"
	upgrade_title.text = "GELİŞTİRME OMURGASI // GELECEK SİSTEM"
	status_hint.text = "YEŞİL: AKTİF  //  TURUNCU: AKTİVASYONA HAZIR  //  KIRMIZI: YETKİ KİLİTLİ"
	firing_range_button.text = "ATIŞ POLİGONU\nAKTİVASYONA HAZIR"
	research_button.text = "ARAŞTIRMA LABORATUVARI\nKİLİTLİ // VEX-01"
	workshop_button.text = "SİLAH ATÖLYESİ\nKİLİTLİ // VEX-02"
	engineering_button.text = "MÜHENDİSLİK BÖLMESİ\nKİLİTLİ // VEX-02"
	_refresh_static_area_button(armory_button, "SİLAH DEPOSU")
	_refresh_static_area_button(command_button, "KOMUTA MERKEZİ")
	_refresh_static_area_button(south_corridor_button, "GÜNEY KORİDORU")
	_refresh_static_area_button(operator_button, "OPERATÖR PLATFORMU")
	standard_lighting_button.text = "STANDART AYDINLATMA\nAKTİF // 100%"
	low_power_lighting_button.text = "DÜŞÜK GÜÇ MODU\nUYGULA // 48%"
	emergency_lighting_button.text = "ACİL DURUM MODU\nUYGULA // 28%"
	power_upgrade_button.text = "ENERJİ DAĞITIM AĞI\nSV 0 / 3 // YAKINDA"
	security_upgrade_button.text = "GÜVENLİK AĞI\nSV 0 / 3 // YAKINDA"
	research_upgrade_button.text = "ARAŞTIRMA ALTYAPISI\nSV 0 / 3 // YAKINDA"
	_set_button_color(firing_range_button, COLOR_READY)
	_set_button_color(research_button, COLOR_LOCKED)
	_set_button_color(workshop_button, COLOR_LOCKED)
	_set_button_color(engineering_button, COLOR_LOCKED)
	_set_button_color(standard_lighting_button, COLOR_ONLINE)
	_set_button_color(low_power_lighting_button, COLOR_SYSTEM)
	_set_button_color(emergency_lighting_button, COLOR_SYSTEM)
	_set_button_color(power_upgrade_button, COLOR_MUTED)
	_set_button_color(security_upgrade_button, COLOR_MUTED)
	_set_button_color(research_upgrade_button, COLOR_MUTED)
