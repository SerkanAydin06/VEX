@tool
class_name VexBaseLevel
extends Node3D

@export_category("01 - Bölüm")
@export var map_revision := "VEX-LEVEL-CANONICAL"
@export var level_display_name := "VEX"
@export_range(0, 100, 1) var campaign_completion_stage := 0
@export var first_objective := ""
@export_multiline var briefing_story := ""
@export var briefing_objective := ""
@export_range(0, 20, 1) var total_secrets := 0
@export_range(0.01, 0.1, 0.005) var briefing_character_delay := 0.028
@export_range(0.1, 3.0, 0.05) var briefing_start_delay := 0.45

@export_category("02 - Otomatik Harita")
@export var automap_title := "VEX MAP"
@export_range(1, 32, 1) var automap_columns := 1
@export_range(1, 32, 1) var automap_rows := 1
@export var automap_world_min := Vector2(-1.0, -1.0)
@export var automap_world_max := Vector2(1.0, 1.0)
@export var automap_walkable_cells: Array[Vector2i] = [Vector2i.ZERO]
@export var automap_start_cell := Vector2i.ZERO
@export var automap_exit_cell := Vector2i.ZERO
@export var automap_merge_adjacent_cells := true
@export var automap_show_room_numbers := false

@onready var level_music: AudioStreamPlayer = get_node_or_null("LevelMusic") as AudioStreamPlayer
@onready var ambient_loop: AudioStreamPlayer = get_node_or_null("AmbientLoop") as AudioStreamPlayer

var _opening_briefing_active := false
var _briefing_reveal_requested := false


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	SettingsManager.apply_brightness()
	if not GameState.key_inventory_changed.is_connected(_on_key_inventory_changed):
		GameState.key_inventory_changed.connect(_on_key_inventory_changed)
	if not GameState.gunshot_emitted.is_connected(_on_gunshot_emitted):
		GameState.gunshot_emitted.connect(_on_gunshot_emitted)
	GameState.begin_level(get_tree().get_nodes_in_group("enemy").size(), total_secrets, first_objective)
	_clear_opening_projectiles()
	_start_audio_loop(level_music)
	_start_audio_loop(ambient_loop)
	_on_level_ready()
	_show_briefing()


func _on_level_ready() -> void:
	pass


func _on_key_inventory_changed(_keys: Array[StringName]) -> void:
	pass


func _on_gunshot_emitted(_position: Vector3, _loudness: float, _source: Node) -> void:
	pass


func _clear_opening_projectiles() -> void:
	for projectile in get_tree().get_nodes_in_group("projectile"):
		if is_instance_valid(projectile):
			projectile.queue_free()


func _start_audio_loop(audio_player: AudioStreamPlayer) -> void:
	if audio_player == null or audio_player.stream == null:
		return
	var restart_callable := _restart_audio_loop.bind(audio_player)
	if not audio_player.finished.is_connected(restart_callable):
		audio_player.finished.connect(restart_callable)
	audio_player.play()


func _restart_audio_loop(audio_player: AudioStreamPlayer) -> void:
	if is_inside_tree() and is_instance_valid(audio_player) and audio_player.stream != null:
		audio_player.play()


func get_level_display_name() -> String:
	return tr(level_display_name)


func get_campaign_completion_stage() -> int:
	return campaign_completion_stage


func get_automap_config() -> Dictionary:
	var ordered_cells: Array[Vector2i] = automap_walkable_cells.duplicate()
	var start_index := ordered_cells.find(automap_start_cell)
	var exit_index := ordered_cells.find(automap_exit_cell)
	# Oda numarası harita dosyasındaki fiziksel grid indeksinden değil görev
	# başlangıcından çıkışa doğru okunur. Eski sahnelerde hücre listesi ters yönde
	# tutulmuş olsa bile Inspector verisini değiştirmeden doğru 01..N sırası sağlanır.
	if start_index >= 0 and exit_index >= 0 and start_index > exit_index:
		ordered_cells.reverse()
	return {
		"title": automap_title,
		"columns": automap_columns,
		"rows": automap_rows,
		"world_min": automap_world_min,
		"world_max": automap_world_max,
		"walkable_cells": ordered_cells,
		"start_cell": automap_start_cell,
		"exit_cell": automap_exit_cell,
		"merge_adjacent_cells": automap_merge_adjacent_cells,
		"show_room_numbers": automap_show_room_numbers,
	}


