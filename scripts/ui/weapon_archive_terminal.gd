@tool
class_name VexWeaponArchiveTerminal
extends CanvasLayer


enum Category {
	SIDEARM,
	SHOTGUN,
	RIFLE,
	SMG,
	LASER,
}

const CATEGORY_GROUPS: Array[StringName] = [
	&"sidearm",
	&"shotgun",
	&"rifle",
	&"smg",
	&"laser",
]
const CATEGORY_LABEL_KEYS := [
	"ARMORY_GROUP_SIDEARM",
	"ARMORY_GROUP_SHOTGUN",
	"ARMORY_GROUP_RIFLE",
	"ARMORY_GROUP_SMG",
	"ARMORY_GROUP_LASER",
]

@onready var terminal_root: Control = %WeaponArchiveRoot
@onready var sidearm_tab: Button = %SidearmTab
@onready var shotgun_tab: Button = %ShotgunTab
@onready var rifle_tab: Button = %RifleTab
@onready var smg_tab: Button = %SmgTab
@onready var laser_tab: Button = %LaserTab
@onready var section_title: Label = %SectionTitle
@onready var weapon_list: VBoxContainer = %WeaponList
@onready var detail_preview: TextureRect = %DetailPreview
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_status: Label = %DetailStatus
@onready var detail_body: RichTextLabel = %DetailBody
@onready var archive_summary: Label = %ArchiveSummary
@onready var close_button: Button = %CloseButton

var _current_category := Category.SIDEARM
var _selected_index := 0
var _current_entries: Array[WeaponDefinition] = []
var _all_definitions: Array[WeaponDefinition] = []
var _weapon_controller: VexWeaponController
var _was_paused := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.is_editor_hint():
		terminal_root.visible = get_tree().edited_scene_root == self
		return
	sidearm_tab.pressed.connect(_select_category.bind(Category.SIDEARM))
	shotgun_tab.pressed.connect(_select_category.bind(Category.SHOTGUN))
	rifle_tab.pressed.connect(_select_category.bind(Category.RIFLE))
	smg_tab.pressed.connect(_select_category.bind(Category.SMG))
	laser_tab.pressed.connect(_select_category.bind(Category.LASER))
	close_button.pressed.connect(close_terminal)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	terminal_root.visible = false


func open_terminal() -> void:
	_was_paused = get_tree().paused
	_weapon_controller = _get_weapon_controller()
	_refresh_definitions()
	terminal_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_all()
	sidearm_tab.grab_focus()


func close_terminal() -> void:
	if not terminal_root.visible:
		return
	terminal_root.visible = false
	get_tree().paused = _was_paused
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if _was_paused else Input.MOUSE_MODE_CAPTURED


func is_open() -> bool:
	return terminal_root.visible


func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not terminal_root.visible:
		return
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close_terminal()


func _get_weapon_controller() -> VexWeaponController:
	if GameState.player == null or not is_instance_valid(GameState.player):
		return null
	return GameState.player.get_node_or_null("WeaponController") as VexWeaponController


func _refresh_definitions() -> void:
	_all_definitions.clear()
	if _weapon_controller == null:
		return
	for definition: WeaponDefinition in _weapon_controller.weapon_definitions:
		if definition != null:
			_all_definitions.append(definition)


func _select_category(category: int) -> void:
	_current_category = category as Category
	_selected_index = 0
	_refresh_all()


func _refresh_all() -> void:
	if not terminal_root.visible:
		return
	_refresh_tabs()
	_refresh_summary()
	_refresh_entries()
	_refresh_detail()
	close_button.text = _t("TERMİNALİ KAPAT", "CLOSE TERMINAL")


func _refresh_tabs() -> void:
	var tabs: Array[Button] = [sidearm_tab, shotgun_tab, rifle_tab, smg_tab, laser_tab]
	for index in tabs.size():
		tabs[index].text = tr(CATEGORY_LABEL_KEYS[index])
		tabs[index].button_pressed = index == _current_category


func _refresh_summary() -> void:
	var acquired := 0
	var carried := 0
	if _weapon_controller != null:
		for definition: WeaponDefinition in _all_definitions:
			if _weapon_controller.owns_weapon(definition.weapon_id):
				acquired += 1
			if _weapon_controller.is_weapon_carried(definition.weapon_id):
				carried += 1
	archive_summary.text = _t(
		"KAYIT %d  //  EDİNİLEN %d  //  KUŞANILAN %d" % [_all_definitions.size(), acquired, carried],
		"RECORDS %d  //  ACQUIRED %d  //  CARRIED %d" % [_all_definitions.size(), acquired, carried]
	)


