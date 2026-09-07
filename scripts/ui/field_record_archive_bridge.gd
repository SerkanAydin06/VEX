class_name VexFieldRecordArchiveBridge
extends Node

const RecordDB = preload("res://scripts/data/vex_field_record_database.gd")
const VEX_LOGO = preload("res://assets/ui/vex_logo.png")

var _terminal: Node = null
var _terminal_root: Control = null
var _records_tab: Button = null
var _entry_list: VBoxContainer = null
var _section_title: Label = null
var _detail_preview: TextureRect = null
var _detail_title: Label = null
var _detail_meta: Label = null
var _detail_body: RichTextLabel = null
var _classification_label: Label = null
var _base_action_row: Control = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_terminal = get_parent()
	if _terminal == null:
		queue_free()
		return
	_resolve_nodes()
	if _records_tab == null or _terminal_root == null:
		push_warning("VEX saha kayıt köprüsü ana terminal node'larını bulamadı.")
		queue_free()
		return
	if not _records_tab.pressed.is_connected(_on_records_pressed):
		_records_tab.pressed.connect(_on_records_pressed)
	if not _terminal_root.visibility_changed.is_connected(_on_terminal_visibility_changed):
		_terminal_root.visibility_changed.connect(_on_terminal_visibility_changed)
	if not BaseManager.field_record_changed.is_connected(_on_field_record_changed):
		BaseManager.field_record_changed.connect(_on_field_record_changed)
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)
	call_deferred("_refresh_if_active")


func _resolve_nodes() -> void:
	_terminal_root = _terminal.get_node_or_null("ArchiveRoot") as Control
	_records_tab = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/NavigationPanel/NavMargin/NavVBox/RecordsTab") as Button
	_entry_list = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/IndexPanel/IndexMargin/IndexVBox/EntryScroll/EntryList") as VBoxContainer
	_section_title = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/IndexPanel/IndexMargin/IndexVBox/SectionTitle") as Label
	_detail_preview = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/DetailTop/PreviewPanel/DetailPreview") as TextureRect
	_detail_title = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/DetailTop/IdentityBlock/DetailTitle") as Label
	_detail_meta = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/DetailTop/IdentityBlock/DetailMeta") as Label
	_detail_body = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/DetailBody") as RichTextLabel
	_classification_label = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/DetailTop/IdentityBlock/ClassificationLabel") as Label
	_base_action_row = _terminal.get_node_or_null("ArchiveRoot/ScreenShell/Margin/VBox/Body/DetailPanel/DetailMargin/DetailVBox/BaseActionRow") as Control


func _on_records_pressed() -> void:
	call_deferred("_refresh_if_active")


func _on_terminal_visibility_changed() -> void:
	if _terminal_root != null and _terminal_root.visible:
		call_deferred("_refresh_if_active")


func _on_field_record_changed(_record_id: StringName) -> void:
	call_deferred("_refresh_if_active")


func _on_language_changed(_locale: String) -> void:
	call_deferred("_refresh_if_active")


func _refresh_if_active() -> void:
	if not is_inside_tree() or _terminal_root == null or not _terminal_root.visible:
		return
	if _records_tab == null or not _records_tab.button_pressed:
		return
	_refresh_records()


