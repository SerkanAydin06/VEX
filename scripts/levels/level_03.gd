@tool
extends VexBaseLevel

const STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_03_structure_source.tscn"
const STRUCTURE_NODE_NAMES := [
	&"WorldEnvironment",
	&"Geometry",
	&"Doors",
	&"Props",
	&"RoomLights",
	&"Lights",
]

var _alarm_triggered := false


func _get_structure_source_path() -> String:
	return STRUCTURE_SOURCE_PATH


func _get_structure_node_names() -> Array:
	return STRUCTURE_NODE_NAMES


func _configure_authored_doors(doors_root: Node) -> void:
	# Legacy combat gates and old key semantics must not leak from the structural
	# snapshot. Start every authored door from a neutral traversal state, then
	# apply the three canonical Pressure Line access gates below.
	_reset_authored_doors(doors_root)
	_configure_access_door(
		doors_root.get_node_or_null("Door_StairAccess"),
		"CH03_DOOR_STAIR_ACCESS",
		[&"blue"],
		"CH03_BLUE_AUTH",
		"CH03_OBJECTIVE_UPPER"
	)
	_configure_access_door(
		doors_root.get_node_or_null("Door_StairSecurity"),
		"CH03_DOOR_ARCHIVE_ACCESS",
		[&"yellow"],
		"CH03_YELLOW_AUTH",
		"CH03_OBJECTIVE_RED"
	)
	_configure_access_door(
		doors_root.get_node_or_null("Door_CoreAuthorization"),
		"CH03_DOOR_REACTOR_ACCESS",
		[&"red"],
		"CH03_RED_AUTH",
		"CH03_OBJECTIVE_RESCUE"
	)

	var final_service_door := doors_root.get_node_or_null("Door_RiftChamber") as VexDoor
	if final_service_door != null:
		final_service_door.display_name = "CH03_DOOR_EVAC_SERVICE"
		final_service_door.auto_close = false


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("CH03_OBJECTIVE_RESCUE")
	elif keys.has(&"yellow"):
		GameState.set_objective("CH03_OBJECTIVE_RED")
	elif keys.has(&"blue"):
		GameState.set_objective("CH03_OBJECTIVE_UPPER")


func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("CH03_GUNSHOT_ALARM")
