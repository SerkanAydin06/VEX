class_name VexLevel01TrainingFlow
extends Node3D

@export_category("01 - Muharebe Kapıları")
@export var gate_door_paths: Array[NodePath] = []
@export var gate_enemy_ids: Array[StringName] = []
@export var gate_display_name_keys: PackedStringArray = []
@export var gate_clear_objective_keys: PackedStringArray = []

@export_category("02 - Değiştirilen Statik Işıklar")
@export var replaced_static_light_paths: Array[NodePath] = []


func _ready() -> void:
	_hide_replaced_static_lights()
	_configure_combat_gates()


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
		if index < gate_clear_objective_keys.size():
			door.objective_on_combat_clear = gate_clear_objective_keys[index]

		# Overlay child sahnesi ana Level 1 ağacına _ready sonrasında eklenir.
		# Bu nedenle kapının mevcut combat-lock cache'ini sahne verisi bağlandıktan
		# sonra bir kez yenileriz. Bundan sonraki tüm açılma ve sinyal davranışı
		# canonical VexDoor içinde kalır.
		door._combat_lock_was_active = door._has_active_combat_lock()
		door._emit_lock_state()


func _hide_replaced_static_lights() -> void:
	for light_path: NodePath in replaced_static_light_paths:
		var light := get_node_or_null(light_path) as Node3D
		if light == null:
			push_warning("VEX-01 değiştirilecek statik kapı ışığı bulunamadı: %s" % light_path)
			continue
		light.visible = false
