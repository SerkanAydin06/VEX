extends Node

const INVALID_SAVE_FIXTURE := "res://tests/fixtures/save_invalid_version.cfg"
const VALID_BACKUP_FIXTURE := "res://tests/fixtures/save_valid_backup.cfg"

const REQUIRED_RESOURCES := [
	"res://scenes/player/player.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/tutorial_trigger.tscn",
	"res://scenes/levels/level_01_training_overlay.tscn",
	"res://scripts/levels/level_01_training_flow.gd",
	"res://scenes/props/door_side_slide.tscn",
	"res://scenes/world/door_status_light.tscn",
	"res://scenes/hub/bastion_7.tscn",
	"res://resources/weapons/p01.tres",
	"res://resources/weapons/p07.tres",
	"res://resources/weapons/p14.tres",
	"res://resources/weapons/p20.tres",
	"res://resources/weapons/sg04.tres",
	"res://resources/weapons/vx47.tres",
	"res://resources/weapons/mp90.tres",
	"res://translations/vex.csv",
]

var failures: Array[String] = []


func _ready() -> void:
	_check_required_resources()
	_check_level_01()
	_check_level_02()
	_check_level_03()
	_check_bastion_7()
	_check_training_overlay()
	_check_automap_contract()
	_check_door_contract()
	_check_weapon_contracts()
	_check_input_map()
	_check_localization_contract()
	_check_save_recovery_contract()

	if failures.is_empty():
		print("VEX integrity test başarılı: güncel level, tutorial, automap, kapı ve silah sözleşmeleri temiz.")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		push_error("VEX integrity test başarısız: %d hata." % failures.size())
		get_tree().quit(1)


func _check_required_resources() -> void:
	for path: String in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(path):
			failures.append("Eksik kaynak: %s" % path)


