class_name VexRecordManager
extends Node

signal record_changed(record_id: StringName)

const RecordDB = preload("res://scripts/data/vex_field_record_database.gd")
const ArchiveBridgeScript = preload("res://scripts/ui/field_record_archive_bridge.gd")

var discovered_record_ids: Array[StringName] = []


func _ready() -> void:
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	call_deferred("_attach_existing_archive_terminal")


func discover_record(record_id: StringName) -> bool:
	if record_id == &"" or discovered_record_ids.has(record_id):
		return false
	if not RecordDB.has_record(record_id):
		push_warning("VEX saha kaydı veritabanında bulunamadı: %s" % str(record_id))
		return false

	# Kayıt keşfi görev içi checkpoint değildir. Bu nedenle metadata yazarken
	# oyuncunun o anki state'i değil, level girişinde yakalanmış güvenli state kullanılır.
	# Böylece ölüm/Continue görevi baştan açarken keşfedilmiş kayıt korunur.
	if GameState.current_level_start_state.is_empty():
		push_warning("VEX saha kaydı güvenli görev başlangıcı yakalanmadan kaydedilemedi: %s" % str(record_id))
		GameState.notify(GameState.get_save_failure_message())
		return false

	discovered_record_ids.append(record_id)
	record_changed.emit(record_id)
	if not GameState.save_campaign_progress(
		GameState.current_level_path,
		GameState.current_level_start_state,
		"field_record"
	):
		discovered_record_ids.erase(record_id)
		record_changed.emit(record_id)
		GameState.notify(GameState.get_save_failure_message())
		return false
	return true


func is_record_discovered(record_id: StringName) -> bool:
	return record_id != &"" and discovered_record_ids.has(record_id)


func get_discovered_record_ids() -> Array[StringName]:
	var result := discovered_record_ids.duplicate()
	result.sort_custom(func(a: StringName, b: StringName) -> bool:
		var entry_a := RecordDB.get_record(a)
		var entry_b := RecordDB.get_record(b)
		return int(entry_a.get("order", 0)) < int(entry_b.get("order", 0))
	)
	return result


func get_discovered_count() -> int:
	return discovered_record_ids.size()


func capture_state() -> Dictionary:
	return {
		"discovered_record_ids": discovered_record_ids.duplicate(),
	}


func restore_state(state: Dictionary) -> void:
	discovered_record_ids.clear()
	var stored: Variant = state.get("discovered_record_ids", [])
	if stored is PackedStringArray:
		for value: String in stored:
			_add_restored_record(StringName(value))
	elif stored is Array:
		for value: Variant in stored:
			_add_restored_record(StringName(str(value)))
	record_changed.emit(&"")


func reset_campaign_state() -> void:
	if discovered_record_ids.is_empty():
		return
	discovered_record_ids.clear()
	record_changed.emit(&"")


func _add_restored_record(record_id: StringName) -> void:
	if record_id == &"" or discovered_record_ids.has(record_id):
		return
	if not RecordDB.has_record(record_id):
		return
	discovered_record_ids.append(record_id)


func _on_tree_node_added(node: Node) -> void:
	if node == null or node.name != "VexArchiveTerminal":
		return
	call_deferred("_attach_archive_bridge", node)


func _attach_existing_archive_terminal() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	var terminal := current_scene.find_child("VexArchiveTerminal", true, false)
	if terminal != null:
		_attach_archive_bridge(terminal)


func _attach_archive_bridge(terminal: Node) -> void:
	if terminal == null or not is_instance_valid(terminal):
		return
	if terminal.get_node_or_null("FieldRecordArchiveBridge") != null:
		return
	var bridge := ArchiveBridgeScript.new() as VexFieldRecordArchiveBridge
	if bridge == null:
		push_warning("VEX saha kayıt arşiv köprüsü oluşturulamadı.")
		return
	bridge.name = "FieldRecordArchiveBridge"
	terminal.add_child(bridge)
