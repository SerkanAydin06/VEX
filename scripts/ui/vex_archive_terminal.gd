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
}

@onready var terminal_root: Control = %ArchiveRoot
@onready var creatures_tab: Button = %CreaturesTab
@onready var universes_tab: Button = %UniversesTab
@onready var records_tab: Button = %RecordsTab
@onready var threat_tab: Button = %ThreatTab
@onready var rift_tab: Button = %RiftTab
@onready var protocols_tab: Button = %ProtocolsTab
@onready var entry_list: VBoxContainer = %EntryList
@onready var section_title: Label = %SectionTitle
@onready var archive_summary: Label = %ArchiveSummary
@onready var detail_preview: TextureRect = %DetailPreview
@onready var detail_title: Label = %DetailTitle
@onready var detail_meta: Label = %DetailMeta
@onready var detail_body: RichTextLabel = %DetailBody
@onready var classification_label: Label = %ClassificationLabel
@onready var close_button: Button = %CloseButton

var _current_section := Section.CREATURES
var _current_entries: Array[Dictionary] = []
var _selected_index := 0
var _was_paused := false
var _preview_cache: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	creatures_tab.pressed.connect(_select_section.bind(Section.CREATURES))
	universes_tab.pressed.connect(_select_section.bind(Section.UNIVERSES))
	records_tab.pressed.connect(_select_section.bind(Section.RECORDS))
	threat_tab.pressed.connect(_select_section.bind(Section.THREAT_ANALYSIS))
	rift_tab.pressed.connect(_select_section.bind(Section.RIFT_NETWORK))
	protocols_tab.pressed.connect(_select_section.bind(Section.PROTOCOLS))
	close_button.pressed.connect(close_terminal)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	if not ArchiveManager.archive_changed.is_connected(_on_archive_changed):
		ArchiveManager.archive_changed.connect(_on_archive_changed)
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
	if not terminal_root.visible:
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
	close_button.text = _t("TERMİNALİ KAPAT", "CLOSE TERMINAL")


func _refresh_header() -> void:
	var discovered := _get_discovered_database_count()
	var known_universes := _get_known_universe_count()
	archive_summary.text = _t(
		"XENOARŞİV %d / %d  //  EVREN %d / %d  //  AĞ AŞAMASI %02d" % [
			discovered,
			ArchiveDB.ENEMIES.size(),
			known_universes,
			ArchiveDB.UNIVERSES.size(),
			GameState.campaign_stage,
		],
		"XENOARCHIVE %d / %d  //  REALITIES %d / %d  //  NETWORK STAGE %02d" % [
			discovered,
			ArchiveDB.ENEMIES.size(),
			known_universes,
			ArchiveDB.UNIVERSES.size(),
			GameState.campaign_stage,
		]
	)


