class_name VexFieldRecordTerminal
extends StaticBody3D

const DiscoveryOverlay = preload("res://scripts/ui/discovery_notification_overlay.gd")
const RecordDB = preload("res://scripts/data/vex_field_record_database.gd")
const READER_THEME: Theme = preload("res://resources/ui/vex_theme.tres")
const READER_HEADING: Font = preload("res://resources/ui/fonts/vex_heading_font.tres")
const READER_MONO: Font = preload("res://resources/ui/fonts/vex_mono_font.tres")

@export_category("Kayıt")
@export var record_id: StringName = &""
# Bu alanlar editor/fallback sunumu içindir. record_id veritabanında varsa
# runtime okuyucu kanonik metni VexFieldRecordDatabase üzerinden kullanır.
@export var category_tr := "KAYIT"
@export var category_en := "RECORD"
@export var title_tr := "SAHA KAYDI"
@export var title_en := "FIELD RECORD"
@export_multiline var body_tr := ""
@export_multiline var body_en := ""
@export var objective_after_read := ""

@export_category("Etkileşim")
@export var interaction_tr := "KAYDI OKU"
@export var interaction_en := "READ RECORD"

const SCREEN_ENCRYPTED_COLOR := Color(1.0, 0.66, 0.2, 1.0)
const SCREEN_DECODED_COLOR := Color(0.36, 1.0, 0.68, 1.0)
const READER_ACCENT := Color(0.24, 0.84, 1.0, 1.0)
const READER_MUTED := Color(0.56, 0.68, 0.74, 1.0)
const READER_BODY_COLOR := Color(0.86, 0.92, 0.95, 1.0)

var _reader_layer: CanvasLayer = null
var _reader_title: Label = null
var _reader_category: Label = null
var _reader_meta: Label = null
var _reader_status: Label = null
var _reader_body: RichTextLabel = null
var _close_button: Button = null
var _status_lamp_material: StandardMaterial3D = null
var _is_open := false
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _was_tree_paused := false
var _ignore_close_until_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var lamp := get_node_or_null("StatusLamp") as MeshInstance3D
	if lamp != null and lamp.mesh != null and lamp.mesh.surface_get_material(0) is StandardMaterial3D:
		_status_lamp_material = (lamp.mesh.surface_get_material(0) as StandardMaterial3D).duplicate()
		lamp.material_override = _status_lamp_material
	_refresh_screen()


func get_interaction_text(_actor: Node = null) -> String:
	return "[E] %s" % _localized(interaction_tr, interaction_en)


func interact(_actor: Node = null) -> void:
	if _is_open:
		return
	_open_record()


func _input(event: InputEvent) -> void:
	if not _is_open or Time.get_ticks_msec() < _ignore_close_until_msec:
		return
	if event.is_action_pressed("interact") or event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_close_record()


func _exit_tree() -> void:
	if _is_open:
		_restore_runtime_state()


func _open_record() -> void:
	_ensure_reader()
	var database_entry := RecordDB.get_record(record_id)
	var display_category := _localized(category_tr, category_en)
	var display_title := _localized(title_tr, title_en)
	var display_body := _localized(body_tr, body_en)
	if not database_entry.is_empty():
		display_category = RecordDB.localized(database_entry, "category")
		display_title = RecordDB.localized(database_entry, "title")
		display_body = RecordDB.localized(database_entry, "body")

	_reader_category.text = display_category
	_reader_title.text = display_title
	_reader_body.text = display_body
	_reader_meta.text = _record_meta_text(database_entry)
	var already_archived := record_id != &"" and BaseManager.is_field_record_discovered(record_id)
	_reader_status.text = tr("FIELD_TERMINAL_UI_ARCHIVED" if already_archived else "FIELD_TERMINAL_UI_ARCHIVED_NEW")
	_reader_layer.visible = true
	_is_open = true
	_ignore_close_until_msec = Time.get_ticks_msec() + 120
	_previous_mouse_mode = Input.mouse_mode
	_was_tree_paused = get_tree().paused
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var newly_discovered := false
	if record_id != &"":
		newly_discovered = BaseManager.discover_field_record(record_id)
	_refresh_screen(true)
	if newly_discovered:
		DiscoveryOverlay.request(
			get_tree(),
			&"record",
			"KAYIT ÇÖZÜLDÜ",
			"RECORD DECODED",
			display_title
		)
	if not objective_after_read.is_empty():
		GameState.set_objective(objective_after_read)


func _close_record() -> void:
	if not _is_open:
		return
	_reader_layer.visible = false
	_is_open = false
	_restore_runtime_state()


func _restore_runtime_state() -> void:
	get_tree().paused = _was_tree_paused
	Input.mouse_mode = _previous_mouse_mode


