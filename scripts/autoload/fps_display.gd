extends CanvasLayer

const SETTINGS_PATH := "user://vex_performance.cfg"
const SAMPLE_INTERVAL := 0.25

var enabled := false
var _sample_remaining := 0.0
var _root: Control
var _fps_label: Label


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	_build_ui()
	_load_setting()
	_sync_visibility()


func _process(delta: float) -> void:
	_sync_visibility()
	if not _root.visible:
		return
	_sample_remaining = maxf(0.0, _sample_remaining - delta)
	if _sample_remaining > 0.0:
		return
	_sample_remaining = SAMPLE_INTERVAL
	_fps_label.text = "FPS: %d" % int(round(Engine.get_frames_per_second()))


func set_enabled(value: bool) -> void:
	enabled = value
	_sample_remaining = 0.0
	_sync_visibility()
	_save_setting()


func _build_ui() -> void:
	_root = Control.new()
	_root.name = "FpsDisplayRoot"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_fps_label = Label.new()
	_fps_label.name = "FpsLabel"
	_fps_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_fps_label.offset_left = -150.0
	_fps_label.offset_top = 14.0
	_fps_label.offset_right = -18.0
	_fps_label.offset_bottom = 46.0
	_fps_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_fps_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fps_label.text = "FPS: --"
	_fps_label.add_theme_font_size_override("font_size", 19)
	_fps_label.add_theme_color_override("font_color", Color(0.72, 0.93, 1.0, 0.96))
	_fps_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
	_fps_label.add_theme_constant_override("outline_size", 5)
	_root.add_child(_fps_label)


func _sync_visibility() -> void:
	if _root == null:
		return
	_root.visible = enabled and _has_gameplay_player()


func _has_gameplay_player() -> bool:
	return GameState.player != null and is_instance_valid(GameState.player)


func _load_setting() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	enabled = bool(config.get_value("display", "show_fps", false))


func _save_setting() -> void:
	var config := ConfigFile.new()
	config.set_value("display", "show_fps", enabled)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_warning("FPS display setting could not be saved. Error code: %s" % error)