func _refresh_tabs() -> void:
	creatures_tab.text = _t("YARATIKLAR", "CREATURES")
	universes_tab.text = _t("EVRENLER", "REALITIES")
	records_tab.text = _t("KAYITLAR", "RECORDS")
	threat_tab.text = _t("TEHDİT ANALİZİ", "THREAT ANALYSIS")
	rift_tab.text = _t("YARIK AĞI", "RIFT NETWORK")
	protocols_tab.text = _t("PROTOKOLLER", "PROTOCOLS")
	var tabs: Array[Button] = [
		creatures_tab,
		universes_tab,
		records_tab,
		threat_tab,
		rift_tab,
		protocols_tab,
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
		button.custom_minimum_size = Vector2(0.0, 58.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
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
				result.append(entry)
	return result


func _get_section_title() -> String:
	match _current_section:
		Section.CREATURES:
			return _t("XENO VARLIK İNDEKSİ", "XENO ENTITY INDEX")
		Section.UNIVERSES:
			return _t("GERÇEKLİK KAYITLARI", "REALITY RECORDS")
		Section.RECORDS:
			return _t("OPERASYON KAYITLARI", "OPERATION RECORDS")
		Section.THREAT_ANALYSIS:
			return _t("TAKTİK TEHDİT MATRİSİ", "TACTICAL THREAT MATRIX")
		Section.RIFT_NETWORK:
			return _t("YARIK AĞI TELEMETRİSİ", "RIFT NETWORK TELEMETRY")
		_:
			return _t("VEX SAHA PROTOKOLLERİ", "VEX FIELD PROTOCOLS")


func _get_entry_button_text(entry: Dictionary, index: int) -> String:
	match _current_section:
		Section.CREATURES:
			if not _is_enemy_discovered(entry):
				return "XENO-%02d  //  ???" % (index + 1)
			return "%s  //  %s" % [
				entry.get("name", "UNKNOWN"),
				_get_universe_name(_entry_string_name(entry, "universe")),
			]
		Section.UNIVERSES, Section.THREAT_ANALYSIS:
			if _is_universe_known(entry):
				return str(entry.get("name", "UNKNOWN"))
			return _t(
				"SINIFLANDIRILMAMIŞ GERÇEKLİK %02d" % (index + 1),
				"UNCLASSIFIED REALITY %02d" % (index + 1)
			)
		Section.RECORDS:
			if _is_log_unlocked(entry):
				return str(entry.get("title", "RECORD"))
			return _t(
				"ŞİFRELİ KAYIT // %02d" % (index + 1),
				"ENCRYPTED RECORD // %02d" % (index + 1)
			)
		_:
			return str(entry.get("title", "DATA"))


func _refresh_detail() -> void:
	if _selected_index < 0 or _selected_index >= _current_entries.size():
		_set_detail(
			_t("VERİ YOK", "NO DATA"),
			"",
			_t("Bu bölümde görüntülenecek kayıt yok.", "No records are available in this section."),
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


func _show_enemy(entry: Dictionary) -> void:
	if not _is_enemy_discovered(entry):
		_set_detail(
			_t("SINIFLANDIRILMAMIŞ XENO VARLIK", "UNCLASSIFIED XENO ENTITY"),
			_t("SAHA TEMASI GEREKLİ", "FIELD CONTACT REQUIRED"),
			_t(
				"Bu kayıt henüz doğrulanmadı. VEX arşivi bir türü ilk doğrulanmış etkisizleştirmeden sonra davranış ve köken verisiyle açar.",
				"This record has not been verified. The VEX archive unlocks behavior and origin data after the first confirmed elimination of a species."
			),
			VEX_LOGO,
			true
		)
		return

	var universe_id := _entry_string_name(entry, "universe")
	var universe := ArchiveDB.get_universe(universe_id)
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("GÖZLENEN DAVRANIŞ", "OBSERVED BEHAVIOR"),
		ArchiveDB.localized(entry, "behavior"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("TAKTİK KARŞILIK", "TACTICAL RESPONSE"),
		ArchiveDB.localized(entry, "tactic"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("EKOLOJİK / TOPLUMSAL ROL", "ECOLOGICAL / SOCIAL ROLE"),
		ArchiveDB.localized(entry, "lore"),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		_t("KAYNAK GERÇEKLİK", "ORIGIN REALITY"),
		ArchiveDB.localized(universe, "extraction"),
	]
	_set_detail(
		str(entry.get("name", "UNKNOWN")),
		_t(
			"KÖKEN // %s    ROL // %s    TEHDİT // %s" % [
				_get_universe_name(universe_id),
				ArchiveDB.localized(entry, "role"),
				entry.get("threat", "?"),
			],
			"ORIGIN // %s    ROLE // %s    THREAT // %s" % [
				_get_universe_name(universe_id),
				ArchiveDB.localized(entry, "role"),
				entry.get("threat", "?"),
			]
		),
		body,
		_get_enemy_preview(entry),
		false
	)


func _show_universe(entry: Dictionary) -> void:
	if not _is_universe_known(entry):
		_set_detail(
			_t("SINIFLANDIRILMAMIŞ GERÇEKLİK", "UNCLASSIFIED REALITY"),
			_t("XENO BAĞLANTISI DOĞRULANMADI", "XENO LINK UNVERIFIED"),
			_t(
				"Bu gerçekliğe ait doğrulanmış bir saha örneği bulunmuyor. İlk doğrulanmış temas sonrası kaynak, ekoloji ve baskı profili açılacak.",
				"No verified field specimen from this reality is available. Resource, ecology and pressure profiles will unlock after first confirmed contact."
			),
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
		_t("GERÇEKLİK KİMLİĞİ", "REALITY IDENTITY"), ArchiveDB.localized(entry, "identity")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("VEX KAYNAK ÇEKİMİ", "VEX EXTRACTION"), ArchiveDB.localized(entry, "extraction")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("SAHA BASKI PROFİLİ", "FIELD PRESSURE PROFILE"), ArchiveDB.localized(entry, "pressure")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("GÖRSEL İMZA", "VISUAL SIGNATURE"), ArchiveDB.localized(entry, "palette")
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		_t("DOĞRULANAN TÜRLER", "VERIFIED SPECIES"),
		", ".join(discovered_names) if not discovered_names.is_empty() else "—",
	]
	_set_detail(
		str(entry.get("name", "UNKNOWN")),
		_t(
			"DOĞRULANAN TÜR // %d / %d" % [discovered_names.size(), ids.size()],
			"VERIFIED SPECIES // %d / %d" % [discovered_names.size(), ids.size()]
		),
		body,
		VEX_LOGO,
		false
	)


func _show_log(entry: Dictionary) -> void:
	if not _is_log_unlocked(entry):
		_set_detail(
			_t("ŞİFRELİ OPERASYON KAYDI", "ENCRYPTED OPERATION RECORD"),
			_t(
				"YETKİ YETERSİZ // OPERASYON TAMAMLANMALI",
				"INSUFFICIENT CLEARANCE // OPERATION MUST BE COMPLETED"
			),
			_t(
				"Bu kayıt mevcut operasyon yetkisiyle açılamıyor. İlgili saha operasyonunun tamamlanması gerekiyor.",
				"This record cannot be opened with the current clearance. The related field operation must be completed."
			),
			VEX_LOGO,
			true
		)
		return
	_set_detail(
		str(entry.get("title", "RECORD")),
		_t("VEX GÜVENLİ KAYIT // DOĞRULANDI", "VEX SECURE RECORD // VERIFIED"),
		_localized_body(entry),
		VEX_LOGO,
		false
	)


func _show_threat_analysis(entry: Dictionary) -> void:
	if not _is_universe_known(entry):
		_set_detail(
			_t("TEHDİT MATRİSİ // VERİ YETERSİZ", "THREAT MATRIX // INSUFFICIENT DATA"),
			_t("DOĞRULANMIŞ TÜR GEREKLİ", "VERIFIED SPECIES REQUIRED"),
			_t(
				"Aile düzeyi taktik model üretmek için bu gerçeklikten en az bir doğrulanmış saha teması gerekiyor.",
				"At least one verified field contact from this reality is required to build a family-level tactical model."
			),
			VEX_LOGO,
			true
		)
		return
	var universe_id := _entry_string_name(entry, "id")
	var body := "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("ANA BASKI", "PRIMARY PRESSURE"), ArchiveDB.localized(entry, "pressure")
	]
	body += "[color=#78cbd8]%s[/color]\n%s\n\n" % [
		_t("VEX TAKTİK ÖNERİSİ", "VEX TACTICAL RECOMMENDATION"),
		_get_universe_recommendation(universe_id),
	]
	body += "[color=#78cbd8]%s[/color]\n%s" % [
		_t("TANIMA İMZASI", "IDENTIFICATION SIGNATURE"), ArchiveDB.localized(entry, "palette")
	]
	_set_detail(
		_t(
			"%s // TEHDİT MODELİ" % entry.get("name", "UNKNOWN"),
			"%s // THREAT MODEL" % entry.get("name", "UNKNOWN")
		),
		_t("AİLE BAZLI KARŞI OYUN", "FAMILY-LEVEL COUNTERPLAY"),
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
		str(entry.get("title", "PROTOCOL")),
		_t("VEX SAHA DOKTRİNİ // AKTİF", "VEX FIELD DOCTRINE // ACTIVE"),
		_localized_body(entry),
		VEX_LOGO,
		false
	)


func _set_detail(
	title: String,
	meta: String,
	body: String,
	texture: Texture2D,
	classified: bool
) -> void:
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
		_t("SINIFLANDIRILMIŞ // VERİ EKSİK", "CLASSIFIED // DATA INCOMPLETE")
		if classified
		else _t("VEX ARŞİV DOĞRULAMASI // GEÇERLİ", "VEX ARCHIVE VERIFICATION // VALID")
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
	return str(universe.get("name", "UNKNOWN"))


func _get_universe_recommendation(universe_id: StringName) -> String:
	match universe_id:
		&"korvath":
			return _t(
				"Ağır hedeflerin hazırlık pencerelerini kullan; termal alanlarla projectile çizgilerinin aynı anda hareket alanını kapatmasına izin verme.",
				"Exploit heavy-unit windups and prevent thermal zones from overlapping projectile lanes until your movement space collapses."
			)
		&"thornwild":
			return _t(
				"Hareket koridorunu koru. Charge, zehir alanı ve hibrit avcılar aynı anda baskı kurduğunda hasardan önce pozisyonu çöz.",
				"Preserve movement corridors. When charges, toxic zones and hybrid hunters overlap, solve positioning before chasing damage."
			)
		&"vaskari":
			return _t(
				"Tek hedef gücüne değil formasyona bak. Komuta/destek ve uzun menzil rollerini güvenli fırsatta önce kır.",
				"Read the formation rather than individual strength. Break command/support and ranged roles first whenever a safe opportunity exists."
			)
		&"nhal":
			return _t(
				"Bilgi kaybını ölümcül kabul et. Son güvenli konumu, ses bilgisini ve açı kontrolünü görüş bozulduğunda önceliklendir.",
				"Treat information loss as lethal. Prioritize the last safe position, audio cues and angle checks whenever visibility is disrupted."
			)
		&"aether":
			return _t(
				"Düşmanın mevcut konumundan çok açabileceği açıları izle. Enerji fanları ve phase step için geniş kaçış payı bırak.",
				"Track possible attack angles more than current positions. Reserve broad dodge space for energy fans and phase steps."
			)
		_:
			return _t("Yeterli veri yok.", "Insufficient data.")


func _build_rift_network_entries() -> Array[Dictionary]:
	var known_universes := _get_known_universe_count()
	var discovered := _get_discovered_database_count()
	return [
		{
			"title": _t("YARIK AĞI // GENEL DURUM", "RIFT NETWORK // OVERVIEW"),
			"meta": _t("BASTION-7 İZOLE TELEMETRİ", "BASTION-7 ISOLATED TELEMETRY"),
			"body": _t(
				"Yarık Ağı, VEX reaktörlerini birbirine bağlayan boyutlar arası enerji omurgasıdır. Yerel geçit kapansa bile ağ çalışıyorsa başka bir düğüm yeniden açılabilir.\n\nDOĞRULANAN GERÇEKLİK: %d / %d\nDOĞRULANAN XENO VARLIK: %d / %d\nCAMPAIGN AŞAMASI: %02d" % [
					known_universes,
					ArchiveDB.UNIVERSES.size(),
					discovered,
					ArchiveDB.ENEMIES.size(),
					GameState.campaign_stage,
				],
				"The Rift Network is the interdimensional energy backbone connecting VEX reactors. Even if a local passage closes, another node can reopen while the network remains active.\n\nVERIFIED REALITIES: %d / %d\nVERIFIED XENO ENTITIES: %d / %d\nCAMPAIGN STAGE: %02d" % [
					known_universes,
					ArchiveDB.UNIVERSES.size(),
					discovered,
					ArchiveDB.ENEMIES.size(),
					GameState.campaign_stage,
				]
			),
		},
		{
			"title": _t("BOYUTSAL KAYNAK MATRİSİ", "DIMENSIONAL EXTRACTION MATRIX"),
			"meta": _t("SIFIR KAYNAK REAKTÖRÜ // NEDENSELLİK", "ZERO SOURCE REACTOR // CAUSALITY"),
			"body": _build_extraction_matrix(),
		},
		{
			"title": "BASTION-7 // NETWORK AIR GAP",
			"meta": _t("FİZİKSEL AĞ İZOLASYONU // AKTİF", "PHYSICAL NETWORK ISOLATION // ACTIVE"),
			"body": _t(
				"Bastion-7 ana Yarık Ağı'ndan fiziksel olarak ayrıdır. Bu izolasyon üssü güvenli operasyon, arşiv ve yeniden konuşlanma merkezi hâline getirir. Terminal verileri saha kayıtlarından yerel olarak derlenir.",
				"Bastion-7 is physically separated from the main Rift Network. This isolation makes the base a secure operations, archive and redeployment center. Terminal data is compiled locally from field records."
			),
		},
		{
			"title": _t("ANA HEDEF // AĞI SUSTUR", "PRIMARY OBJECTIVE // SILENCE THE NETWORK"),
			"meta": _t("STRATEJİK DİREKTİF", "STRATEGIC DIRECTIVE"),
			"body": _t(
				"Tek tek yarıkları kapatmak kalıcı çözüm değildir. Nihai amaç enerji çekimini besleyen düğümleri devre dışı bırakmak, kaynak gerçeklik bağlantılarını çözmek ve Yarık Ağı'nın merkezini kalıcı olarak susturmaktır.",
				"Closing individual rifts is not a permanent solution. The final objective is to disable the nodes feeding extraction, resolve origin-reality links and permanently silence the core of the Rift Network."
			),
		},
	]


func _build_extraction_matrix() -> String:
	var lines := PackedStringArray()
	for universe: Dictionary in ArchiveDB.UNIVERSES:
		if _is_universe_known(universe):
			lines.append("[color=#78cbd8]%s[/color]\n%s" % [
				universe.get("name", "UNKNOWN"),
				ArchiveDB.localized(universe, "extraction"),
			])
		else:
			lines.append("[color=#7a4440]%s[/color]\n%s" % [
				_t("SINIFLANDIRILMAMIŞ GERÇEKLİK", "UNCLASSIFIED REALITY"),
				_t("Kaynak profili doğrulanmadı.", "Extraction profile unverified."),
			])
	return "\n\n".join(lines)


func _localized_body(entry: Dictionary) -> String:
	return str(entry.get("body_tr" if ArchiveDB.is_turkish() else "body_en", ""))


func _entry_string_name(entry: Dictionary, key: String) -> StringName:
	return StringName(str(entry.get(key, "")))


func _on_archive_changed(_enemy_id: StringName) -> void:
	_refresh_all()


func _on_language_changed(_locale: String) -> void:
	_preview_cache.clear()
	_refresh_all()


func _t(turkish: String, english: String) -> String:
	return turkish if ArchiveDB.is_turkish() else english
