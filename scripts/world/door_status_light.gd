@tool
class_name VexDoorStatusLight
extends Node3D

@export_category("Kapı Durumu")
@export var door_path: NodePath
@export var locked_preview := true:
	set(value):
		locked_preview = value
		if Engine.is_editor_hint():
			call_deferred("_apply_indicator_state", locked_preview)

var _door: Node


func _ready() -> void:
	if Engine.is_editor_hint():
		_apply_indicator_state(locked_preview)
		return

	_door = get_node_or_null(door_path)
	if _door != null and _door.has_signal("lock_state_changed"):
		var callback := Callable(self, "_on_lock_state_changed")
		if not _door.is_connected("lock_state_changed", callback):
			_door.connect("lock_state_changed", callback)
	call_deferred("_sync_from_door")


func _sync_from_door() -> void:
	var is_locked := locked_preview
	if _door != null and _door.has_method("is_access_locked"):
		is_locked = bool(_door.call("is_access_locked"))
	_apply_indicator_state(is_locked)


func _on_lock_state_changed(is_locked: bool) -> void:
	_apply_indicator_state(is_locked)


func _apply_indicator_state(is_locked: bool) -> void:
	var locked_lamp := get_node_or_null("Locked") as Node3D
	var unlocked_lamp := get_node_or_null("Unlocked") as Node3D
	if locked_lamp != null:
		locked_lamp.visible = is_locked
	if unlocked_lamp != null:
		unlocked_lamp.visible = not is_locked