func _show_briefing() -> void:
	_opening_briefing_active = true
	_briefing_reveal_requested = false
	var briefing := CanvasLayer.new()
	briefing.name = "LevelBriefing"
	briefing.layer = 1000
	briefing.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(briefing)

	var root := Control.new()
	root.name = "Root"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	briefing.add_child(root)

	var blackout := ColorRect.new()
	blackout.name = "Blackout"
	blackout.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	blackout.color = Color.BLACK
	root.add_child(blackout)

	var location := Label.new()
	location.name = "MissionHeader"
	location.set_anchors_preset(Control.PRESET_TOP_WIDE)
	location.offset_left = 100.0
	location.offset_top = 90.0
	location.offset_right = -100.0
	location.offset_bottom = 150.0
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	location.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	location.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	location.add_theme_font_size_override("font_size", 30)
	location.add_theme_color_override("font_color", Color(0.55, 0.82, 1.0, 1.0))
	location.text = tr(level_display_name)
	root.add_child(location)

	var story := RichTextLabel.new()
	story.name = "Story"
	story.set_anchors_preset(Control.PRESET_CENTER)
	story.offset_left = -520.0
	story.offset_top = -135.0
	story.offset_right = 520.0
	story.offset_bottom = 95.0
	story.fit_content = false
	story.scroll_active = false
	story.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	story.add_theme_font_size_override("normal_font_size", 25)
	story.add_theme_color_override("default_color", Color(0.93, 0.95, 0.98, 1.0))
	story.text = tr(briefing_story)
	story.visible_characters = 0
	root.add_child(story)

	var objective := Label.new()
	objective.name = "Objective"
	objective.set_anchors_preset(Control.PRESET_CENTER)
	objective.offset_left = -520.0
	objective.offset_top = 125.0
	objective.offset_right = 520.0
	objective.offset_bottom = 185.0
	objective.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	objective.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective.add_theme_font_size_override("font_size", 24)
	objective.add_theme_color_override("font_color", Color(0.78, 0.88, 0.96, 1.0))
	objective.text = tr(briefing_objective)
	objective.visible_characters = 0
	root.add_child(objective)

	var prompt := Label.new()
	prompt.name = "ContinuePrompt"
	prompt.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	prompt.offset_left = 100.0
	prompt.offset_top = -115.0
	prompt.offset_right = -100.0
	prompt.offset_bottom = -55.0
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	prompt.add_theme_font_size_override("font_size", 20)
	prompt.add_theme_color_override("font_color", Color(0.68, 0.74, 0.80, 1.0))
	prompt.text = tr("BRIEFING_CONTINUE")
	prompt.modulate.a = 0.0
	root.add_child(prompt)

	var locked_nodes: Array[Dictionary] = []
	for actor in get_tree().get_nodes_in_group("player") + get_tree().get_nodes_in_group("enemy"):
		if actor is Node:
			locked_nodes.append({
				"node": actor,
				"process": actor.is_processing(),
				"physics": actor.is_physics_processing(),
				"input": actor.is_processing_input(),
				"unhandled": actor.is_processing_unhandled_input(),
				"unhandled_key": actor.is_processing_unhandled_key_input(),
				"process_mode": actor.process_mode,
			})
			actor.set_process(false)
			actor.set_physics_process(false)
			actor.set_process_input(false)
			actor.set_process_unhandled_input(false)
			actor.set_process_unhandled_key_input(false)
			actor.process_mode = Node.PROCESS_MODE_DISABLED

	# Scene değişiminden taşınan basılı hareket/ateş girdisini yeni bir briefing
	# basışı sayma. Oyuncu önce tuşu bırakmalı; sonraki basış normal şekilde işler.
	await _wait_for_continue_release()
	await get_tree().create_timer(briefing_start_delay, true, false, true).timeout
	await _type_text(story, briefing_character_delay)
	if not _briefing_reveal_requested:
		await _type_text(objective, briefing_character_delay)
	else:
		objective.visible_characters = -1
	if _briefing_reveal_requested:
		await _wait_for_continue_release()

	var blink := create_tween()
	blink.set_loops()
	blink.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	blink.tween_property(prompt, "modulate:a", 1.0, 0.45)
	blink.tween_property(prompt, "modulate:a", 0.25, 0.45)
	await _wait_for_continue()
	blink.kill()

	prompt.visible = false
	location.visible = false
	story.visible = false
	objective.visible = false
	await _wait_for_continue_release()

	var reveal := create_tween()
	reveal.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	reveal.tween_property(blackout, "color:a", 0.0, 1.15)
	await reveal.finished

	_opening_briefing_active = false
	for entry in locked_nodes:
		var actor: Node = entry["node"]
		if not is_instance_valid(actor):
			continue
		actor.process_mode = entry["process_mode"]
		actor.set_process(entry["process"])
		actor.set_physics_process(entry["physics"])
		actor.set_process_input(entry["input"])
		actor.set_process_unhandled_input(entry["unhandled"])
		actor.set_process_unhandled_key_input(entry["unhandled_key"])

	GameState.notify(tr("LEVEL_DIFFICULTY_NOTICE") % [tr(level_display_name), GameState.get_active_difficulty_name()])
	briefing.queue_free()


func _type_text(label: Variant, delay: float) -> void:
	label.visible_characters = 0
	for index in range(label.text.length()):
		if not is_instance_valid(label):
			return
		if _is_briefing_continue_pressed():
			_briefing_reveal_requested = true
			label.visible_characters = -1
			return
		label.visible_characters = index + 1
		await get_tree().create_timer(delay, true, false, true).timeout


func _is_briefing_continue_pressed() -> bool:
	return Input.is_anything_pressed() \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) \
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE)


func _wait_for_continue() -> void:
	while not _is_briefing_continue_pressed():
		await get_tree().process_frame


func _wait_for_continue_release() -> void:
	while _is_briefing_continue_pressed():
		await get_tree().process_frame
