@tool
class_name VexArchiveTerminal
extends CanvasLayer

const ArchiveDB = preload("res://scripts/data/vex_archive_database.gd")
const VEX_LOGO = preload("res://assets/ui/vex_logo.png")

# Vaskari Ravager predates the canonical character-sheet manifest format.
# Keep its authored idle frame explicit instead of displaying the whole legacy sheet.
const LEGACY_PREVIEW_REGIONS := {
	&"vaskari_ravager": Rect2(682.0, 512.0, 341.0, 512.0),
}

enum Section {
	CREATURES,
	UNIVERSES,
	RECORDS,
	THREAT_ANALYSIS,
	RIFT_NETWORK,
	PROTOCOLS,
	BASE_MANAGEMENT,
}

@onready var terminal_root: Control = %ArchiveRoot
@onready var creatures_tab: Button = %CreaturesTab
@onready var universes_tab: Button = %UniversesTab
@onready var records_tab: Button = %RecordsTab
@onready var threat_tab: Button = %ThreatTab
@onready var rift_tab: Button = %RiftTab
@onready var protocols_tab: Button = %ProtocolsTab
@onready var base_management_tab: Button = %BaseManagementTab
@onready var entry_list: VBoxContainer = %EntryList
@onready var section_title: Label = %SectionTitle
@onready var archive_summary: Label = %ArchiveSummary
@onready var detail_preview: TextureRect = %DetailPreview
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_body: RichTextLabel = %DetailBody
@onready var classification_label: Label = %ClassificationLabel
@onready var base_action_row: HBoxContainer = %BaseActionRow
@onready var base_action_hint: Label = %BaseActionHint
@onready var base_action_button: Button = %BaseActionButton
@onready var close_button: Button = %CloseButton

var _current_section := Section.CREATURES
var _current_entries: Array[Dictionary] = []
var _selected_index := 0
var _was_paused := false
var _preview_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if Engine.is_editor_hint():
		terminal_root.visible = get_tree().edited_scene_root == self
		return
	creatures_tab.pressed.connect(_select_section.bind(Section.CREATURES))
	universes_tab.pressed.connect(_select_section.bind(Section.UNIVERSES))
	records_tab.pressed.connect(_select_section.bind(Section.RECORDS))
	threat_tab.pressed.connect(_select_section.bind(Section.THREAT_ANALYSIS))
	rift_tab.pressed.connect(_select_section.bind(Section.RIFT_NETWORK))
	protocols_tab.pressed.connect(_select_section.bind(Section.PROTOCOLS))
	base_management_tab.pressed.connect(_select_section.bind(Section.BASE_MANAGEMENT))
	base_action_button.pressed.connect(_activate_base_management_entry)
	close_button.pressed.connect(close_terminal)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	if not ArchiveManager.archive_changed.is_connected(_on_archive_changed):
		ArchiveManager.archive_changed.connect(_on_archive_changed)
	if not BaseManager.base_state_changed.is_connected(_on_base_state_changed):
		BaseManager.base_state_changed.connect(_on_base_state_changed)
	base_action_row.visible = false
	terminal_root.visible = false


func open_terminal() -> void:
	_was_paused = get_tree().paused
	terminal_root.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_refresh_all()
	creatures_tab.grab_focus()


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


func _select_section(section: int) -> void:
	_current_section = section as Section
	_selected_index = 0
	_refresh_all()


func _refresh_all() -> void:
	if not terminal_root.visible:
		return
	_refresh_header()
	_refresh_tabs()
	_refresh_entries()
	_refresh_detail()
	close_button.text = tr("TERMINAL_MENU_CLOSE")


func _refresh_header() -> void:
	var discovered := _get_discovered_database_count()
	var known_universes := _get_known_universe_count()
	archive_summary.text = tr("ARCHIVE_UI_XENOARCHIVE_REALITIES_NETWORK_STAGE_02D") % [
			discovered,
			ArchiveDB.ENEMIES.size(),
			known_universes,
			ArchiveDB.UNIVERSES.size(),
			GameState.campaign_stage,
		]