func _ensure_reader() -> void:
	if _reader_layer != null:
		return

	_reader_layer = CanvasLayer.new()
	_reader_layer.name = "FieldRecordReader"
	_reader_layer.layer = 80
	_reader_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_reader_layer)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.82)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	_reader_layer.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(780.0, 480.0)
	panel.theme = READER_THEME
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.016, 0.03, 0.04, 0.97)
	panel_style.border_color = Color(0.24, 0.84, 1.0, 0.42)
	panel_style.set_border_width_all(1)
	panel_style.border_width_left = 4
	panel_style.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 26)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 26)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	margin.add_child(content)

	# Üst şerit: sistem adı solda, kayıt künyesi (bölüm · oda · numara) sağda.
	var header := HBoxContainer.new()
	content.add_child(header)
	var system_label := Label.new()
	system_label.text = tr("FIELD_TERMINAL_UI_HEADER")
	system_label.add_theme_font_override("font", READER_MONO)
	system_label.add_theme_font_size_override("font_size", 16)
	system_label.add_theme_color_override("font_color", READER_MUTED)
	system_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(system_label)
	_reader_meta = Label.new()
	_reader_meta.add_theme_font_override("font", READER_MONO)
	_reader_meta.add_theme_font_size_override("font_size", 16)
	_reader_meta.add_theme_color_override("font_color", READER_MUTED)
	_reader_meta.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_reader_meta)

	_reader_category = Label.new()
	_reader_category.add_theme_font_override("font", READER_MONO)
	_reader_category.add_theme_font_size_override("font_size", 17)
	_reader_category.add_theme_color_override("font_color", READER_ACCENT)
	content.add_child(_reader_category)

	_reader_title = Label.new()
	_reader_title.add_theme_font_override("font", READER_HEADING)
	_reader_title.add_theme_font_size_override("font_size", 28)
	_reader_title.custom_minimum_size = Vector2(700.0, 0.0)
	_reader_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_reader_title)

	var divider := ColorRect.new()
	divider.custom_minimum_size = Vector2(0.0, 2.0)
	divider.color = Color(READER_ACCENT, 0.55)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(divider)

	_reader_body = RichTextLabel.new()
	_reader_body.custom_minimum_size = Vector2(0.0, 300.0)
	_reader_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reader_body.fit_content = false
	_reader_body.scroll_active = true
	_reader_body.add_theme_font_size_override("normal_font_size", 18)
	_reader_body.add_theme_color_override("default_color", READER_BODY_COLOR)
	_reader_body.add_theme_constant_override("line_separation", 4)
	content.add_child(_reader_body)

	# Alt şerit: arşiv durumu solda, kapatma düğmesi sağda.
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	content.add_child(footer)
	_reader_status = Label.new()
	_reader_status.add_theme_font_override("font", READER_MONO)
	_reader_status.add_theme_font_size_override("font_size", 16)
	_reader_status.add_theme_color_override("font_color", SCREEN_DECODED_COLOR.darkened(0.15))
	_reader_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reader_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	footer.add_child(_reader_status)

	_close_button = Button.new()
	_close_button.text = tr("FIELD_TERMINAL_UI_CLOSE_E_ESC")
	_close_button.custom_minimum_size = Vector2(180.0, 46.0)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_button.pressed.connect(_close_record)
	footer.add_child(_close_button)


## Terminal ekranı: kayıt kategorisi, şifreli/çözüldü durumu ve saha künyesi.
func _refresh_screen(decoded_now := false) -> void:
	var entry := RecordDB.get_record(record_id)
	var category := _localized(category_tr, category_en)
	if not entry.is_empty():
		category = RecordDB.localized(entry, "category")
	var decoded := decoded_now
	if not decoded and record_id != &"" and not Engine.is_editor_hint():
		decoded = BaseManager.is_field_record_discovered(record_id)
	var state_color := SCREEN_DECODED_COLOR if decoded else SCREEN_ENCRYPTED_COLOR
	_set_label("HeaderLabel", tr("FIELD_TERMINAL_UI_HEADER"))
	_set_label("CategoryLabel", category)
	_set_label("StatusLabel", tr("FIELD_TERMINAL_UI_SCREEN_DECODED" if decoded else "FIELD_TERMINAL_UI_SCREEN_ENCRYPTED"), state_color)
	_set_label("MetaLabel", _screen_meta_text(entry))
	if _status_lamp_material != null:
		_status_lamp_material.albedo_color = state_color


func _set_label(node_name: String, text: String, color := Color(0, 0, 0, 0)) -> void:
	var label := get_node_or_null(node_name) as Label3D
	if label == null:
		return
	label.text = text
	if color.a > 0.0:
		label.modulate = color


func _screen_meta_text(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	return tr("FIELD_TERMINAL_UI_SCREEN_META") % [str(entry.get("room", "—")), int(entry.get("order", 0))]


func _record_meta_text(entry: Dictionary) -> String:
	if entry.is_empty():
		return ""
	return tr("FIELD_TERMINAL_UI_META") % [
		int(entry.get("chapter", 0)),
		str(entry.get("room", "—")),
		int(entry.get("order", 0)),
		RecordDB.TOTAL_CAMPAIGN_RECORDS,
	]


## Sahnede yazılı _tr/_en veri alanlarından birini seçer (çeviri anahtarı değil, veri kalıbı).
func _localized(tr_text: String, en_text: String) -> String:
	return en_text if TranslationServer.get_locale().to_lower().begins_with("en") else tr_text
