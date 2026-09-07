extends Node

signal archive_changed(enemy_id: StringName)

const SAVE_PATH := "user://vex_archive.cfg"
const SAVE_SECTION := "archive"
const SAVE_KEY := "discovered_enemy_ids"

var discovered_enemy_ids: Array[StringName] = []


func _ready() -> void:
	_load_archive()
	if not GameState.enemy_defeated.is_connected(_on_enemy_defeated):
		GameState.enemy_defeated.connect(_on_enemy_defeated)


func _on_enemy_defeated(enemy_id: StringName) -> void:
	discover_enemy(enemy_id)


func discover_enemy(enemy_id: StringName) -> bool:
	if enemy_id == &"" or discovered_enemy_ids.has(enemy_id):
		return false
	discovered_enemy_ids.append(enemy_id)
	_save_archive()
	archive_changed.emit(enemy_id)
	return true


func is_enemy_discovered(enemy_id: StringName) -> bool:
	return enemy_id != &"" and discovered_enemy_ids.has(enemy_id)


func get_discovered_enemy_ids() -> Array[StringName]:
	return discovered_enemy_ids.duplicate()


func get_discovered_count() -> int:
	return discovered_enemy_ids.size()


func _load_archive() -> void:
	discovered_enemy_ids.clear()
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	var stored: Variant = config.get_value(SAVE_SECTION, SAVE_KEY, [])
	if stored is PackedStringArray:
		for value: String in stored:
			var enemy_id := StringName(value)
			if enemy_id != &"" and not discovered_enemy_ids.has(enemy_id):
				discovered_enemy_ids.append(enemy_id)
	elif stored is Array:
		for value: Variant in stored:
			var enemy_id := StringName(str(value))
			if enemy_id != &"" and not discovered_enemy_ids.has(enemy_id):
				discovered_enemy_ids.append(enemy_id)


func _save_archive() -> void:
	var config := ConfigFile.new()
	var stored := PackedStringArray()
	for enemy_id: StringName in discovered_enemy_ids:
		stored.append(str(enemy_id))
	config.set_value(SAVE_SECTION, SAVE_KEY, stored)
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_warning("VEX archive discovery save failed. Error: %s" % error)