func _refresh_entries() -> void:
	for child: Node in weapon_list.get_children():
		child.queue_free()
	_current_entries.clear()
	var group_id := CATEGORY_GROUPS[int(_current_category)]
	for definition: WeaponDefinition in _all_definitions:
		if definition.loadout_group == group_id:
			_current_entries.append(definition)
	section_title.text = tr(CATEGORY_LABEL_KEYS[int(_current_category)])
	if _current_entries.is_empty():
		_selected_index = -1
		var empty_label := Label.new()
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_label.add_theme_font_size_override("font_size", 13)
		empty_label.text = _t(
			"BU KATEGORİDE AKTİF SİLAH KAYDI YOK",
			"NO ACTIVE WEAPON RECORDS IN THIS CATEGORY"
		)
		weapon_list.add_child(empty_label)
		return
	_selected_index = clampi(_selected_index, 0, _current_entries.size() - 1)
	for index in _current_entries.size():
		var definition := _current_entries[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 64.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 13)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = index == _selected_index
		button.text = "%s\n// %s" % [tr(definition.display_name), _weapon_status_text(definition)]
		button.pressed.connect(_select_weapon.bind(index))
		weapon_list.add_child(button)


func _select_weapon(index: int) -> void:
	if index < 0 or index >= _current_entries.size():
		return
	_selected_index = index
	var children := weapon_list.get_children()
	for child_index in children.size():
		var button := children[child_index] as Button
		if button != null:
			button.button_pressed = child_index == _selected_index
	_refresh_detail()


func _refresh_detail() -> void:
	if _selected_index < 0 or _selected_index >= _current_entries.size():
		detail_preview.texture = null
		detail_title.text = _t("AKTİF KAYIT YOK", "NO ACTIVE RECORD")
		detail_meta.text = tr(CATEGORY_LABEL_KEYS[int(_current_category)])
		detail_status.text = _t("VEX CEPHANELİK VERİTABANI", "VEX ARMORY DATABASE")
		detail_body.text = _t(
			"Bu kategori için oyuncu silah sistemine bağlı aktif bir WeaponDefinition bulunmuyor.",
			"No active WeaponDefinition connected to the player weapon system exists for this category."
		)
		return
	var definition := _current_entries[_selected_index]
	detail_preview.texture = definition.world_pickup_texture
	detail_title.text = tr(definition.display_name)
	detail_meta.text = "%s  //  %s %d" % [
		tr(definition.loadout_group_label),
		_t("YÜK YUVASI", "LOADOUT SLOT"),
		definition.loadout_slot,
	]
	detail_status.text = _weapon_status_text(definition)
	detail_body.text = _build_weapon_detail(definition)


func _weapon_status_text(definition: WeaponDefinition) -> String:
	if _weapon_controller == null:
		return _t("VERİ BAĞLANTISI YOK", "DATA LINK OFFLINE")
	if _weapon_controller.is_weapon_carried(definition.weapon_id):
		return tr("UI_CARRIED")
	if _weapon_controller.owns_weapon(definition.weapon_id):
		return tr("UI_STORED")
	return tr("UI_LOCKED")


