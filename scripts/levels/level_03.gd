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


func _ready() -> void:
	if Engine.is_editor_hint():
		_install_editor_structure_preview()
		return

	# Canonical Pressure Line gameplay/environment are real subscene instances of
	# level_03.tscn. Only the safe authored structural roots are filtered out of the
	# legacy two-floor snapshot at runtime.
	_install_authored_structure()
	super._ready()


func _install_editor_structure_preview() -> void:
	if get_node_or_null("Geometry") != null:
		return
	_install_authored_structure()


func _install_authored_structure() -> void:
	var structure_resource := load(STRUCTURE_SOURCE_PATH) as PackedScene
	if structure_resource == null:
		push_error("VEX-03 yapısal kaynak sahnesi yüklenemedi.")
		return
	var source_root := structure_resource.instantiate() as Node3D
	if source_root == null:
		push_error("VEX-03 yapısal kaynak sahnesi instantiate edilemedi.")
		return

	for node_name: StringName in STRUCTURE_NODE_NAMES:
		if get_node_or_null(NodePath(str(node_name))) != null:
			continue
		var structure_node := source_root.get_node_or_null(NodePath(str(node_name)))
		if structure_node == null:
			push_error("VEX-03 yapısal node bulunamadı: %s" % node_name)
			continue
		if node_name == &"Doors":
			_configure_authored_doors(structure_node)
		source_root.remove_child(structure_node)
		structure_node.owner = null
		add_child(structure_node)

	source_root.free()


func _configure_authored_doors(doors_root: Node) -> void:
	# Legacy combat gates and old key semantics must not leak from the structural
	# snapshot. Start every authored door from a neutral traversal state, then
	# apply the three canonical Pressure Line access gates below.
	for child: Node in doors_root.get_children():
		var door := child as VexDoor
		if door == null:
			continue
		_reset_authored_door(door)

	_configure_key_door(
		doors_root.get_node_or_null("Door_StairAccess"),
		"CH03_DOOR_STAIR_ACCESS",
		&"blue",
		"CH03_BLUE_AUTH",
		"CH03_OBJECTIVE_UPPER"
	)
	_configure_key_door(
		doors_root.get_node_or_null("Door_StairSecurity"),
		"CH03_DOOR_ARCHIVE_ACCESS",
		&"yellow",
		"CH03_YELLOW_AUTH",
		"CH03_OBJECTIVE_RED"
	)
	_configure_key_door(
		doors_root.get_node_or_null("Door_CoreAuthorization"),
		"CH03_DOOR_REACTOR_ACCESS",
		&"red",
		"CH03_RED_AUTH",
		"CH03_OBJECTIVE_RESCUE"
	)

	var final_service_door := doors_root.get_node_or_null("Door_RiftChamber") as VexDoor
	if final_service_door != null:
		final_service_door.display_name = "CH03_DOOR_EVAC_SERVICE"
		final_service_door.auto_close = false


func _reset_authored_door(door: VexDoor) -> void:
	door.locked = false
	door.required_key = &""
	door.required_keys = []
	door.required_key_label = ""
	door.objective_on_unlock = ""
	door.required_enemy_ids = []
	door.objective_on_combat_clear = ""
	door.permanently_locked = false


func _configure_key_door(
	door_node: Node,
	display_key: String,
	required_key: StringName,
	required_label_key: String,
	objective_key: String
) -> void:
	var door := door_node as VexDoor
	if door == null:
		return
	door.display_name = display_key
	door.locked = true
	door.required_key = required_key
	door.required_keys = []
	door.required_key_label = required_label_key
	door.objective_on_unlock = objective_key
	door.required_enemy_ids = []
	door.objective_on_combat_clear = ""
	door.permanently_locked = false


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
