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
	close_button.text = tr("TERMINAL_MENU_CLOSE")


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
	archive_summary.text = tr("WEAPON_UI_RECORDS_ACQUIRED_CARRIED") % [_all_definitions.size(), acquired, carried]


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
		empty_label.text = tr("WEAPON_UI_NO_ACTIVE_WEAPON_RECORDS_IN_THIS")
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
		detail_title.text = tr("WEAPON_UI_NO_ACTIVE_RECORD")
		detail_meta.text = tr(CATEGORY_LABEL_KEYS[int(_current_category)])
		detail_status.text = tr("WEAPON_UI_VEX_ARMORY_DATABASE")
		detail_body.text = tr("WEAPON_UI_NO_ACTIVE_WEAPONDEFINITION_CONNECTED_TO_THE")
		return
	var definition := _current_entries[_selected_index]
	detail_preview.texture = definition.world_pickup_texture
	detail_title.text = tr(definition.display_name)
	detail_meta.text = "%s  //  %s %d" % [
		tr(definition.loadout_group_label),
		tr("WEAPON_UI_LOADOUT_SLOT"),
		definition.loadout_slot,
	]
	detail_status.text = _weapon_status_text(definition)
	detail_body.text = _build_weapon_detail(definition)


func _weapon_status_text(definition: WeaponDefinition) -> String:
	if _weapon_controller == null:
		return tr("WEAPON_UI_DATA_LINK_OFFLINE")
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
	lines.append("[color=#78cbd8]%s[/color]" % tr("WEAPON_UI_FIREPOWER"))
	lines.append(tr("WEAPON_UI_DAMAGE_PELLET_1F_PELLETS_SHOT_TOTAL") % [damage_per_pellet, pellet_count, trigger_damage, headshot, theoretical_dps, magazine_damage])

	lines.append("[color=#78cbd8]%s[/color]" % tr("WEAPON_UI_FIRE_CYCLE_AMMUNITION"))
	lines.append(tr("WEAPON_UI_FIRE_MODE_FIRE_RATE_0F_RPM") % [_fire_mode_text(definition), rpm, fire_interval, magazine, definition.reserve_ammo_capacity, reload_duration, _ammo_text(definition.ammo_type)])

	lines.append("[color=#78cbd8]%s[/color]" % tr("WEAPON_UI_ACCURACY_RANGE"))
	var range_text := tr("WEAPON_UI_MAXIMUM_RANGE_0F_M_HIP_SPREAD") % [definition.maximum_range, spread]
	if definition.supports_ads_pose:
		range_text += tr("WEAPON_UI_ADS_SPREAD_2F_ADS_FOV_RATIO") % [spread * definition.ads_spread_multiplier, definition.ads_fov_multiplier]
	else:
		range_text += tr("WEAPON_UI_ADS_NOT_SUPPORTED")
	if definition.damage_falloff_end_distance > definition.damage_falloff_start_distance:
		range_text += tr("WEAPON_UI_DAMAGE_FALLOFF_0F_0F_M_MINIMUM") % [definition.damage_falloff_start_distance, definition.damage_falloff_end_distance, definition.damage_falloff_min_multiplier]
	lines.append(range_text)

	lines.append("[color=#78cbd8]%s[/color]" % tr("WEAPON_UI_RECOIL_SIGNATURE"))
	lines.append(tr("WEAPON_UI_VERTICAL_RECOIL_2F_HORIZONTAL_RECOIL_2F") % [vertical_recoil, horizontal_recoil, definition.recoil_max_vertical_degrees, definition.recoil_max_horizontal_degrees, definition.recoil_recovery_degrees_per_second * float(modifiers.get("recoil_recovery", 1.0)), noise, penetration])

	var systems := PackedStringArray()
	if definition.supports_flashlight:
		systems.append(tr("WEAPON_UI_TACTICAL_LIGHT"))
	if definition.supports_alt_fire:
		systems.append(tr("WEAPON_UI_ALT_FIRE"))
	if definition.uses_charge:
		systems.append(tr("WEAPON_UI_CHARGED_FIRE"))
	if definition.uses_heat:
		systems.append(tr("WEAPON_UI_HEAT_SYSTEM"))
	if systems.is_empty():
		systems.append(tr("WEAPON_UI_NO_AUXILIARY_SYSTEM"))
	lines.append("[color=#78cbd8]%s[/color]" % tr("WEAPON_UI_SPECIAL_SYSTEMS"))
	lines.append(" // ".join(systems))
	if definition.supports_flashlight:
		lines.append(tr("WEAPON_UI_LIGHT_1F_M_1F_ENERGY_0F") % [definition.flashlight_range * float(modifiers.get("flashlight_range", 1.0)), definition.flashlight_energy * float(modifiers.get("flashlight_energy", 1.0)), definition.flashlight_angle_degrees])
	if definition.uses_heat:
		lines.append(tr("WEAPON_UI_HEAT_1F_SHOT_CAPACITY_1F_COOLING") % [definition.heat_per_shot, definition.heat_capacity * float(modifiers.get("heat_capacity", 1.0)), definition.heat_cooling_per_second * float(modifiers.get("heat_cooling", 1.0)), definition.heat_unlock_ratio * 100.0])

	lines.append("[color=#78cbd8]%s[/color]" % tr("ARCHIVE_UI_UPGRADE_TRACK"))
	lines.append(_upgrade_track_text(definition.weapon_id, level))
	return "\n\n".join(lines)


func _upgrade_track_text(weapon_id: StringName, level: int) -> String:
	var track := VexWeaponUpgradeCatalog.get_track(weapon_id)
	if track.is_empty():
		return tr("WEAPON_UI_NO_REGISTERED_UPGRADE_TRACK")
	var lines := PackedStringArray()
	lines.append(tr("WEAPON_UI_CURRENT_LEVEL") % [level, track.size()])
	for index in track.size():
		var tier: Dictionary = track[index]
		var marker := "[color=#4cff9a]✓[/color]" if index < level else "○"
		lines.append("%s  T%d // %s" % [marker, index + 1, tr(str(tier.get("name", "UPGRADE_GENERIC")))])
	return "\n".join(lines)


func _fire_mode_text(definition: WeaponDefinition) -> String:
	return tr("WEAPON_UI_AUTOMATIC") if definition.automatic else tr("WEAPON_UI_SEMI_AUTOMATIC")


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

