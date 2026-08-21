class_name VexBastion7
extends Node3D

@export_category("01 - Üs")
@export var hub_display_name := "BASTION-7 // VEX ANA ÜSSÜ"
@export var first_objective := "OPERASYON TERMİNALİNİ KULLAN"
@export_range(0.0, 5.0, 0.05) var intro_message_delay := 0.45
@export var arrival_message := "BASTION-7 // GÜVENLİ BÖLGE"
@export var allow_weapon_fire := false

@export_category("02 - Otomatik Harita")
@export var automap_title := "BASTION-7 // ÜS HARİTASI"
@export_range(1, 32, 1) var automap_columns := 5
@export_range(1, 32, 1) var automap_rows := 7
@export var automap_world_min := Vector2(-30.0, -35.0)
@export var automap_world_max := Vector2(30.0, 35.0)
@export var automap_walkable_cells: Array[Vector2i] = []
@export var automap_start_cell := Vector2i(2, 6)
@export var automap_exit_cell := Vector2i(2, 0)
@export var automap_merge_adjacent_cells := false
@export var automap_show_room_numbers := false

@export_category("03 - Ses")
@export_range(-40.0, 6.0, 0.5) var ambience_volume_db := -12.0

@export_category("04 - Campaign")
@export var mission_paths: PackedStringArray = []
@export var mission_labels: PackedStringArray = []
@export var mission_definitions: Array[VexMissionDefinition] = []

@onready var ambient_loop: AudioStreamPlayer = $AmbientLoop


func _ready() -> void:
	SettingsManager.apply_brightness()
	GameState.begin_level(0, 0, first_objective)
	_apply_safe_zone_rules()
	ambient_loop.volume_db = ambience_volume_db
	_start_audio_loop(ambient_loop)
	_intro_message()


func _apply_safe_zone_rules() -> void:
	if allow_weapon_fire:
		return
	if GameState.player == null or not is_instance_valid(GameState.player):
		return
	var controller := GameState.player.get_node_or_null("WeaponController")
	if controller != null:
		controller.set_process(false)


func _intro_message() -> void:
	await get_tree().create_timer(intro_message_delay).timeout
	if not is_inside_tree():
		return
	GameState.notify(arrival_message)
	await get_tree().create_timer(0.9).timeout
	if not is_inside_tree():
		return
	if GameState.campaign_stage >= 2:
		GameState.notify("OPERASYON TAMAMLANDI // VEX-02 KAYDI BASTION-7'YE AKTARILDI")
		GameState.set_objective(first_objective)
	elif GameState.campaign_stage >= 1:
		GameState.notify("VEX-01 TAMAMLANDI // VEX-02 OPERASYONU HAZIR")
		GameState.set_objective(first_objective)
	else:
		GameState.set_objective(first_objective)


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
	return hub_display_name


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


func _get_active_mission_definition() -> VexMissionDefinition:
	var index := GameState.campaign_stage
	if index < 0 or index >= mission_definitions.size():
		return null
	return mission_definitions[index]


func get_next_mission_path() -> String:
	var definition := _get_active_mission_definition()
	if definition != null and not definition.scene_path.is_empty():
		return definition.scene_path
	var index := GameState.campaign_stage
	if index < 0 or index >= mission_paths.size():
		return ""
	return mission_paths[index]


func get_next_mission_label() -> String:
	var definition := _get_active_mission_definition()
	if definition != null and not definition.display_name.is_empty():
		return definition.display_name
	var index := GameState.campaign_stage
	if index < 0 or index >= mission_labels.size():
		return "YENİ OPERASYON BEKLENİYOR"
	return mission_labels[index]


func get_next_mission_briefing() -> String:
	var definition := _get_active_mission_definition()
	if definition != null:
		return definition.briefing
	return "OPERASYON BRİFİNGİ YÜKLENEMEDİ."
