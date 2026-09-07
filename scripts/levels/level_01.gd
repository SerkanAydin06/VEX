@tool
extends VexBaseLevel

const STRUCTURE_SOURCE_PATH := "res://scenes/levels/level_01_structure_source.tscn"
const STRUCTURE_NODE_NAMES := [
	&"WorldEnvironment",
	&"Geometry",
	&"Doors",
	&"RoomLights",
	&"Lights",
	&"Props",
]
const TRAINING_OVERLAY_SCENE := preload("res://scenes/levels/level_01_training_overlay.tscn")

var _training_overlay: Node3D


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	# Structural roots must exist before the directly-instanced gameplay/environment
	# children receive _ready(), especially for lighting and navigation references.
	_install_authored_structure()


func _ready() -> void:
	if Engine.is_editor_hint():
		_install_editor_structure_preview()
		return
	super._ready()


func _install_editor_structure_preview() -> void:
	# The old structural source also contains retired gameplay roots, so it cannot
	# be instanced wholesale in the editor. Reuse the same safe structural filter
	# used at runtime. These preview nodes are intentionally not scene-owned; edits
	# to structural geometry should be made in the authored structure source.
	if get_node_or_null("Geometry") != null:
		return
	_install_authored_structure()


func _install_authored_structure() -> void:
	var structure_resource := load(STRUCTURE_SOURCE_PATH) as PackedScene
	if structure_resource == null:
		push_error("Bölüm 01 yapısal kaynak sahnesi yüklenemedi.")
		return
	var source_root := structure_resource.instantiate() as Node3D
	if source_root == null:
		push_error("Bölüm 01 yapısal kaynak sahnesi instantiate edilemedi.")
		return

	for node_name: StringName in STRUCTURE_NODE_NAMES:
		if get_node_or_null(NodePath(str(node_name))) != null:
			continue
		var structure_node := source_root.get_node_or_null(NodePath(str(node_name)))
		if structure_node == null:
			push_error("Bölüm 01 yapısal node bulunamadı: %s" % node_name)
			continue
		# Legacy structure source already has the two intended access doors, but its
		# labels/objectives predate the 30-chapter canon. Apply current semantics only
		# at runtime; editor preview keeps non-tool door scripts visual-only.
		if node_name == &"Doors" and not Engine.is_editor_hint():
			_configure_authored_doors(structure_node)
		source_root.remove_child(structure_node)
		structure_node.owner = null
		add_child(structure_node)

	source_root.free()


func _configure_authored_doors(doors_root: Node) -> void:
	for child: Node in doors_root.get_children():
		var door := child as VexDoor
		if door == null:
			continue
		_reset_authored_door(door)

	_configure_key_door(
		doors_root.get_node_or_null("Door_25_27"),
		"CH01_DOOR_BLUE_ACCESS",
		[&"blue"],
		"CH01_BLUE_ACCESS",
		"CH01_OBJECTIVE_DEEPER"
	)
	_configure_key_door(
		doors_root.get_node_or_null("Door_35_37"),
		"CH01_DOOR_FINAL_AIRLOCK",
		[&"blue", &"red"],
		"CH01_DUAL_ACCESS",
		"CH01_OBJECTIVE_FINAL"
	)


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
	required_keys: Array[StringName],
	required_label_key: String,
	objective_key: String
) -> void:
	var door := door_node as VexDoor
	if door == null:
		push_warning("Bölüm 01 kanonik erişim kapısı bulunamadı: %s" % display_key)
		return
	door.display_name = display_key
	door.locked = true
	door.required_key = &""
	door.required_keys = required_keys
	door.required_key_label = required_label_key
	door.objective_on_unlock = objective_key
	door.required_enemy_ids = []
	door.objective_on_combat_clear = ""
	door.permanently_locked = false


func _on_level_ready() -> void:
	_configure_first_fracture_start()
	if TRAINING_OVERLAY_SCENE == null:
		push_error("Bölüm 01 eğitim overlay sahnesi yüklenemedi.")
		return
	_training_overlay = TRAINING_OVERLAY_SCENE.instantiate() as Node3D
	if _training_overlay == null:
		push_error("Bölüm 01 eğitim overlay sahnesi instantiate edilemedi.")
		return
	add_child(_training_overlay)


func _configure_first_fracture_start() -> void:
	# Player sahnesi diğer görevler ve test sahneleri için P-01 ile başlar.
	# İlk Kırılma'da ise P-01 R03 güvenlik dolabından fiziksel olarak edinilir.
	# Bu override yalnız kampanyanın ilk aşamasında çalışır; tamamlanmış kampanya
	# ile olası tekrar girişlerde taşınan loadout'a dokunmaz.
	if GameState.campaign_stage != 0:
		return
	var level_player := get_node_or_null("Player") as Node
	if level_player == null:
		push_warning("Bölüm 01 silahsız başlangıç için Player bulunamadı.")
		return
	var weapon_controller := level_player.get_node_or_null("WeaponController") as VexWeaponController
	if weapon_controller == null:
		push_warning("Bölüm 01 silahsız başlangıç için WeaponController bulunamadı.")
		return
	weapon_controller.unlocked_weapons.clear()
	weapon_controller.acquired_weapons.clear()
	weapon_controller.current_weapon_id = &""
	weapon_controller.magazines[&"p01"] = 0
	weapon_controller.reserve_ammo[&"bullets"] = 0
	weapon_controller.reserve_ammo[&"shells"] = 0
	weapon_controller.reserve_ammo[&"rifle_ammo"] = 0
	weapon_controller.reserve_ammo[&"mp90_ammo"] = 0
	weapon_controller.flashlight_enabled = false
	weapon_controller.broadcast_state()


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	var has_blue := keys.has(&"blue")
	var has_red := keys.has(&"red")
	if has_blue and has_red:
		GameState.set_objective("CH01_OBJECTIVE_BOTH_KEYS")
	elif has_red:
		GameState.set_objective("CH01_OBJECTIVE_RED_ONLY")
	elif has_blue:
		GameState.set_objective("CH01_OBJECTIVE_BLUE_ONLY")
