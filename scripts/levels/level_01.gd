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
const FIRST_FRACTURE_CONTENT_SCENE := preload("res://scenes/levels/level_01_first_fracture_content.tscn")
const ENVIRONMENT_STORY_SCENE := preload("res://scenes/levels/level_01_environment_story.tscn")

var _training_overlay: Node3D
var _first_fracture_content: Node3D
var _environment_story: Node3D


func _ready() -> void:
	# Aktif level_01.tscn artık legacy gameplay içermez. Korunan 37 odalı fiziksel
	# omurga ayrı sahne kaynağından yalnız yapı node'ları seçilerek taşınır;
	# eski düşman/pickup/trigger kökleri hiçbir zaman aktif SceneTree'ye girmez.
	_install_authored_structure()
	_install_environment_story()
	_install_first_fracture_content()
	super._ready()


func _install_authored_structure() -> void:
	var structure_resource := load(STRUCTURE_SOURCE_PATH) as PackedScene
	if structure_resource == null:
		push_error("VEX-01 yapısal kaynak sahnesi yüklenemedi.")
		return
	var source_root := structure_resource.instantiate() as Node3D
	if source_root == null:
		push_error("VEX-01 yapısal kaynak sahnesi instantiate edilemedi.")
		return

	for node_name: StringName in STRUCTURE_NODE_NAMES:
		var structure_node := source_root.get_node_or_null(NodePath(str(node_name)))
		if structure_node == null:
			push_error("VEX-01 yapısal node bulunamadı: %s" % node_name)
			continue
		source_root.remove_child(structure_node)
		structure_node.owner = null
		add_child(structure_node)

	source_root.free()


func _install_environment_story() -> void:
	if ENVIRONMENT_STORY_SCENE == null:
		push_error("VEX-01 çevresel hikâye sahnesi yüklenemedi.")
		return
	_environment_story = ENVIRONMENT_STORY_SCENE.instantiate() as Node3D
	if _environment_story == null:
		push_error("VEX-01 çevresel hikâye sahnesi instantiate edilemedi.")
		return
	add_child(_environment_story)


func _install_first_fracture_content() -> void:
	if FIRST_FRACTURE_CONTENT_SCENE == null:
		push_error("VEX-01 kanonik içerik sahnesi yüklenemedi.")
		return
	_first_fracture_content = FIRST_FRACTURE_CONTENT_SCENE.instantiate() as Node3D
	if _first_fracture_content == null:
		push_error("VEX-01 kanonik içerik sahnesi instantiate edilemedi.")
		return
	add_child(_first_fracture_content)
	map_revision = "VEX01-FIRST-FRACTURE-R37-ENV01"


func _on_level_ready() -> void:
	_configure_first_fracture_start()
	if TRAINING_OVERLAY_SCENE == null:
		push_error("VEX-01 eğitim overlay sahnesi yüklenemedi.")
		return
	_training_overlay = TRAINING_OVERLAY_SCENE.instantiate() as Node3D
	if _training_overlay == null:
		push_error("VEX-01 eğitim overlay sahnesi instantiate edilemedi.")
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
		push_warning("VEX-01 silahsız başlangıç için Player bulunamadı.")
		return
	var weapon_controller := level_player.get_node_or_null("WeaponController") as VexWeaponController
	if weapon_controller == null:
		push_warning("VEX-01 silahsız başlangıç için WeaponController bulunamadı.")
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
		GameState.set_objective("LEVEL01_OBJECTIVE_BOTH_KEYS")
	elif has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_RED_ONLY")
	elif has_blue:
		GameState.set_objective("LEVEL01_OBJECTIVE_BLUE_ONLY")
