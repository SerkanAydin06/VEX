class_name VexDiscoveryNotificationOverlay
extends CanvasLayer

const SCENE_PATH := "res://scenes/ui/discovery_notification_overlay.tscn"

@export_range(0.05, 1.0, 0.05) var slide_time := 0.22
@export_range(1.0, 8.0, 0.1) var hold_time := 4.0
@export_range(0.05, 1.5, 0.05) var fade_time := 0.35
@export_range(0.0, 100.0, 1.0) var slide_distance := 28.0

@onready var card: PanelContainer = %Card
@onready var accent: ColorRect = %Accent
@onready var category_label: Label = %Category
@onready var title_label: Label = %Title
@onready var subtitle_label: Label = %Subtitle

var _queue: Array[Dictionary] = []
var _showing := false
var _rest_position := Vector2.ZERO
var _active_tween: Tween = null


static func request(
	tree: SceneTree,
	category: StringName,
	title_tr: String,
	title_en: String,
	subtitle: String
) -> void:
	if tree == null:
		return
	var overlay := tree.get_first_node_in_group(&"discovery_notification_overlay") as VexDiscoveryNotificationOverlay
	if overlay == null:
		var packed := load(SCENE_PATH) as PackedScene
		if packed == null:
			push_warning("VEX discovery notification scene yüklenemedi.")
			return
		overlay = packed.instantiate() as VexDiscoveryNotificationOverlay
		if overlay == null:
			push_warning("VEX discovery notification scene instantiate edilemedi.")
			return
		tree.root.add_child(overlay)
	overlay.enqueue(category, title_tr, title_en, subtitle)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group(&"discovery_notification_overlay")
	_rest_position = card.position
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE


func enqueue(
	category: StringName,
	title_tr: String,
	title_en: String,
	subtitle: String
) -> void:
	_queue.append({
		"category": category,
		"title_tr": title_tr,
		"title_en": title_en,
		"subtitle": subtitle,
	})
	if not _showing:
		call_deferred("_show_next")


func _show_next() -> void:
	if _showing or _queue.is_empty() or not is_inside_tree():
		return
	_showing = true
	var entry := _queue.pop_front() as Dictionary
	var category := StringName(str(entry.get("category", "info")))
	var title_tr := str(entry.get("title_tr", "VEX BİLGİ GÜNCELLENDİ"))
	var title_en := str(entry.get("title_en", "VEX DATA UPDATED"))
	var subtitle := str(entry.get("subtitle", ""))

	_apply_category(category)
	category_label.text = _category_text(category)
	title_label.text = title_en if _is_english() else title_tr
	subtitle_label.text = subtitle

	if _active_tween != null and _active_tween.is_valid():
		_active_tween.kill()
	card.position = _rest_position + Vector2(0.0, -slide_distance)
	card.modulate.a = 0.0
	card.visible = true

	_active_tween = create_tween()
	_active_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_active_tween.tween_property(card, "position", _rest_position, slide_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_active_tween.parallel().tween_property(card, "modulate:a", 1.0, minf(slide_time, 0.16))
	_active_tween.tween_interval(hold_time)
	_active_tween.tween_property(card, "modulate:a", 0.0, fade_time)
	await _active_tween.finished

	if not is_inside_tree():
		return
	card.visible = false
	card.position = _rest_position
	_showing = false
	if not _queue.is_empty():
		call_deferred("_show_next")


func _apply_category(category: StringName) -> void:
	match category:
		&"weapon":
			accent.color = Color(1.0, 0.36, 0.12, 1.0)
			category_label.modulate = Color(1.0, 0.62, 0.34, 1.0)
		&"xeno":
			accent.color = Color(0.18, 0.86, 1.0, 1.0)
			category_label.modulate = Color(0.42, 0.92, 1.0, 1.0)
		&"record":
			accent.color = Color(0.66, 0.48, 1.0, 1.0)
			category_label.modulate = Color(0.78, 0.68, 1.0, 1.0)
		_:
			accent.color = Color(0.32, 0.82, 0.94, 1.0)
			category_label.modulate = Color(0.52, 0.88, 0.96, 1.0)


func _category_text(category: StringName) -> String:
	match category:
		&"weapon":
			return "VEX // WEAPON ARCHIVE" if _is_english() else "VEX // SİLAH ARŞİVİ"
		&"xeno":
			return "VEX // XENO ARCHIVE" if _is_english() else "VEX // XENO ARŞİVİ"
		&"record":
			return "VEX // FIELD RECORD" if _is_english() else "VEX // SAHA KAYDI"
	return "VEX // DATA"


func _is_english() -> bool:
	return TranslationServer.get_locale().to_lower().begins_with("en")