func _refresh_records() -> void:
	if _entry_list == null:
		return
	for child: Node in _entry_list.get_children():
		child.free()
	if _base_action_row != null:
		_base_action_row.visible = false

	# BaseManagementDashboard kendi sekme görünürlüğünün sahibidir. Bu köprü ona
	# dokunmaz; Records sekmesi sadece mevcut index/detail kayıt alanını yeniler.
	var record_ids := BaseManager.get_discovered_field_record_ids()
	if _section_title != null:
		_section_title.text = _t(
			"SAHA KAYITLARI // %d / %d" % [record_ids.size(), RecordDB.TOTAL_CAMPAIGN_RECORDS],
			"FIELD RECORDS // %d / %d" % [record_ids.size(), RecordDB.TOTAL_CAMPAIGN_RECORDS]
		)

	if record_ids.is_empty():
		_show_empty_state()
		return

	var first_button: Button = null
	var first_record_id: StringName = &""
	for record_id: StringName in record_ids:
		var entry := RecordDB.get_record(record_id)
		if entry.is_empty():
			continue
		var button := Button.new()
		button.custom_minimum_size = Vector2(0.0, 68.0)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = false
		button.add_theme_font_size_override("font_size", 13)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.toggle_mode = true
		button.text = _record_button_text(entry)
		button.pressed.connect(_select_record.bind(record_id, button))
		_entry_list.add_child(button)
		if first_button == null:
			first_button = button
			first_record_id = record_id

	if first_button != null:
		_select_record(first_record_id, first_button)
	else:
		_show_empty_state()


func _select_record(record_id: StringName, selected_button: Button) -> void:
	if _entry_list != null:
		for child: Node in _entry_list.get_children():
			var button := child as Button
			if button != null:
				button.button_pressed = button == selected_button
	var entry := RecordDB.get_record(record_id)
	if entry.is_empty():
		_show_empty_state()
		return
	if _detail_preview != null:
		_detail_preview.texture = VEX_LOGO
		_detail_preview.modulate = Color.WHITE
	if _detail_title != null:
		_detail_title.text = RecordDB.localized(entry, "title")
	if _detail_meta != null:
		_detail_meta.text = _t(
			"SAHA KAYDI // BÖLÜM %02d // %s // %s" % [
				int(entry.get("chapter", 0)),
				str(entry.get("room", "—")),
				RecordDB.localized(entry, "category"),
			],
			"FIELD RECORD // CHAPTER %02d // %s // %s" % [
				int(entry.get("chapter", 0)),
				str(entry.get("room", "—")),
				RecordDB.localized(entry, "category"),
			]
		)
	if _detail_body != null:
		_detail_body.text = RecordDB.localized(entry, "body")
	if _classification_label != null:
		_classification_label.text = _t(
			"SAHA VERİSİ // YEREL ARŞİVE AKTARILDI",
			"FIELD DATA // COPIED TO LOCAL ARCHIVE"
		)
		_classification_label.add_theme_color_override("font_color", Color(0.30, 1.0, 0.62, 1.0))


func _show_empty_state() -> void:
	if _detail_preview != null:
		_detail_preview.texture = VEX_LOGO
		_detail_preview.modulate = Color(0.42, 0.78, 0.82, 0.32)
	if _detail_title != null:
		_detail_title.text = _t("SAHA KAYDI BULUNMADI", "NO FIELD RECORDS FOUND")
	if _detail_meta != null:
		_detail_meta.text = _t("SAHADA VERİ TERMİNALİ ARA", "SEARCH FOR DATA TERMINALS IN THE FIELD")
	if _detail_body != null:
		_detail_body.text = _t(
			"Bulduğun saha kayıtları burada kalıcı olarak listelenecek. Ana kampanyada toplam 90 kayıt planlandı; kilitli veya bulunmamış kayıtların başlıkları gösterilmez.",
			"Recovered field records will be listed here permanently. The main campaign targets 90 records; titles for locked or undiscovered records are not shown."
		)
	if _classification_label != null:
		_classification_label.text = _t("VERİ BEKLİYOR", "AWAITING DATA")
		_classification_label.add_theme_color_override("font_color", Color(1.0, 0.52, 0.24, 1.0))


func _record_button_text(entry: Dictionary) -> String:
	return "%s\n// %s" % [
		RecordDB.localized(entry, "title"),
		_t(
			"BÖLÜM %02d // %s" % [int(entry.get("chapter", 0)), str(entry.get("room", "—"))],
			"CHAPTER %02d // %s" % [int(entry.get("chapter", 0)), str(entry.get("room", "—"))]
		),
	]


func _t(turkish: String, english: String) -> String:
	return turkish if TranslationServer.get_locale().begins_with("tr") else english
