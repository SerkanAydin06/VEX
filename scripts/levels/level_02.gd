@tool
extends VexBaseLevel

const STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_02_structure_source.tscn"
const STRUCTURE_NODE_NAMES := [
	&"WorldEnvironment",
	&"Geometry",
	&"EnemyNavigation",
	&"Doors",
	&"RoomLights",
	&"Lights",
	&"Props",
]

var _alarm_triggered := false


func _get_structure_source_path() -> String:
	return STRUCTURE_SOURCE_PATH


func _get_structure_node_names() -> Array:
	return STRUCTURE_NODE_NAMES


func _configure_authored_doors(doors_root: Node) -> void:
	# D05 final airlock stays a free traversal door; the four fuse doors gate the route.
	_reset_authored_doors(doors_root)
	_configure_access_door(
		doors_root.get_node_or_null("D01_Door"),
		"CH02_DOOR_BLUE_SHORTCUT",
		[&"blue"],
		"CH02_BLUE_FUSE",
		"CH02_OBJECTIVE_BLUE"
	)
	_configure_access_door(
		doors_root.get_node_or_null("D02_Door"),
		"CH02_DOOR_THERMAL_BULKHEAD",
		[&"yellow"],
		"CH02_YELLOW_FUSE",
		"CH02_OBJECTIVE_YELLOW"
	)
	_configure_access_door(
		doors_root.get_node_or_null("D03_Door"),
		"CH02_DOOR_EAST_TRANSFER",
		[&"blue"],
		"CH02_BLUE_FUSE",
		"CH02_OBJECTIVE_BLUE"
	)
	_configure_access_door(
		doors_root.get_node_or_null("D04_Door"),
		"CH02_DOOR_ISOLATION_LOCK",
		[&"red"],
		"CH02_RED_FUSE",
		"CH02_OBJECTIVE_RED"
	)
	var final_airlock := doors_root.get_node_or_null("D05_Door") as VexDoor
	if final_airlock != null:
		final_airlock.display_name = "CH02_DOOR_FINAL_AIRLOCK"


func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("CH02_GUNSHOT_ALARM")


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("CH02_OBJECTIVE_RED")
	elif keys.has(&"yellow"):
		GameState.set_objective("CH02_OBJECTIVE_YELLOW")
	elif keys.has(&"blue"):
		GameState.set_objective("CH02_OBJECTIVE_BLUE")