func _build_weapon_detail(definition: WeaponDefinition) -> String:
	var level := 0
	if _weapon_controller != null:
		level = _weapon_controller.get_weapon_upgrade_level(definition.weapon_id)
	var modifiers := VexWeaponUpgradeCatalog.get_modifiers(definition.weapon_id, level)
	var damage_per_pellet := float(definition.damage_per_pellet) * float(modifiers.get("damage", 1.0))
	var pellet_count := definition.pellet_count
	var trigger_damage := damage_per_pellet * float(pellet_count)
	var fire_interval := maxf(0.001, definition.fire_interval * float(modifiers.get("fire_rate", 1.0)))
	var rpm := 60.0 / fire_interval
	var magazine := definition.magazine_size + int(modifiers.get("magazine", 0))
	var reload_duration := definition.reload_duration * float(modifiers.get("reload", 1.0))
	var spread := definition.spread_degrees * float(modifiers.get("spread", 1.0))
	var vertical_recoil := definition.recoil_vertical_degrees * float(modifiers.get("recoil", 1.0))
	var horizontal_recoil := definition.recoil_horizontal_degrees * float(modifiers.get("recoil", 1.0))
	var headshot := definition.headshot_multiplier * float(modifiers.get("headshot", 1.0))
	var penetration := definition.penetration_power + float(modifiers.get("penetration", 0.0))
	var noise := definition.gunshot_noise_multiplier * float(modifiers.get("gunshot_noise", 1.0))
	var theoretical_dps := trigger_damage / fire_interval
	var magazine_damage := trigger_damage * float(magazine)

	var lines := PackedStringArray()
	lines.append("[color=#78cbd8]%s[/color]" % _t("ATEŞ GÜCÜ", "FIREPOWER"))
	lines.append(_t(
		"Hasar / pellet: %.1f\nPellet / atış: %d\nToplam tetik hasarı: %.1f\nKafa çarpanı: ×%.2f\nTeorik DPS: %.1f\nŞarjör teorik hasarı: %.1f" % [damage_per_pellet, pellet_count, trigger_damage, headshot, theoretical_dps, magazine_damage],
		"Damage / pellet: %.1f\nPellets / shot: %d\nTotal trigger damage: %.1f\nHeadshot multiplier: ×%.2f\nTheoretical DPS: %.1f\nTheoretical magazine damage: %.1f" % [damage_per_pellet, pellet_count, trigger_damage, headshot, theoretical_dps, magazine_damage]
	))

	lines.append("[color=#78cbd8]%s[/color]" % _t("ATIŞ DÖNGÜSÜ VE MÜHİMMAT", "FIRE CYCLE & AMMUNITION"))
	lines.append(_t(
		"Atış modu: %s\nAtış hızı: %.0f RPM\nAtış aralığı: %.3f sn\nŞarjör: %d\nYedek kapasite: %d\nDoldurma: %.2f sn\nMühimmat: %s" % [_fire_mode_text(definition), rpm, fire_interval, magazine, definition.reserve_ammo_capacity, reload_duration, _ammo_text(definition.ammo_type)],
		"Fire mode: %s\nFire rate: %.0f RPM\nShot interval: %.3f s\nMagazine: %d\nReserve capacity: %d\nReload: %.2f s\nAmmunition: %s" % [_fire_mode_text(definition), rpm, fire_interval, magazine, definition.reserve_ammo_capacity, reload_duration, _ammo_text(definition.ammo_type)]
	))

	lines.append("[color=#78cbd8]%s[/color]" % _t("İSABET VE MENZİL", "ACCURACY & RANGE"))
	var range_text := _t(
		"Maksimum menzil: %.0f m\nKalça yayılımı: %.2f°" % [definition.maximum_range, spread],
		"Maximum range: %.0f m\nHip spread: %.2f°" % [definition.maximum_range, spread]
	)
	if definition.supports_ads_pose:
		range_text += _t(
			"\nADS yayılımı: %.2f°\nADS FOV oranı: %.2f" % [spread * definition.ads_spread_multiplier, definition.ads_fov_multiplier],
			"\nADS spread: %.2f°\nADS FOV ratio: %.2f" % [spread * definition.ads_spread_multiplier, definition.ads_fov_multiplier]
		)
	else:
		range_text += _t("\nADS: DESTEKLENMİYOR", "\nADS: NOT SUPPORTED")
	if definition.damage_falloff_end_distance > definition.damage_falloff_start_distance:
		range_text += _t(
			"\nHasar düşüşü: %.0f–%.0f m // minimum ×%.2f" % [definition.damage_falloff_start_distance, definition.damage_falloff_end_distance, definition.damage_falloff_min_multiplier],
			"\nDamage falloff: %.0f–%.0f m // minimum ×%.2f" % [definition.damage_falloff_start_distance, definition.damage_falloff_end_distance, definition.damage_falloff_min_multiplier]
		)
	lines.append(range_text)

	lines.append("[color=#78cbd8]%s[/color]" % _t("SEKME VE İMZA", "RECOIL & SIGNATURE"))
	lines.append(_t(
		"Dikey sekme: %.2f°\nYatay sekme: %.2f°\nMaks. dikey birikim: %.2f°\nMaks. yatay birikim: %.2f°\nSekme toparlama: %.1f°/sn\nSilah sesi çarpanı: ×%.2f\nPenetrasyon gücü: %.2f" % [vertical_recoil, horizontal_recoil, definition.recoil_max_vertical_degrees, definition.recoil_max_horizontal_degrees, definition.recoil_recovery_degrees_per_second * float(modifiers.get("recoil_recovery", 1.0)), noise, penetration],
		"Vertical recoil: %.2f°\nHorizontal recoil: %.2f°\nMax vertical buildup: %.2f°\nMax horizontal buildup: %.2f°\nRecoil recovery: %.1f°/s\nGunshot noise multiplier: ×%.2f\nPenetration power: %.2f" % [vertical_recoil, horizontal_recoil, definition.recoil_max_vertical_degrees, definition.recoil_max_horizontal_degrees, definition.recoil_recovery_degrees_per_second * float(modifiers.get("recoil_recovery", 1.0)), noise, penetration]
	))

	var systems := PackedStringArray()
	if definition.supports_flashlight:
		systems.append(_t("TAKTİK FENER", "TACTICAL LIGHT"))
	if definition.supports_alt_fire:
		systems.append(_t("ALTERNATİF ATIŞ", "ALT FIRE"))
	if definition.uses_charge:
		systems.append(_t("ŞARJLI ATIŞ", "CHARGED FIRE"))
	if definition.uses_heat:
		systems.append(_t("ISI SİSTEMİ", "HEAT SYSTEM"))
	if systems.is_empty():
		systems.append(_t("EK SİSTEM YOK", "NO AUXILIARY SYSTEM"))
	lines.append("[color=#78cbd8]%s[/color]" % _t("ÖZEL SİSTEMLER", "SPECIAL SYSTEMS"))
	lines.append(" // ".join(systems))
	if definition.supports_flashlight:
		lines.append(_t(
			"Fener: %.1f m // %.1f enerji // %.0f°" % [definition.flashlight_range * float(modifiers.get("flashlight_range", 1.0)), definition.flashlight_energy * float(modifiers.get("flashlight_energy", 1.0)), definition.flashlight_angle_degrees],
			"Light: %.1f m // %.1f energy // %.0f°" % [definition.flashlight_range * float(modifiers.get("flashlight_range", 1.0)), definition.flashlight_energy * float(modifiers.get("flashlight_energy", 1.0)), definition.flashlight_angle_degrees]
		))
	if definition.uses_heat:
		lines.append(_t(
			"Isı: %.1f/atış // kapasite %.1f // soğutma %.1f/sn // kilit açma %.0f%%" % [definition.heat_per_shot, definition.heat_capacity * float(modifiers.get("heat_capacity", 1.0)), definition.heat_cooling_per_second * float(modifiers.get("heat_cooling", 1.0)), definition.heat_unlock_ratio * 100.0],
			"Heat: %.1f/shot // capacity %.1f // cooling %.1f/s // unlock %.0f%%" % [definition.heat_per_shot, definition.heat_capacity * float(modifiers.get("heat_capacity", 1.0)), definition.heat_cooling_per_second * float(modifiers.get("heat_cooling", 1.0)), definition.heat_unlock_ratio * 100.0]
		))

	lines.append("[color=#78cbd8]%s[/color]" % _t("GELİŞTİRME HATTI", "UPGRADE TRACK"))
	lines.append(_upgrade_track_text(definition.weapon_id, level))
	return "\n\n".join(lines)


