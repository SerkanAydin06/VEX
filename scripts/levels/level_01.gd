extends Node3D

@export var map_revision := "VEX01-R26-PRO-AUTOMAP"
@export var level_display_name := "VEX-01 // KARANTİNA TESİSİ"
@export var first_objective := "İKİ ERİŞİM ANAHTARINI BUL"
@export_range(0, 20, 1) var total_secrets := 0

@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var ambient_loop: AudioStreamPlayer = $AmbientLoop

const AUTOMAP_WALKABLE_CELLS: Array[Vector2i] = [
	Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0),
	Vector2i(0, 1), Vector2i(1, 1), Vector2i(2, 1),
	Vector2i(0, 2), Vector2i(1, 2), Vector2i(2, 2),
	Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3),
	Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4),
	Vector2i(0, 5), Vector2i(1, 5), Vector2i(2, 5),
]

const AUTOMAP_DOOR_CONNECTIONS: Array[Dictionary] = [
	{"from": Vector2i(0, 0), "to": Vector2i(1, 0), "door": NodePath("Doors/Door_1_2")},
	{"from": Vector2i(0, 1), "to": Vector2i(1, 1), "door": NodePath("Doors/Door_4_5")},
	{"from": Vector2i(1, 1), "to": Vector2i(2, 1), "door": NodePath("Doors/Door_5_6")},
	{"from": Vector2i(0, 2), "to": Vector2i(1, 2), "door": NodePath("Doors/Door_7_8")},
	{"from": Vector2i(1, 2), "to": Vector2i(2, 2), "door": NodePath("Doors/Door_8_9")},
	{"from": Vector2i(0, 4), "to": Vector2i(1, 4), "door": NodePath("Doors/Door_13_14")},
	{"from": Vector2i(1, 4), "to": Vector2i(2, 4), "door": NodePath("Doors/Door_14_15")},
	{"from": Vector2i(0, 5), "to": Vector2i(1, 5), "door": NodePath("Doors/Door_16_17")},
	{"from": Vector2i(1, 0), "to": Vector2i(1, 1), "door": NodePath("Doors/Door_2_5")},
	{"from": Vector2i(2, 0), "to": Vector2i(2, 1), "door": NodePath("Doors/Door_3_6")},
	{"from": Vector2i(0, 1), "to": Vector2i(0, 2), "door": NodePath("Doors/Door_4_7")},
	{"from": Vector2i(1, 1), "to": Vector2i(1, 2), "door": NodePath("Doors/Door_5_8")},
	{"from": Vector2i(2, 1), "to": Vector2i(2, 2), "door": NodePath("Doors/Door_6_9")},
	{"from": Vector2i(0, 2), "to": Vector2i(0, 3), "door": NodePath("Doors/Door_7_10")},
	{"from": Vector2i(1, 2), "to": Vector2i(1, 3), "door": NodePath("Doors/Door_8_11")},
	{"from": Vector2i(2, 2), "to": Vector2i(2, 3), "door": NodePath("Doors/Door_9_12")},
	{"from": Vector2i(1, 3), "to": Vector2i(1, 4), "door": NodePath("Doors/Door_11_14")},
	{"from": Vector2i(1, 4), "to": Vector2i(1, 5), "door": NodePath("Doors/Door_14_17")},
	{"from": Vector2i(2, 4), "to": Vector2i(2, 5), "door": NodePath("Doors/Door_15_18")},
]


func _ready() -> void:
	SettingsManager.apply_brightness()
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	GameState.begin_level(enemy_count, total_secrets, first_objective)
	_start_audio_loop(level_music)
	_start_audio_loop(ambient_loop)
	_intro_message()


func _intro_message() -> void:
	await get_tree().create_timer(0.5).timeout
	if is_inside_tree():
		GameState.notify(
			"VEX-01 // KARANTİNA TESİSİ // ZORLUK: %s"
			% GameState.get_active_difficulty_name()
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


func get_automap_config() -> Dictionary:
	return {
		"title": "TESİS HARİTASI // VEX-01",
		"columns": 3,
		"rows": 6,
		"world_min": Vector2(-18.0, -30.0),
		"world_max": Vector2(18.0, 30.0),
		"walkable_cells": AUTOMAP_WALKABLE_CELLS,
		"door_connections": AUTOMAP_DOOR_CONNECTIONS,
		"start_cell": Vector2i(0, 5),
		"exit_cell": Vector2i(2, 0),
		"merge_adjacent_cells": false,
		"show_room_numbers": true,
	}
