@tool
extends Node3D
class_name VexRoomNameDisplay

@export_category("Display Content")
@export var room_name := "ROOM NAME":
	set(value):
		room_name = value
		_sync_text()
@export var header_text := "B-7 // LOCATION":
	set(value):
		header_text = value
		_sync_text()


func _ready() -> void:
	_sync_text()


func _sync_text() -> void:
	var room_label := get_node_or_null("RoomName") as Label3D
	if room_label != null:
		room_label.text = room_name
	var header_label := get_node_or_null("Header") as Label3D
	if header_label != null:
		header_label.text = header_text