func _refresh_tabs() -> void:
	creatures_tab.text = tr("ARCHIVE_UI_CREATURES")
	universes_tab.text = tr("ARCHIVE_UI_REALITIES")
	records_tab.text = tr("ARCHIVE_UI_RECORDS")
	threat_tab.text = tr("ARCHIVE_UI_THREAT_ANALYSIS")
	rift_tab.text = tr("ARCHIVE_UI_RIFT_NETWORK")
	protocols_tab.text = tr("ARCHIVE_UI_PROTOCOLS")
	base_management_tab.text = tr("ARCHIVE_UI_BASE_MANAGEMENT")
	var tabs: Array[Button] = [
		creatures_tab,
		universes_tab,
		records_tab,
		threat_tab,
		rift_tab,
		protocols_tab,
		base_management_tab,
	]
	for index in tabs.size():
		tabs[index].button_pressed = index == _current_section


func _refresh_entries() -> void:
	for child: Node in entry_list.get_children():
		child.queue_free()
	_current_entries = _get_entries_for_section()
	section_title.text = _get_section_title()
	if _current_entries.is_empty():
		_selected_index = -1
		return
	_selected_index = clampi(_selected_index, 0, _current_entries.size() - 1)
	for index in _current_entries.size():
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 13)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.button_pressed = index == _selected_index
		button.text = _get_entry_button_text(_current_entries[index], index)
		button.pressed.connect(_select_entry.bind(index))
		entry_list.add_child(button)


func _select_entry(index: int) -> void:
	if index < 0 or index >= _current_entries.size():
		return
	_selected_index = index
	var children := entry_list.get_children()
	for child_index in children.size():
		var button := children[child_index] as Button
		if button != null:
			button.button_pressed = child_index == _selected_index
	_refresh_detail()


func _get_entries_for_section() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	match _current_section:
		Section.CREATURES:
			for entry: Dictionary in ArchiveDB.ENEMIES:
				result.append(entry)
		Section.UNIVERSES, Section.THREAT_ANALYSIS:
			for entry: Dictionary in ArchiveDB.UNIVERSES:
				result.append(entry)
		Section.RECORDS:
			for entry: Dictionary in ArchiveDB.LOGS:
				result.append(entry)
		Section.RIFT_NETWORK:
			result = _build_rift_network_entries()
		Section.PROTOCOLS:
			for entry: Dictionary in ArchiveDB.PROTOCOLS:
				# Aileye özgü doktrinler o aile sahada tanınmadan listelenmez.
				if GameState.campaign_stage >= int(entry.get("unlock_stage", 0)):
					result.append(entry)
		Section.BASE_MANAGEMENT:
			result = _build_base_management_entries()
	return result


func _get_section_title() -> String:
	match _current_section:
		Section.CREATURES:
			return tr("ARCHIVE_UI_XENO_ENTITY_INDEX")
		Section.UNIVERSES:
			return tr("ARCHIVE_UI_REALITY_RECORDS")
		Section.RECORDS:
			return tr("ARCHIVE_UI_OPERATION_RECORDS")
		Section.THREAT_ANALYSIS:
			return tr("ARCHIVE_UI_TACTICAL_THREAT_MATRIX")
		Section.RIFT_NETWORK:
			return tr("ARCHIVE_UI_RIFT_NETWORK_TELEMETRY")
		Section.PROTOCOLS:
			return tr("ARCHIVE_UI_VEX_FIELD_PROTOCOLS")
		Section.BASE_MANAGEMENT:
			return tr("ARCHIVE_UI_BASTION_7_BASE_MANAGEMENT")
		_:
			return tr("ARCHIVE_UI_SYSTEM_DATA")


func _get_entry_button_text(entry: Dictionary, index: int) -> String:
	match _current_section:
		Section.CREATURES:
			if not _is_enemy_discovered(entry):
				return "XENO-%02d\n// ???" % (index + 1)
			return "%s\n// %s" % [
				entry.get("name", "UNKNOWN"),
				_get_universe_name(_entry_string_name(entry, "universe")),
			]
		Section.UNIVERSES, Section.THREAT_ANALYSIS:
			if _is_universe_known(entry):
				return ArchiveDB.universe_name(entry)
			return tr("ARCHIVE_UI_REALITY_02D_UNCLASSIFIED") % (index + 1)
		Section.RECORDS:
			if _is_log_unlocked(entry):
				return ArchiveDB.entry_title(entry, "RECORD")
			return tr("ARCHIVE_UI_ENCRYPTED_RECORD_02D") % (index + 1)
		Section.BASE_MANAGEMENT:
			return _get_base_management_button_text(entry)
		_:
			return ArchiveDB.entry_title(entry, "DATA")


