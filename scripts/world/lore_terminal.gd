class_name VexLoreTerminal
extends StaticBody3D

signal log_read(log_id: StringName)

@export_category("Saha Kaydı")
@export var log_id: StringName = &"lore_log"
@export var display_name := "VEX SAHA KAYDI"
@export var log_title := "KAYIT"
@export_multiline var log_body := "Kayıt verisi bulunamadı."
@export var accent_color := Color(0.25, 0.82, 1.0, 1.0)

var _read := false
var _overlay_open := false


func _ready() -> void:
	add_to_group("interactable")


func get_interaction_text(_player: Node) -> String:
	if _overlay_open:
		return ""
	return "[E] %s %s" % [display_name, "TEKRAR OKU" if _read else "OKU"]


func interact(_player: Node) -> void:
	if _overlay_open:
		return
	_show_log()


func _show_log() -> void:
	_overlay_open = true
	_read = true
	log_read.emit(log_id)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var overlay := CanvasLayer.new()
	overlay.name = "LoreOverlay"
	overlay.layer = 1100
	overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(root)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.9)
	root.add_child(shade)

	var panel := ColorRect.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.offset_left = -520.0
	panel.offset_top = -260.0
	panel.offset_right = 520.0
	panel.offset_bottom = 260.0
	panel.color = Color(0.025, 0.035, 0.045, 0.98)
	root.add_child(panel)

	var title := Label.new()
	title.position = Vector2(48, 38)
	title.size = Vector2(944, 58)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", accent_color)
	title.text = log_title
	panel.add_child(title)

	var divider := ColorRect.new()
	divider.position = Vector2(58, 108)
	divider.size = Vector2(924, 2)
	divider.color = accent_color
	panel.add_child(divider)

	var body := RichTextLabel.new()
	body.position = Vector2(62, 135)
	body.size = Vector2(916, 270)
	body.fit_content = false
	body.scroll_active = false
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.add_theme_font_size_override("normal_font_size", 23)
	body.add_theme_color_override("default_color", Color(0.9, 0.93, 0.96, 1.0))
	body.text = log_body
	panel.add_child(body)

	var prompt := Label.new()
	prompt.position = Vector2(48, 438)
	prompt.size = Vector2(944, 42)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 18)
	prompt.add_theme_color_override("font_color", Color(0.62, 0.68, 0.74, 1.0))
	prompt.text = "HERHANGİ BİR TUŞA BAS — KAYDI KAPAT"
	panel.add_child(prompt)

	await _wait_for_input_release()
	await _wait_for_input_press()
	await _wait_for_input_release()
	if is_instance_valid(overlay):
		overlay.queue_free()
	_overlay_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _input_active() -> bool:
	return Input.is_anything_pressed() or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)


func _wait_for_input_press() -> void:
	while not _input_active():
		await get_tree().process_frame


func _wait_for_input_release() -> void:
	while _input_active():
		await get_tree().process_frame
