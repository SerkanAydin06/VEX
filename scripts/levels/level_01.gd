extends Node3D

@export_category("01 - Bölüm")
@export var map_revision := "VEX01-R26-PRO-AUTOMAP"
@export var level_display_name := "VEX-01 // KARANTİNA TESİSİ"
@export_range(0, 100, 1) var campaign_completion_stage := 1
@export var first_objective := "TESİSTE İLERLE"
@export_range(0, 20, 1) var total_secrets := 0
@export_range(0.0, 5.0, 0.05) var intro_message_delay := 0.5

@export_category("02 - Otomatik Harita")
@export var automap_title := "TESİS HARİTASI // VEX-01"
@export_range(1, 32, 1) var automap_columns := 3
@export_range(1, 32, 1) var automap_rows := 6
@export var automap_world_min := Vector2(-18.0, -30.0)
@export var automap_world_max := Vector2(18.0, 30.0)
@export var automap_walkable_cells: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5),
]
@export var automap_start_cell := Vector2i(0, 5)
@export var automap_exit_cell := Vector2i(2, 0)
@export var automap_merge_adjacent_cells := false
@export var automap_show_room_numbers := true

@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var ambient_loop: AudioStreamPlayer = $AmbientLoop


func _ready() -> void:
	SettingsManager.apply_brightness()
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	GameState.begin_level(enemy_count, total_secrets, first_objective)
	_start_audio_loop(level_music)
	_start_audio_loop(ambient_loop)
	_intro_message()


func _intro_message() -> void:
	await get_tree().create_timer(intro_message_delay).timeout
	if is_inside_tree():
		GameState.notify(
			"%s // ZORLUK: %s"
			% [level_display_name, GameState.get_active_difficulty_name()]
		)


func _start_audio_loop(audio_player: AudioStreamPlayer) -> void:
	if audio_player.stream == null:
		return
	var restart_callable := _restart_audio_loop.bind(audio_player)
	if not audio_player.finished.is_connected(restart_callable):
		audio_player.finished.connect(restart_callable)
	audio_player.play()


func _restart_audio_loop(audio_player: AudioStreamPlayer) -> void:
	if is_inside_tree() and is_instance_valid(audio_player) and audio_player.stream != null:
		audio_player.play()


func get_level_display_name() -> String:
	return level_display_name


func get_campaign_completion_stage() -> int:
	return campaign_completion_stage


func get_automap_config() -> Dictionary:
	return {
		"title": automap_title,
		"columns": automap_columns,
		"rows": automap_rows,
		"world_min": automap_world_min,
		"world_max": automap_world_max,
		"walkable_cells": automap_walkable_cells,
		"start_cell": automap_start_cell,
		"exit_cell": automap_exit_cell,
		"merge_adjacent_cells": automap_merge_adjacent_cells,
		"show_room_numbers": automap_show_room_numbers,
	}
