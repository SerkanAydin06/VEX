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
const PRESSURE_LINE_CONTENT_SCENE := preload("res://scenes/levels/level_03_pressure_line_content.tscn")
const ENVIRONMENT_STORY_SCENE := preload("res://scenes/levels/level_03_environment_story.tscn")

var _pressure_line_content: Node3D
var _environment_story: Node3D
var _alarm_triggered := false


func _ready() -> void:
	# The legacy Ash Mine scene remains only as an authored two-level structure
	# source. Mixed-reality enemies, old lore terminals, pickups and objectives are
	# never added to the live SceneTree.
	_install_authored_structure()
	_install_environment_story()
	_install_pressure_line_content()
	super._ready()


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
	var stair_access := doors_root.get_node_or_null("Door_StairAccess") as VexDoor
	if stair_access != null:
		stair_access.display_name = "CH03_DOOR_STAIR_ACCESS"
		stair_access.locked = true
		stair_access.required_key = &"blue"
		stair_access.required_keys = []
		stair_access.required_key_label = "CH03_BLUE_CLEARANCE"
		stair_access.objective_on_unlock = "CH03_OBJECTIVE_UPPER"
		stair_access.required_enemy_ids = []
		stair_access.objective_on_combat_clear = ""
		stair_access.permanently_locked = false

	var archive_access := doors_root.get_node_or_null("Door_CoreAuthorization") as VexDoor
	if archive_access != null:
		archive_access.display_name = "CH03_DOOR_ARCHIVE_ACCESS"
		archive_access.locked = true
		archive_access.required_key = &"red"
		archive_access.required_keys = []
		archive_access.required_key_label = "CH03_RED_CLEARANCE"
		archive_access.objective_on_unlock = "CH03_OBJECTIVE_RESCUE"
		archive_access.required_enemy_ids = []
		archive_access.objective_on_combat_clear = ""
		archive_access.permanently_locked = false
		archive_access.auto_close = false

	var final_service_door := doors_root.get_node_or_null("Door_RiftChamber") as VexDoor
	if final_service_door != null:
		final_service_door.display_name = "CH03_DOOR_REACTOR_SERVICE"
		final_service_door.locked = false
		final_service_door.required_key = &""
		final_service_door.required_keys = []
		final_service_door.required_key_label = ""
		final_service_door.objective_on_unlock = ""
		final_service_door.required_enemy_ids = []
		final_service_door.objective_on_combat_clear = ""
		final_service_door.permanently_locked = false


func _install_environment_story() -> void:
	if ENVIRONMENT_STORY_SCENE == null:
		push_error("VEX-03 çevresel hikâye sahnesi yüklenemedi.")
		return
	_environment_story = ENVIRONMENT_STORY_SCENE.instantiate() as Node3D
	if _environment_story == null:
		push_error("VEX-03 çevresel hikâye sahnesi instantiate edilemedi.")
		return
	add_child(_environment_story)


func _install_pressure_line_content() -> void:
	if PRESSURE_LINE_CONTENT_SCENE == null:
		push_error("VEX-03 Basınç Hattı içerik sahnesi yüklenemedi.")
		return
	_pressure_line_content = PRESSURE_LINE_CONTENT_SCENE.instantiate() as Node3D
	if _pressure_line_content == null:
		push_error("VEX-03 Basınç Hattı içerik sahnesi instantiate edilemedi.")
		return
	add_child(_pressure_line_content)
	map_revision = "VEX03-PRESSURE-LINE-R01-CANONICAL"


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("CH03_OBJECTIVE_RESCUE")
	elif keys.has(&"blue"):
		GameState.set_objective("CH03_OBJECTIVE_UPPER")


func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("CH03_GUNSHOT_ALARM")
