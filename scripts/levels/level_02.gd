extends Node3D

@export_category("01 - Bölüm")
@export var map_revision := "VEX02-R47-MODULAR-STANDARD"
@export var level_display_name := "VEX-02 // KIRIK OMURGA"
@export_range(0, 100, 1) var campaign_completion_stage := 2
@export var first_objective := "BATI KANADINI ARA"
@export_multiline var story_intro_message := "VEX-01 kaydından sonra Bastion-7, VEX-02 içinde aktif bir güvenlik ağı tespit etti. Batı kanadını araştır; erişim zincirini tamamla ve tahliye odasına ulaş."
@export_range(0, 20, 1) var total_secrets := 2
@export_range(0.0, 5.0, 0.05) var intro_message_delay := 0.5

@export_category("02 - Otomatik Harita")
@export var automap_title := "TESİS HARİTASI // VEX-02"
@export_range(1, 32, 1) var automap_columns := 9
@export_range(1, 32, 1) var automap_rows := 7
@export var automap_world_min := Vector2(-54.0, -35.0)
@export var automap_world_max := Vector2(54.0, 35.0)
@export var automap_walkable_cells: Array[Vector2i] = [Vector2i(1, 0), Vector2i(2, 0), Vector2i(7, 0), Vector2i(1, 1), Vector2i(2, 1), Vector2i(3, 1), Vector2i(6, 1), Vector2i(7, 1), Vector2i(0, 2), Vector2i(1, 2), Vector2i(3, 2), Vector2i(6, 2), Vector2i(0, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(5, 3), Vector2i(6, 3), Vector2i(7, 3), Vector2i(8, 3), Vector2i(0, 4), Vector2i(1, 4), Vector2i(2, 4), Vector2i(7, 4), Vector2i(8, 4), Vector2i(0, 5), Vector2i(1, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5), Vector2i(6, 6), Vector2i(7, 6), Vector2i(8, 6)]
@export var automap_start_cell := Vector2i(4, 3)
@export var automap_exit_cell := Vector2i(8, 6)
@export var automap_merge_adjacent_cells := true
@export var automap_show_room_numbers := false

@onready var level_music: AudioStreamPlayer = $LevelMusic
@onready var ambient_loop: AudioStreamPlayer = $AmbientLoop
var _alarm_triggered := false

func _ready() -> void:
	SettingsManager.apply_brightness()
	if not GameState.key_inventory_changed.is_connected(_on_key_inventory_changed):
		GameState.key_inventory_changed.connect(_on_key_inventory_changed)
	var enemy_count := get_tree().get_nodes_in_group("enemy").size()
	GameState.begin_level(enemy_count, total_secrets, first_objective)
	_start_audio_loop(level_music)
	_start_audio_loop(ambient_loop)
	_intro_message()
	var noise_bus := get_node_or_null("/root/VexNoiseManager")
	if noise_bus != null and not noise_bus.noise_emitted.is_connected(_on_noise_emitted):
		noise_bus.noise_emitted.connect(_on_noise_emitted)

func _intro_message() -> void:
	await get_tree().create_timer(intro_message_delay).timeout
	if is_inside_tree():
		GameState.notify(story_intro_message)
		await get_tree().create_timer(1.8).timeout
		if is_inside_tree():
			GameState.notify("%s // ZORLUK: %s" % [level_display_name, GameState.get_active_difficulty_name()])

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


func _on_noise_emitted(_position: Vector3, _radius: float, noise_type: StringName, source: Node) -> void:
	if _alarm_triggered or noise_type != &"gunshot" or source == null:
		return
	_alarm_triggered = true
	GameState.notify("VEX-02 // GÜVENLİK ALARMI: SİLAH SESİ TESPİT EDİLDİ")
	GameState.set_objective("GÜVENLİK AĞINI AŞ // SARI ERİŞİM KARTINI BUL")


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"yellow"):
		GameState.set_objective("SARI ERİŞİM KARTI ALINDI // REAKTÖR BÖLME KAPISINA İLERLE")
	elif keys.has(&"red"):
		GameState.set_objective("KIRMIZI ERİŞİM KARTI ALINDI // TAHLİYE HAVA KİLİDİNE İLERLE")

