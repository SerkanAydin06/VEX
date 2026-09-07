class_name VexFieldRecordTerminal
extends StaticBody3D

const DiscoveryOverlay = preload("res://scripts/ui/discovery_notification_overlay.gd")
const RecordDB = preload("res://scripts/data/vex_field_record_database.gd")

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

var _reader_layer: CanvasLayer = null
var _reader_title: Label = null
var _reader_category: Label = null
var _reader_body: RichTextLabel = null
var _close_button: Button = null
var _is_open := false
var _previous_mouse_mode := Input.MOUSE_MODE_CAPTURED
var _was_tree_paused := false
var _ignore_close_until_msec := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


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
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	margin.add_child(content)

	_reader_category = Label.new()
	_reader_category.add_theme_font_size_override("font_size", 13)
	_reader_category.modulate = Color(0.45, 0.9, 1.0)
	content.add_child(_reader_category)

	_reader_title = Label.new()
	_reader_title.add_theme_font_size_override("font_size", 28)
	_reader_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(_reader_title)

	var divider := HSeparator.new()
	content.add_child(divider)

	_reader_body = RichTextLabel.new()
	_reader_body.custom_minimum_size = Vector2(0.0, 300.0)
	_reader_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_reader_body.fit_content = false
	_reader_body.scroll_active = true
	_reader_body.add_theme_font_size_override("normal_font_size", 17)
	content.add_child(_reader_body)

	_close_button = Button.new()
	_close_button.text = _localized("KAPAT  [E / ESC]", "CLOSE  [E / ESC]")
	_close_button.custom_minimum_size = Vector2(180.0, 46.0)
	_close_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	_close_button.pressed.connect(_close_record)
	content.add_child(_close_button)


func _localized(tr_text: String, en_text: String) -> String:
	return en_text if TranslationServer.get_locale().to_lower().begins_with("en") else tr_text