func _refresh_detail() -> void:
	if _selected_index < 0 or _selected_index >= _current_entries.size():
		_set_detail(
			tr("ARCHIVE_UI_NO_DATA"),
			"",
			tr("ARCHIVE_UI_NO_RECORDS_ARE_AVAILABLE_IN_THIS"),
			null,
			true
		)
		return
	var entry := _current_entries[_selected_index]
	match _current_section:
		Section.CREATURES:
			_show_enemy(entry)
		Section.UNIVERSES:
			_show_universe(entry)
		Section.RECORDS:
			_show_log(entry)
		Section.THREAT_ANALYSIS:
			_show_threat_analysis(entry)
		Section.RIFT_NETWORK:
			_show_rift_entry(entry)
		Section.PROTOCOLS:
			_show_protocol(entry)
		Section.BASE_MANAGEMENT:
			_show_base_management_entry(entry)


func _show_enemy(entry: Dictionary) -> void:
	if not _is_enemy_discovered(entry):
		_set_detail(
			tr("ARCHIVE_UI_UNCLASSIFIED_XENO_ENTITY"),
			tr("ARCHIVE_UI_FIELD_CONTACT_REQUIRED"),
			tr("ARCHIVE_UI_THIS_RECORD_HAS_NOT_BEEN_VERIFIED"),
			VEX_LOGO,
			true
		)
		return

	var universe_id := _entry_string_name(entry, "universe")
	var universe := ArchiveDB.get_universe(universe_id)
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_OBSERVED_BEHAVIOR"),
		ArchiveDB.localized(entry, "behavior"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_TACTICAL_RESPONSE"),
		ArchiveDB.localized(entry, "tactic"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_ECOLOGICAL_SOCIAL_ROLE"),
		ArchiveDB.enemy_lore(entry, GameState.campaign_stage),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_ORIGIN_REALITY"),
		ArchiveDB.universe_story_text(universe, "extraction", GameState.campaign_stage),
	]
	_set_detail(
		str(entry.get("name", "UNKNOWN")),
		tr("ARCHIVE_UI_ORIGIN_ROLE_THREAT") % [
				_get_universe_name(universe_id),
				ArchiveDB.localized(entry, "role"),
				entry.get("threat", "?"),
			],
		body,
		_get_enemy_preview(entry),
		false
	)


func _show_universe(entry: Dictionary) -> void:
	if not _is_universe_known(entry):
		_set_detail(
			tr("ARCHIVE_UI_UNCLASSIFIED_REALITY"),
			tr("ARCHIVE_UI_XENO_LINK_UNVERIFIED"),
			tr("ARCHIVE_UI_NO_VERIFIED_FIELD_SPECIMEN_FROM_THIS"),
			VEX_LOGO,
			true
		)
		return

	var ids := ArchiveDB.get_enemy_ids_for_universe(_entry_string_name(entry, "id"))
	var discovered_names := PackedStringArray()
	for enemy_id: StringName in ids:
		var enemy := ArchiveDB.get_enemy(enemy_id)
		if not enemy.is_empty() and _is_enemy_discovered(enemy):
			discovered_names.append(str(enemy.get("name", enemy_id)))
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_REALITY_IDENTITY"),
		ArchiveDB.universe_story_text(entry, "identity", GameState.campaign_stage)
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_VEX_EXTRACTION"),
		ArchiveDB.universe_story_text(entry, "extraction", GameState.campaign_stage)
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_FIELD_PRESSURE_PROFILE"), ArchiveDB.localized(entry, "pressure")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_VISUAL_SIGNATURE"), ArchiveDB.localized(entry, "palette")
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_VERIFIED_SPECIES"),
		", ".join(discovered_names) if not discovered_names.is_empty() else "—",
	]
	_set_detail(
		ArchiveDB.universe_name(entry),
		tr("ARCHIVE_UI_VERIFIED_SPECIES_2") % [discovered_names.size(), ids.size()],
		body,
		VEX_LOGO,
		false
	)


func _show_log(entry: Dictionary) -> void:
	if not _is_log_unlocked(entry):
		_set_detail(
			tr("ARCHIVE_UI_ENCRYPTED_OPERATION_RECORD"),
			tr("ARCHIVE_UI_INSUFFICIENT_CLEARANCE_OPERATION_MUST_BE_COMPLETED"),
			tr("ARCHIVE_UI_THIS_RECORD_CANNOT_BE_OPENED_WITH"),
			VEX_LOGO,
			true
		)
		return
	_set_detail(
		ArchiveDB.entry_title(entry, "RECORD"),
		tr("ARCHIVE_UI_VEX_SECURE_RECORD_VERIFIED"),
		_localized_body(entry),
		VEX_LOGO,
		false
	)


