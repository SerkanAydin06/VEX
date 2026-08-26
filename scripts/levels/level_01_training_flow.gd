class_name VexLevel01TrainingFlow
extends Node3D

@export_category("01 - Muharebe Kapıları")
@export var gate_door_paths: Array[NodePath] = []
@export var gate_enemy_ids: Array[StringName] = []
@export var gate_display_name_keys: PackedStringArray = []
@export var gate_clear_objective_keys: PackedStringArray = []
@export var gate_indicator_paths: Array[NodePath] = []

@export_category("02 - Durum Işığı Değişimi")
@export var replaced_static_light_paths: Array[NodePath] = []

@export_category("03 - Protokol Tamamlama")
@export_range(-1, 16, 1) var protocol_completion_gate_index := -1
@export var protocol_complete_notification_key := "LEVEL01_TUTORIAL_COMPLETE_HINT"


func _ready() -> void:
	_hide_replaced_static_lights()
	_configure_combat_gates()
	if not GameState.enemy_defeated.is_connected(_on_enemy_defeated):
		GameState.enemy_defeated.connect(_on_enemy_defeated)


func _exit_tree() -> void:
	if GameState.enemy_defeated.is_connected(_on_enemy_defeated):
		GameState.enemy_defeated.disconnect(_on_enemy_defeated)


func _configure_combat_gates() -> void:
	var gate_count := mini(gate_door_paths.size(), gate_enemy_ids.size())
	for index in gate_count:
		var door := get_node_or_null(gate_door_paths[index]) as VexDoor
		if door == null:
			push_error("VEX-01 eğitim kapısı bulunamadı: %s" % gate_door_paths[index])
			continue

		var required_ids: Array[StringName] = []
		var enemy_id := gate_enemy_ids[index]
		if enemy_id != &"":
			required_ids.append(enemy_id)
		door.required_enemy_ids = required_ids

		if index < gate_display_name_keys.size() and not gate_display_name_keys[index].is_empty():
			door.display_name = gate_display_name_keys[index]

		# Kapı _ready() aşamasını daha önce tamamlamış olabilir. Combat kilidinin
		# gerçek otoritesi required_enemy_ids + GameState olduğundan burada yalnız
		# sahne verisini bağlarız; açılma bildirimi/indikasyonu bu akış tarafından
		# enemy_defeated sinyalinden deterministik olarak güncellenir.
		_set_gate_indicator(index, not GameState.was_enemy_defeated(enemy_id))


func _hide_replaced_static_lights() -> void:
	for light_path: NodePath in replaced_static_light_paths:
		var light := get_node_or_null(light_path) as Node3D
		if light == null:
			push_warning("VEX-01 değiştirilecek statik kapı ışığı bulunamadı: %s" % light_path)
			continue
		light.visible = false


func _on_enemy_defeated(enemy_id: StringName) -> void:
	for index in gate_enemy_ids.size():
		if gate_enemy_ids[index] != enemy_id:
			continue
		_set_gate_indicator(index, false)
		GameState.notify("DOOR_COMBAT_CLEARED")
		if index < gate_clear_objective_keys.size():
			var objective_key := gate_clear_objective_keys[index]
			if not objective_key.is_empty():
				GameState.set_objective(objective_key)
		if index == protocol_completion_gate_index and not protocol_complete_notification_key.is_empty():
			GameState.notify(protocol_complete_notification_key)
		return


func _set_gate_indicator(index: int, locked: bool) -> void:
	if index < 0 or index >= gate_indicator_paths.size():
		return
	var indicator_root := get_node_or_null(gate_indicator_paths[index]) as Node3D
	if indicator_root == null:
		push_warning("VEX-01 eğitim kapısı durum ışığı bulunamadı: %s" % gate_indicator_paths[index])
		return
	for child: Node in indicator_root.get_children():
		if not (child is Node3D):
			continue
		var indicator := child as Node3D
		if indicator.name.begins_with("Locked"):
			indicator.visible = locked
		elif indicator.name.begins_with("Unlocked"):
			indicator.visible = not locked