func _instantiate(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Sahne yüklenemedi: %s" % path)
		return null
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Sahne instantiate edilemedi: %s" % path)
	return instance


func _count_named_children(root: Node, prefix: String) -> int:
	if root == null:
		return 0
	var count := 0
	for child: Node in root.get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _check_level_01() -> void:
	var level := _instantiate("res://scenes/levels/level_01.tscn")
	if level == null:
		return
	if str(level.get("map_revision")) != "VEX01-R28-37ROOM-13STEP":
		failures.append("VEX-01 37 oda revision sözleşmesi yanlış.")

	var geometry := level.get_node_or_null("Geometry")
	if _count_named_children(geometry, "Floor_R") != 37:
		failures.append("VEX-01 zemin modülü 37 değil.")
	if _count_named_children(geometry, "Ceiling_R") != 37:
		failures.append("VEX-01 tavan modülü 37 değil.")
	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != 37:
		failures.append("VEX-01 beyaz oda ışığı 37 değil.")
	var lights := level.get_node_or_null("Lights")
	if lights == null or lights.get_child_count() != 24:
		failures.append("VEX-01 statik kapı ışığı sayısı 24 değil.")
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 36:
		failures.append("VEX-01 seçici bağlantı kapısı 36 değil.")

	var blue_gate := level.get_node_or_null("Doors/Door_25_27") as VexDoor
	if blue_gate == null or not blue_gate.locked or blue_gate.required_key != &"blue":
		failures.append("VEX-01 mavi erişim kapısı yanlış.")
	var final_gate := level.get_node_or_null("Doors/Door_35_37") as VexDoor
	if final_gate == null or final_gate.required_keys != [&"blue", &"red"]:
		failures.append("VEX-01 final çift erişim kapısı yanlış.")
	var finish := level.get_node_or_null("Triggers/FinishSwitch") as VexFinishSwitch
	if finish == null or finish.required_enemy_id != &"ravager_19":
		failures.append("VEX-01 final muhafız/bitiş sözleşmesi yanlış.")

	var config: Dictionary = level.call("get_automap_config")
	var cells: Array = config.get("walkable_cells", []) as Array
	if cells.size() != 37:
		failures.append("VEX-01 automap yürünebilir oda sayısı 37 değil.")
	elif cells[0] != Vector2i(2, 12) or cells[cells.size() - 1] != Vector2i(2, 0):
		failures.append("VEX-01 automap oda sırası başlangıçtan çıkışa normalize edilmiyor.")
	level.free()


func _check_level_02() -> void:
	var level := _instantiate("res://scenes/levels/level_02.tscn")
	if level == null:
		return
	var geometry := level.get_node_or_null("Geometry")
	if _count_named_children(geometry, "Floor_") != 33:
		failures.append("VEX-02 zemin modülü 33 değil.")
	if _count_named_children(geometry, "Ceiling_") != 33:
		failures.append("VEX-02 tavan modülü 33 değil.")
	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != 33:
		failures.append("VEX-02 beyaz ışık sayısı 33 değil.")
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 5:
		failures.append("VEX-02 kapı sayısı 5 değil.")
	for node_path in ["Enemies/HellMagma_19", "Enemies/Voidweaver_30"]:
		if level.get_node_or_null(node_path) == null:
			failures.append("VEX-02 içerik eksik: %s" % node_path)
	level.free()


func _check_level_03() -> void:
	var level := _instantiate("res://scenes/levels/level_03.tscn")
	if level == null:
		return
	for node_path in [
		"Geometry/UpperLevel/UpperDeck",
		"Geometry/Stairs/Collision/SmoothRampCollision/LowerRamp",
		"Geometry/Stairs/Collision/SmoothRampCollision/Landing",
		"Geometry/Stairs/Collision/SmoothRampCollision/UpperRamp",
		"Objectives/RiftIsolationSwitch",
		"Enemies/KorvathWarden",
		"Pickups/BluePowerCard",
		"LoreTerminals/EceTanEmergencySignal",
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("VEX-03 bileşeni eksik: %s" % node_path)
	var enemies := level.get_node_or_null("Enemies")
	if enemies == null or enemies.get_child_count() != 16:
		failures.append("VEX-03 düşman yerleşimi 16 düğüm değil.")
	var pickups := level.get_node_or_null("Pickups")
	if pickups == null or pickups.get_child_count() != 12:
		failures.append("VEX-03 pickup yerleşimi 12 düğüm değil.")
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 14:
		failures.append("VEX-03 kapı sayısı 14 değil.")
	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != 17:
		failures.append("VEX-03 beyaz ışık sayısı 17 değil.")
	level.free()


func _check_bastion_7() -> void:
	var hub := _instantiate("res://scenes/hub/bastion_7.tscn")
	if hub == null:
		return
	var doors := hub.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 6:
		failures.append("Bastion-7 kapı sayısı 6 değil.")
	var lights := hub.get_node_or_null("RoomLights")
	if lights == null or lights.get_child_count() != 9:
		failures.append("Bastion-7 beyaz ışık sayısı 9 değil.")
	var door_lights := hub.get_node_or_null("DoorLights")
	if door_lights == null or door_lights.get_child_count() != 12:
		failures.append("Bastion-7 kapı durum ışığı sayısı 12 değil.")
	var room_displays := hub.get_node_or_null("RoomDisplays")
	if room_displays == null or room_displays.get_child_count() != 6:
		failures.append("Bastion-7 oda ekranı sayısı 6 değil.")
	for node_path in ["Systems/DeploymentTerminal", "Systems/CommandStatusTerminal", "Systems/ArmoryRacks"]:
		if hub.get_node_or_null(node_path) == null:
			failures.append("Bastion-7 sistem bileşeni eksik: %s" % node_path)
	hub.free()


func _check_training_overlay() -> void:
	var overlay := _instantiate("res://scenes/levels/level_01_training_overlay.tscn") as VexLevel01TrainingFlow
	if overlay == null:
		return
	if overlay.gate_door_paths.size() != 2 or overlay.gate_enemy_ids != [&"ravager_01", &"ravager_07"]:
		failures.append("VEX-01 Easy-safe combat gate eşlemesi yanlış.")
	for node_name in [
		"TutorialMove", "TutorialInteract", "TutorialFire", "TutorialReload",
		"TutorialStrafe", "TutorialBarrel", "TutorialResource", "TutorialFinal",
		"TutorialComplete", "TrainingBarrel", "Gate03_07StatusFront",
		"Gate03_07StatusBack", "Gate13_15StatusFront", "Gate13_15StatusBack",
	]:
		if overlay.get_node_or_null(node_name) == null:
			failures.append("VEX-01 eğitim overlay bileşeni eksik: %s" % node_name)
	var level_script := FileAccess.get_file_as_string("res://scripts/levels/level_01.gd")
	if "TRAINING_OVERLAY_SCENE" not in level_script or "add_child(_training_overlay)" not in level_script:
		failures.append("VEX-01 eğitim overlay sahnesi runtime akışına bağlı değil.")
	overlay.free()


func _check_automap_contract() -> void:
	var automap := FileAccess.get_file_as_string("res://scripts/ui/automap_view.gd")
	for contract in [
		"_walkable_order.find(cell) + 1",
		"door.has_method(\"is_access_locked\")",
		"door.call(\"is_access_locked\")",
	]:
		if contract not in automap:
			failures.append("Automap güncel sözleşmesi eksik: %s" % contract)
	var base_level := FileAccess.get_file_as_string("res://scripts/levels/base_level.gd")
	for contract in ["ordered_cells.reverse()", "\"walkable_cells\": ordered_cells"]:
		if contract not in base_level:
			failures.append("BaseLevel automap sıralama sözleşmesi eksik: %s" % contract)


func _check_door_contract() -> void:
	var door := _instantiate("res://scenes/props/door_side_slide.tscn") as VexDoor
	if door == null:
		return
	for property_name in [&"automatic_open", &"required_enemy_ids", &"objective_on_combat_clear"]:
		if not _has_property(door, property_name):
			failures.append("Kapı Inspector ayarı eksik: %s" % property_name)
	var left_panel := door.get_node_or_null("DoorPanel") as Node3D
	var right_panel := door.get_node_or_null("DoorPanelRight") as Node3D
	if left_panel == null or not is_equal_approx(left_panel.position.z, -1.11):
		failures.append("Sol kapı kanadı canonical -1.11 konumunda değil.")
	if right_panel == null or not is_equal_approx(right_panel.position.z, 1.11):
		failures.append("Sağ kapı kanadı canonical +1.11 konumunda değil.")
	for node_path in ["SafetySensor", "PerceptionBlocker", "DoorShadowBlocker", "FrameCollision/JambLeft", "FrameCollision/JambRight", "FrameCollision/Header"]:
		if door.get_node_or_null(node_path) == null:
			failures.append("Canonical kapı bileşeni eksik: %s" % node_path)
	door.free()


func _check_weapon_contracts() -> void:
	var p20 := load("res://resources/weapons/p20.tres") as WeaponDefinition
	if p20 == null:
		failures.append("P-20 WeaponDefinition yüklenemedi.")
	else:
		if p20.weapon_id != &"p20" or p20.ammo_type != &"bullets":
			failures.append("P-20 ortak tabanca mühimmat sözleşmesi yanlış.")
		if p20.hud_ammo_label_key != "HUD_AMMO_PISTOL":
			failures.append("P-20 ortak tabanca HUD etiketi yanlış.")
		if p20.magazine_size != 8 or p20.damage_per_pellet != 42:
			failures.append("P-20 şarjör/hasar dengesi yanlış.")
		if p20.reserve_ammo_capacity != 180:
			failures.append("P-20 ortak bullets rezerv kapasitesi 180 değil.")
		if not is_equal_approx(p20.penetration_power, 0.5):
			failures.append("P-20 penetrasyon gücü 0.5 değil.")
	var controller := FileAccess.get_file_as_string("res://scripts/player/weapon_controller.gd")
	for contract in ["penetration_power", "target_limit", "_migrate_legacy_ammo_dictionary", "legacy_magnum_count"]:
		if contract not in controller:
			failures.append("WeaponController P-20/save migration sözleşmesi eksik: %s" % contract)


func _check_input_map() -> void:
	for action_name in [
		"move_forward", "move_backward", "move_left", "move_right", "jump",
		"sprint", "crouch", "aim", "fire", "interact", "reload", "pause",
		"automap", "night_vision", "weapon_flashlight", "weapon_1", "weapon_2",
		"weapon_3", "weapon_4", "weapon_5",
	]:
		if not InputMap.has_action(action_name):
			failures.append("InputMap eksik: %s" % action_name)


func _check_localization_contract() -> void:
	var csv_text := FileAccess.get_file_as_string("res://translations/vex.csv")
	if not csv_text.begins_with("keys,tr,en"):
		failures.append("Çeviri CSV başlığı keys,tr,en değil.")
	for required_key in [
		"LEVEL01_TUTORIAL_MOVE_HINT", "LEVEL01_TUTORIAL_INTERACT_HINT",
		"LEVEL01_TUTORIAL_FIRE_HINT", "LEVEL01_TUTORIAL_RELOAD_HINT",
		"LEVEL01_TUTORIAL_STRAFE_HINT", "LEVEL01_TUTORIAL_BARREL_HINT",
		"LEVEL01_TUTORIAL_RESOURCE_HINT", "LEVEL01_TUTORIAL_FINAL_HINT",
		"LEVEL01_TUTORIAL_COMPLETE_HINT", "LEVEL01_DOOR_FIRE_TRAINING",
		"LEVEL01_DOOR_PROTOCOL_ENTRY", "WEAPON_P20_NAME", "HUD_AMMO_PISTOL",
		"DOOR_COMBAT_LOCKED", "DOOR_COMBAT_CLEARED",
	]:
		if required_key not in csv_text:
			failures.append("Çeviri anahtarı eksik: %s" % required_key)


func _check_save_recovery_contract() -> void:
	for fixture_path in [INVALID_SAVE_FIXTURE, VALID_BACKUP_FIXTURE]:
		if not FileAccess.file_exists(fixture_path):
			failures.append("Save recovery fixture eksik: %s" % fixture_path)
			return
	var recovered := bool(GameState.call(
		"_load_campaign_save_from_paths",
		INVALID_SAVE_FIXTURE,
		VALID_BACKUP_FIXTURE
	))
	if not recovered:
		failures.append("Semantik olarak bozuk ana kayıtta sağlam .bak yüklenemiyor.")
		return
	if str(GameState.saved_run_state.get("save_reason", "")) != "test_backup":
		failures.append("Save recovery ana kayıt yerine doğrulanmış yedeği seçmiyor.")
	if not bool(GameState.get("_loaded_save_from_backup")):
		failures.append("Save recovery yedekten yükleme durumunu korumuyor.")
	var invalid_pair_loaded := bool(GameState.call(
		"_load_campaign_save_from_paths",
		INVALID_SAVE_FIXTURE,
		INVALID_SAVE_FIXTURE
	))
	if invalid_pair_loaded:
		failures.append("Save recovery iki semantik bozuk kaydı geçerli kabul ediyor.")


func _has_property(object: Object, property_name: StringName) -> bool:
	for property_data in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			return true
	return false