func _show_threat_analysis(entry: Dictionary) -> void:
	if not _is_universe_known(entry):
		_set_detail(
			tr("ARCHIVE_UI_THREAT_MATRIX_INSUFFICIENT_DATA"),
			tr("ARCHIVE_UI_VERIFIED_SPECIES_REQUIRED"),
			tr("ARCHIVE_UI_AT_LEAST_ONE_VERIFIED_FIELD_CONTACT"),
			VEX_LOGO,
			true
		)
		return
	var universe_id := _entry_string_name(entry, "id")
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_PRIMARY_PRESSURE"), ArchiveDB.localized(entry, "pressure")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_VEX_TACTICAL_RECOMMENDATION"),
		_get_universe_recommendation(universe_id),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_IDENTIFICATION_SIGNATURE"), ArchiveDB.localized(entry, "palette")
	]
	_set_detail(
		tr("ARCHIVE_UI_THREAT_MODEL") % ArchiveDB.universe_name(entry),
		tr("ARCHIVE_UI_FAMILY_LEVEL_COUNTERPLAY"),
		body,
		VEX_LOGO,
		false
	)


func _show_rift_entry(entry: Dictionary) -> void:
	_set_detail(
		str(entry.get("title", "RIFT NETWORK")),
		str(entry.get("meta", "VEX NETWORK")),
		str(entry.get("body", "")),
		VEX_LOGO,
		false
	)


func _show_protocol(entry: Dictionary) -> void:
	_set_detail(
		ArchiveDB.entry_title(entry, "PROTOCOL"),
		tr("ARCHIVE_UI_VEX_FIELD_DOCTRINE_ACTIVE"),
		_localized_body(entry),
		VEX_LOGO,
		false
	)


func _build_base_management_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		{
			"base_kind": &"overview",
			"title": tr("ARCHIVE_UI_BASE_STATUS"),
		},
	]
	for definition: Dictionary in BaseManager.get_area_definitions():
		var entry := definition.duplicate(true)
		entry["base_kind"] = &"area"
		entry["title"] = _base_localized(entry, "name")
		result.append(entry)
	for definition: Dictionary in BaseManager.get_lighting_definitions():
		var entry := definition.duplicate(true)
		entry["base_kind"] = &"lighting"
		entry["title"] = _base_localized(entry, "name")
		result.append(entry)
	for definition: Dictionary in BaseManager.get_upgrade_definitions():
		var entry := definition.duplicate(true)
		entry["base_kind"] = &"upgrade"
		entry["title"] = _base_localized(entry, "name")
		result.append(entry)
	return result


func _get_base_management_button_text(entry: Dictionary) -> String:
	var title := str(entry.get("title", "BASTION-7"))
	var kind := StringName(str(entry.get("base_kind", "")))
	match kind:
		&"overview":
			return "%s\n// %s" % [title, tr("ARCHIVE_UI_LOCAL_SYSTEMS")]
		&"area":
			var area_id := _entry_string_name(entry, "id")
			var status := tr("ARCHIVE_UI_CLEARANCE_LOCKED")
			if BaseManager.is_area_unlocked(area_id):
				status = tr("ARCHIVE_UI_ACCESS_ONLINE")
			elif BaseManager.can_unlock_area(area_id, GameState.campaign_stage):
				status = tr("ARCHIVE_UI_ACTIVATION_READY")
			return "%s\n// %s" % [title, status]
		&"lighting":
			var mode := int(entry.get("mode", 0))
			var status := (
				tr("ARCHIVE_UI_ACTIVE_PROFILE")
				if mode == BaseManager.get_lighting_mode()
				else tr("ARCHIVE_UI_AVAILABLE")
			)
			return "%s\n// %s" % [title, status]
		&"upgrade":
			var upgrade_id := _entry_string_name(entry, "id")
			return "%s\n// %s %d / %d" % [
				title,
				tr("ARCHIVE_UI_LEVEL"),
				BaseManager.get_upgrade_level(upgrade_id),
				int(entry.get("max_level", 0)),
			]
		_:
			return title