func _upgrade_track_text(weapon_id: StringName, level: int) -> String:
	var track := VexWeaponUpgradeCatalog.get_track(weapon_id)
	if track.is_empty():
		return _t("Kayıtlı geliştirme hattı yok.", "No registered upgrade track.")
	var lines := PackedStringArray()
	lines.append(_t("Mevcut seviye: %d / %d" % [level, track.size()], "Current level: %d / %d" % [level, track.size()]))
	for index in track.size():
		var tier: Dictionary = track[index]
		var marker := "[color=#4cff9a]✓[/color]" if index < level else "○"
		lines.append("%s  T%d // %s" % [marker, index + 1, tr(str(tier.get("name", "UPGRADE_GENERIC")))])
	return "\n".join(lines)


func _fire_mode_text(definition: WeaponDefinition) -> String:
	return _t("OTOMATİK", "AUTOMATIC") if definition.automatic else _t("YARI OTOMATİK", "SEMI-AUTOMATIC")


func _ammo_text(ammo_type: StringName) -> String:
	match ammo_type:
		&"bullets":
			return tr("AMMO_9X19")
		&"shells":
			return tr("AMMO_12GA")
		&"rifle_ammo":
			return tr("AMMO_762")
		&"mp90_ammo":
			return tr("AMMO_57")
		_:
			return str(ammo_type).to_upper()


func _on_language_changed(_locale: String) -> void:
	_refresh_all()


func _t(turkish: String, english: String) -> String:
	return turkish if TranslationServer.get_locale().begins_with("tr") else english
