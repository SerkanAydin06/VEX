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
const ASH_CORRIDOR_CONTENT_SCENE := preload("res://scenes/levels/level_02_ash_corridor_content.tscn")
const ENVIRONMENT_STORY_SCENE := preload("res://scenes/levels/level_02_environment_story.tscn")

var _ash_corridor_content: Node3D
var _environment_story: Node3D
var _alarm_triggered := false


func _ready() -> void:
	# Legacy VEX-02 gameplay is preserved only as a structural source. None of its
	# old Ravager/Vaskari/Basalt/Voidweaver or pickup/trigger roots enter the live
	# SceneTree. Only authored geometry, navigation markers, doors, lights and props
	# are transferred into the canonical Chapter 2 shell.
	_install_authored_structure()
	_install_environment_story()
	_install_ash_corridor_content()
	super._ready()


func _install_authored_structure() -> void:
	var structure_resource := load(STRUCTURE_SOURCE_PATH) as PackedScene
	if structure_resource == null:
		push_error("VEX-02 yapısal kaynak sahnesi yüklenemedi.")
		return
	var source_root := structure_resource.instantiate() as Node3D
	if source_root == null:
		push_error("VEX-02 yapısal kaynak sahnesi instantiate edilemedi.")
		return

	for node_name: StringName in STRUCTURE_NODE_NAMES:
		var structure_node := source_root.get_node_or_null(NodePath(str(node_name)))
		if structure_node == null:
			push_error("VEX-02 yapısal node bulunamadı: %s" % node_name)
			continue
		if node_name == &"Doors":
			_configure_authored_doors(structure_node)
		source_root.remove_child(structure_node)
		structure_node.owner = null
		add_child(structure_node)

	source_root.free()


func _configure_authored_doors(doors_root: Node) -> void:
	_configure_door(
		doors_root.get_node_or_null("D01_Door"),
		"CH02_DOOR_BLUE_SHORTCUT",
		&"blue",
		"CH02_BLUE_FUSE",
		"CH02_OBJECTIVE_BLUE"
	)
	_configure_door(
		doors_root.get_node_or_null("D02_Door"),
		"CH02_DOOR_THERMAL_BULKHEAD",
		&"yellow",
		"CH02_YELLOW_FUSE",
		"CH02_OBJECTIVE_YELLOW"
	)
	_configure_door(
		doors_root.get_node_or_null("D03_Door"),
		"CH02_DOOR_EAST_TRANSFER",
		&"blue",
		"CH02_BLUE_FUSE",
		"CH02_OBJECTIVE_BLUE"
	)
	_configure_door(
		doors_root.get_node_or_null("D04_Door"),
		"CH02_DOOR_ISOLATION_LOCK",
		&"red",
		"CH02_RED_FUSE",
		"CH02_OBJECTIVE_RED"
	)
	var final_airlock := doors_root.get_node_or_null("D05_Door") as VexDoor
	if final_airlock != null:
		final_airlock.display_name = "CH02_DOOR_FINAL_AIRLOCK"
		final_airlock.locked = false
		final_airlock.required_key = &""
		final_airlock.required_keys = []
		final_airlock.required_key_label = ""
		final_airlock.objective_on_unlock = ""
		final_airlock.required_enemy_ids = []
		final_airlock.objective_on_combat_clear = ""
		final_airlock.permanently_locked = false


func _configure_door(
	door_node: Node,
	display_key: String,
	required_key: StringName,
	required_label: String,
	objective_key: String
) -> void:
	var door := door_node as VexDoor
	if door == null:
		return
	door.display_name = display_key
	door.locked = true
	door.required_key = required_key
	door.required_keys = []
	door.required_key_label = required_label
	door.objective_on_unlock = objective_key
	door.required_enemy_ids = []
	door.objective_on_combat_clear = ""
	door.permanently_locked = false


func _install_environment_story() -> void:
	if ENVIRONMENT_STORY_SCENE == null:
		push_error("VEX-02 çevresel hikâye sahnesi yüklenemedi.")
		return
	_environment_story = ENVIRONMENT_STORY_SCENE.instantiate() as Node3D
	if _environment_story == null:
		push_error("VEX-02 çevresel hikâye sahnesi instantiate edilemedi.")
		return
	add_child(_environment_story)


func _install_ash_corridor_content() -> void:
	if ASH_CORRIDOR_CONTENT_SCENE == null:
		push_error("VEX-02 Kül Koridoru içerik sahnesi yüklenemedi.")
		return
	_ash_corridor_content = ASH_CORRIDOR_CONTENT_SCENE.instantiate() as Node3D
	if _ash_corridor_content == null:
		push_error("VEX-02 Kül Koridoru içerik sahnesi instantiate edilemedi.")
		return
	add_child(_ash_corridor_content)
	map_revision = "VEX02-ASH-CORRIDOR-R33-CANONICAL"


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