func _show_base_management_entry(entry: Dictionary) -> void:
	var kind := StringName(str(entry.get("base_kind", "")))
	match kind:
		&"overview":
			_show_base_overview()
		&"area":
			_show_base_area(entry)
		&"lighting":
			_show_base_lighting(entry)
		&"upgrade":
			_show_base_upgrade(entry)
		_:
			_set_detail(
				tr("ARCHIVE_UI_BASE_SYSTEM"),
				"BASTION-7",
				tr("ARCHIVE_UI_NO_VALID_BASE_MANAGEMENT_RECORD_WAS"),
				VEX_LOGO,
				false
			)


func _show_base_overview() -> void:
	var unlocked_count := 0
	var areas := BaseManager.get_area_definitions()
	for definition: Dictionary in areas:
		if BaseManager.is_area_unlocked(_entry_string_name(definition, "id")):
			unlocked_count += 1
	var lighting := BaseManager.get_lighting_definition(BaseManager.get_lighting_mode())
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_AREA_ACCESS"),
		tr("ARCHIVE_UI_RECOMMISSIONED_RESTRICTED_AREAS") % [unlocked_count, areas.size()],
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_LIGHTING_PROFILE"),
		_base_localized(lighting, "name"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_UPGRADE_BACKBONE"),
		tr("ARCHIVE_UI_PERSISTENT_UPGRADE_SLOTS_ARE_REGISTERED_FOR"),
	]
	_set_detail(
		tr("ARCHIVE_UI_BASTION_7_BASE_STATUS"),
		tr("ARCHIVE_UI_LOCAL_FACILITY_CONTROL_AIR_GAPPED"),
		body,
		VEX_LOGO,
		false
	)
	_set_base_classification(tr("ARCHIVE_UI_BASTION_7_LOCAL_AUTHORITY_ACTIVE"))


func _show_base_area(entry: Dictionary) -> void:
	var area_id := _entry_string_name(entry, "id")
	var required_stage := int(entry.get("required_stage", 0))
	var unlocked := BaseManager.is_area_unlocked(area_id)
	var can_unlock := BaseManager.can_unlock_area(area_id, GameState.campaign_stage)
	var status := tr("ARCHIVE_UI_CLEARANCE_LOCKED")
	if unlocked:
		status = tr("ARCHIVE_UI_ACCESS_ONLINE")
	elif can_unlock:
		status = tr("ARCHIVE_UI_ACTIVATION_READY")
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_AREA_STATUS"),
		status,
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_FACILITY_RECORD"),
		_base_localized(entry, "description"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_CLEARANCE_REQUIREMENT"),
		_get_base_stage_requirement_text(required_stage),
	]
	_set_detail(
		str(entry.get("title", "FACILITY")),
		tr("ARCHIVE_UI_BASTION_7_AREA_ACCESS_GRID"),
		body,
		VEX_LOGO,
		false
	)
	_set_base_classification(status)
	if unlocked:
		_configure_base_action(
			tr("ARCHIVE_UI_ACCESS_ONLINE"),
			false,
			tr("ARCHIVE_UI_THE_DOOR_NETWORK_IS_ACTIVELY_ENFORCING")
		)
	elif can_unlock:
		_configure_base_action(
			tr("ARCHIVE_UI_RESTORE_ACCESS"),
			true,
			tr("ARCHIVE_UI_ACTIVATION_IS_WRITTEN_TO_THE_CAMPAIGN")
		)
	else:
		_configure_base_action(
			tr("ARCHIVE_UI_CLEARANCE_LOCKED"),
			false,
			_get_base_stage_requirement_text(required_stage)
		)


func _show_base_lighting(entry: Dictionary) -> void:
	var mode := int(entry.get("mode", 0))
	var active := mode == BaseManager.get_lighting_mode()
	var energy_percent := roundi(float(entry.get("energy_multiplier", 1.0)) * 100.0)
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_LIGHTING_PROFILE"),
		_base_localized(entry, "description"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_PRIMARY_LIGHT_POWER"),
		"%d%%" % energy_percent,
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_SCENE_AUTHORITY"),
		tr("ARCHIVE_UI_THIS_PROFILE_DOES_NOT_REPLACE_SCENE"),
	]
	_set_detail(
		str(entry.get("title", "LIGHTING")),
		tr("ARCHIVE_UI_BASTION_7_LIGHTING_CONTROL"),
		body,
		VEX_LOGO,
		false
	)
	_set_base_classification(
		tr("ARCHIVE_UI_ACTIVE_LIGHTING_PROFILE")
		if active
		else tr("ARCHIVE_UI_PROFILE_READY_TO_APPLY")
	)
	_configure_base_action(
		tr("ARCHIVE_UI_ACTIVE") if active else tr("ARCHIVE_UI_APPLY_PROFILE"),
		not active,
		tr("ARCHIVE_UI_THE_CHANGE_IS_APPLIED_TO_BASTION")
	)


func _show_base_upgrade(entry: Dictionary) -> void:
	var upgrade_id := _entry_string_name(entry, "id")
	var level := BaseManager.get_upgrade_level(upgrade_id)
	var max_level := int(entry.get("max_level", 0))
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		tr("ARCHIVE_UI_UPGRADE_TRACK"),
		_base_localized(entry, "description"),
	]
	body += "[color=#78cbd8]%s[/color]\n%d / %d\n\n" % [
		tr("ARCHIVE_UI_CURRENT_LEVEL"),
		level,
		max_level,
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		tr("ARCHIVE_UI_INTEGRATION_STATUS"),
		tr("ARCHIVE_UI_PERSISTENT_STATE_LEVEL_LIMITS_AND_SAVE"),
	]
	_set_detail(
		str(entry.get("title", "UPGRADE")),
		tr("ARCHIVE_UI_BASTION_7_UPGRADE_INFRASTRUCTURE"),
		body,
		VEX_LOGO,
		false
	)
	_set_base_classification(tr("ARCHIVE_UI_INFRASTRUCTURE_READY_EFFECT_HOOK_PENDING"))
	_configure_base_action(
		tr("ARCHIVE_UI_UPGRADES_COMING_LATER"),
		false,
		tr("ARCHIVE_UI_THIS_ACTION_WILL_ACTIVATE_WHEN_THE")
	)


func _configure_base_action(button_text: String, enabled: bool, hint: String) -> void:
	base_action_row.visible = true
	base_action_button.text = button_text
	base_action_button.disabled = not enabled
	base_action_hint.text = hint


func _set_base_classification(text: String) -> void:
	classification_label.text = text
	classification_label.add_theme_color_override("font_color", Color(0.30, 1.0, 0.62, 1.0))


func _activate_base_management_entry() -> void:
	if _current_section != Section.BASE_MANAGEMENT:
		return
	if _selected_index < 0 or _selected_index >= _current_entries.size():
		return
	var entry := _current_entries[_selected_index]
	var kind := StringName(str(entry.get("base_kind", "")))
	var changed := false
	var success_message := ""
	match kind:
		&"area":
			var area_id := _entry_string_name(entry, "id")
			changed = BaseManager.unlock_area(area_id, GameState.campaign_stage)
			if changed:
				success_message = tr("ARCHIVE_UI_BASTION_7_AREA_ACCESS_RESTORED")
		&"lighting":
			changed = BaseManager.set_lighting_mode(int(entry.get("mode", 0)))
			if changed:
				success_message = tr("ARCHIVE_UI_BASTION_7_LIGHTING_PROFILE_UPDATED")
		_:
			return
	if not changed:
		return
	if not GameState.save_current_safe_progress("base_management"):
		GameState.notify(GameState.get_save_failure_message())
		return
	GameState.notify(success_message)


func _get_base_stage_requirement_text(required_stage: int) -> String:
	if required_stage <= 0:
		return tr("ARCHIVE_UI_LOCAL_AUTHORITY_READY")
	return tr("ARCHIVE_UI_CHAPTER_02D_MUST_BE_COMPLETED") % required_stage


func _base_localized(entry: Dictionary, key: String) -> String:
	var suffix := "_tr" if ArchiveDB.is_turkish() else "_en"
	return str(entry.get(key + suffix, entry.get(key, "")))


func _set_detail(
	title: String,
	meta: String,
	body: String,
	texture: Texture2D,
	classified: bool
) -> void:
	base_action_row.visible = false
	base_action_hint.text = ""
	base_action_button.disabled = true
	detail_title.text = title
	detail_meta.text = meta
	detail_body.text = body
	detail_preview.texture = texture
	detail_preview.modulate = (
		Color(0.42, 0.78, 0.82, 0.32)
		if classified
		else Color.WHITE
	)
	classification_label.text = (
		tr("ARCHIVE_UI_CLASSIFIED_DATA_INCOMPLETE")
		if classified
		else tr("ARCHIVE_UI_VEX_ARCHIVE_VERIFICATION_VALID")
	)
	classification_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.32, 0.18, 1.0) if classified else Color(0.30, 1.0, 0.62, 1.0)
	)


func _get_enemy_preview(entry: Dictionary) -> Texture2D:
	var enemy_id := _entry_string_name(entry, "id")
	if _preview_cache.has(enemy_id):
		return _preview_cache[enemy_id] as Texture2D

	var sheet_path := ArchiveDB.enemy_sheet_path(entry)
	var manifest_path := ArchiveDB.enemy_manifest_path(entry)
	if sheet_path.is_empty() or not ResourceLoader.exists(sheet_path):
		var folder := str(entry.get("asset_folder", ""))
		var legacy_path := "res://assets/enemies/%s/%s_spritesheet.png" % [folder, folder]
		if not folder.is_empty() and ResourceLoader.exists(legacy_path):
			sheet_path = legacy_path
			manifest_path = ""
		else:
			_preview_cache[enemy_id] = VEX_LOGO
			return VEX_LOGO

	var sheet := load(sheet_path) as Texture2D
	if sheet == null:
		_preview_cache[enemy_id] = VEX_LOGO
		return VEX_LOGO

	if not manifest_path.is_empty() and FileAccess.file_exists(manifest_path):
		var manifest_preview := _preview_from_manifest(sheet, manifest_path)
		if manifest_preview != null:
			_preview_cache[enemy_id] = manifest_preview
			return manifest_preview

	if LEGACY_PREVIEW_REGIONS.has(enemy_id):
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = LEGACY_PREVIEW_REGIONS[enemy_id] as Rect2
		_preview_cache[enemy_id] = atlas
		return atlas

	_preview_cache[enemy_id] = VEX_LOGO
	return VEX_LOGO


func _preview_from_manifest(sheet: Texture2D, manifest_path: String) -> Texture2D:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
	if not (parsed is Dictionary):
		return null
	var frame_size: Variant = (parsed as Dictionary).get("frame_size", {})
	if not (frame_size is Dictionary):
		return null
	var width := float((frame_size as Dictionary).get("width", 0))
	var height := float((frame_size as Dictionary).get("height", 0))
	if width <= 0.0 or height <= 0.0:
		return null
	var atlas := AtlasTexture.new()
	atlas.atlas = sheet
	atlas.region = Rect2(0.0, 0.0, width, height)
	return atlas


func _is_enemy_discovered(entry: Dictionary) -> bool:
	return ArchiveManager.is_enemy_discovered(_entry_string_name(entry, "id"))


func _is_universe_known(entry: Dictionary) -> bool:
	var values: Variant = entry.get("enemy_ids", [])
	if not (values is Array):
		return false
	for value: Variant in values:
		if ArchiveManager.is_enemy_discovered(StringName(str(value))):
			return true
	return false


func _is_log_unlocked(entry: Dictionary) -> bool:
	var required_stage := int(entry.get("unlock_stage", 0))
	match _entry_string_name(entry, "id"):
		&"vex01":
			required_stage = maxi(required_stage, 1)
		&"vex02":
			required_stage = maxi(required_stage, 2)
		&"vex03":
			required_stage = maxi(required_stage, 3)
	return GameState.campaign_stage >= required_stage


func _get_discovered_database_count() -> int:
	var count := 0
	for entry: Dictionary in ArchiveDB.ENEMIES:
		if _is_enemy_discovered(entry):
			count += 1
	return count


func _get_known_universe_count() -> int:
	var count := 0
	for entry: Dictionary in ArchiveDB.UNIVERSES:
		if _is_universe_known(entry):
			count += 1
	return count


func _get_universe_name(universe_id: StringName) -> String:
	var universe := ArchiveDB.get_universe(universe_id)
	return ArchiveDB.universe_name(universe) if not universe.is_empty() else "UNKNOWN"


func _get_universe_recommendation(universe_id: StringName) -> String:
	match universe_id:
		&"korvath":
			return tr("ARCHIVE_UI_EXPLOIT_HEAVY_UNIT_WINDUPS_AND_PREVENT")
		&"thornwild":
			return tr("ARCHIVE_UI_PRESERVE_MOVEMENT_CORRIDORS_WHEN_CHARGES_TOXIC")
		&"vaskari":
			return tr("ARCHIVE_UI_READ_THE_FORMATION_RATHER_THAN_INDIVIDUAL")
		&"nhal":
			return tr("ARCHIVE_UI_TREAT_INFORMATION_LOSS_AS_LETHAL_PRIORITIZE")
		&"aether":
			return tr("ARCHIVE_UI_TRACK_POSSIBLE_ATTACK_ANGLES_MORE_THAN")
		_:
			return tr("ARCHIVE_UI_INSUFFICIENT_DATA")


func _build_rift_network_entries() -> Array[Dictionary]:
	var known_universes := _get_known_universe_count()
	var discovered := _get_discovered_database_count()
	return [
		{
			"title": tr("ARCHIVE_UI_RIFT_NETWORK_OVERVIEW"),
			"meta": tr("ARCHIVE_UI_BASTION_7_ISOLATED_TELEMETRY"),
			"body": tr("ARCHIVE_UI_THE_RIFT_NETWORK_IS_THE_INTERDIMENSIONAL") % [
					_rift_network_status_line(),
					known_universes,
					ArchiveDB.UNIVERSES.size(),
					discovered,
					ArchiveDB.ENEMIES.size(),
					GameState.campaign_stage,
				],
		},
		{
			"title": tr("ARCHIVE_UI_DIMENSIONAL_EXTRACTION_MATRIX"),
			"meta": tr("ARCHIVE_UI_ZERO_SOURCE_REACTOR_CAUSALITY"),
			"body": _build_extraction_matrix(),
		},
		{
			"title": tr("ARCHIVE_UI_BASTION_7_NETWORK_AIR_GAP"),
			"meta": tr("ARCHIVE_UI_PHYSICAL_NETWORK_ISOLATION_ACTIVE"),
			"body": tr("ARCHIVE_UI_BASTION_7_IS_PHYSICALLY_SEPARATED_FROM"),
		},
		{
			"title": tr("ARCHIVE_UI_PRIMARY_OBJECTIVE_BASTION_DIRECTIVE"),
			"meta": tr("ARCHIVE_UI_STRATEGIC_DIRECTIVE"),
			"body": _rift_network_directive(),
		},
	]


# Yarık Ağı'nın kendi bağlantılarını dengelediği Bölüm 20'de keşfedilir; öncesinde
# terminal yalnız o ana kadar doğrulanmış bilgiyi ve güncel direktifi gösterir.
const RIFT_SELF_BALANCING_STAGE := 20
const FIRST_ANCHOR_STAGE := 5


func _rift_network_status_line() -> String:
	if GameState.campaign_stage >= RIFT_SELF_BALANCING_STAGE:
		return tr("ARCHIVE_UI_EVEN_IF_A_LOCAL_PASSAGE_CLOSES")
	if GameState.campaign_stage >= 3:
		return tr("ARCHIVE_UI_SELIN_ERDEM_S_ANALYSIS_SHOWS_THE")
	return tr("ARCHIVE_UI_THE_NETWORK_S_SCALE_AND_SOURCE")


func _rift_network_directive() -> String:
	if GameState.campaign_stage >= RIFT_SELF_BALANCING_STAGE:
		return tr("ARCHIVE_UI_CLOSING_INDIVIDUAL_RIFTS_IS_NOT_A")
	if GameState.campaign_stage >= FIRST_ANCHOR_STAGE:
		return tr("ARCHIVE_UI_LOCATE_SOURCE_NODES_AND_THEIR_ANCHORS")
	return tr("ARCHIVE_UI_FIND_SURVIVORS_SECURE_VEX_FACILITY_RECORDS")


func _build_extraction_matrix() -> String:
	var lines := PackedStringArray()
	for universe: Dictionary in ArchiveDB.UNIVERSES:
		if _is_universe_known(universe):
			lines.append("[color=#78cbd8]%s[/color]\n%s" % [
				ArchiveDB.universe_name(universe),
				ArchiveDB.universe_story_text(universe, "extraction", GameState.campaign_stage),
			])
		else:
			lines.append("[color=#7a4440]%s[/color]\n%s" % [
				tr("ARCHIVE_UI_UNCLASSIFIED_REALITY"),
				tr("ARCHIVE_UI_EXTRACTION_PROFILE_UNVERIFIED"),
			])
	return "\n\n".join(lines)


func _localized_body(entry: Dictionary) -> String:
	return str(entry.get("body_tr" if ArchiveDB.is_turkish() else "body_en", ""))


func _entry_string_name(entry: Dictionary, key: String) -> StringName:
	return StringName(str(entry.get(key, "")))


func _on_archive_changed(_enemy_id: StringName) -> void:
	_refresh_all()


func _on_base_state_changed() -> void:
	if terminal_root.visible and _current_section == Section.BASE_MANAGEMENT:
		_refresh_all()


func _on_language_changed(_locale: String) -> void:
	_preview_cache.clear()
	_refresh_all()

