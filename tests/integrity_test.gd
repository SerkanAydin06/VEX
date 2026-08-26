extends Node

const REQUIRED_RESOURCES := [
	"res://resources/materials/floor_standard.tres",
	"res://resources/materials/ceiling_standard.tres",
	"res://resources/materials/wall_panel.tres",
	"res://resources/shaders/world_planar_surface.gdshader",
	"res://resources/shaders/world_wall_surface.gdshader",
	"res://scenes/props/door_side_slide.tscn",
	"res://resources/materials/door_threshold.tres",
	"res://scenes/props/burn_remains.tscn",
	"res://scenes/props/pickup.tscn",
	"res://scenes/props/explosive_barrel.tscn",
	"res://scripts/props/finish_switch.gd",
	"res://scenes/player/player.tscn",
	"res://resources/weapons/p01.tres",
	"res://resources/weapons/p07.tres",
	"res://resources/weapons/p14.tres",
	"res://resources/weapons/p20.tres",
	"res://resources/weapons/sg04.tres",
	"res://resources/weapons/vx47.tres",
	"res://resources/weapons/mp90.tres",
	"res://scenes/world/ceiling_light_white_horror.tscn",
	"res://scenes/world/ceiling_light_white_fill.tscn",
	"res://scenes/world/ceiling_light_white_large.tscn",
	"res://scenes/world/world_piece.tscn",
	"res://scenes/world/u_staircase.tscn",
	"res://scenes/world/door_status_light.tscn",
	"res://scenes/world/room_name_display.tscn",
	"res://scripts/world/room_name_display.gd",
	"res://scenes/world/korvath_rift.tscn",
	"res://scenes/world/lore_terminal.tscn",
	"res://assets/world/level03/korvath_rift.png",
	"res://assets/weapons/p01/p01_idle.png",
	"res://assets/weapons/p01/p01_side.png",
	"res://assets/weapons/p01/p01_fire_1.png",
	"res://assets/weapons/p01/p01_fire_2.png",
	"res://assets/weapons/p01/p01_fire_3.png",
	"res://assets/weapons/p01/p01_fire_4.png",
	"res://assets/weapons/p01/p01_aim_fire_1.png",
	"res://assets/weapons/p01/p01_aim_fire_2.png",
	"res://assets/weapons/p01/p01_aim_fire_3.png",
	"res://assets/weapons/p01/p01_aim_fire_4.png",
	"res://assets/weapons/p01/p01_reload_1.png",
	"res://assets/weapons/p01/p01_reload_2.png",
	"res://assets/weapons/p01/p01_reload_3.png",
	"res://assets/weapons/p01/p01_reload_4.png",
	"res://assets/weapons/p01/p01_zoom.png",
	"res://assets/weapons/p07/p07_idle.png",
	"res://assets/weapons/p07/p07_side.png",
	"res://assets/weapons/p07/p07_fire_1.png",
	"res://assets/weapons/p07/p07_fire_2.png",
	"res://assets/weapons/p07/p07_fire_3.png",
	"res://assets/weapons/p07/p07_fire_4.png",
	"res://assets/weapons/p07/p07_aim_fire_1.png",
	"res://assets/weapons/p07/p07_aim_fire_2.png",
	"res://assets/weapons/p07/p07_aim_fire_3.png",
	"res://assets/weapons/p07/p07_aim_fire_4.png",
	"res://assets/weapons/p07/p07_reload_1.png",
	"res://assets/weapons/p07/p07_reload_2.png",
	"res://assets/weapons/p07/p07_reload_3.png",
	"res://assets/weapons/p07/p07_reload_4.png",
	"res://assets/weapons/p07/p07_zoom.png",
	"res://assets/weapons/p14/p14_idle.png",
	"res://assets/weapons/p14/p14_side.png",
	"res://assets/weapons/p14/p14_fire_1.png",
	"res://assets/weapons/p14/p14_fire_2.png",
	"res://assets/weapons/p14/p14_fire_3.png",
	"res://assets/weapons/p14/p14_fire_4.png",
	"res://assets/weapons/p14/p14_aim_fire_1.png",
	"res://assets/weapons/p14/p14_aim_fire_2.png",
	"res://assets/weapons/p14/p14_aim_fire_3.png",
	"res://assets/weapons/p14/p14_aim_fire_4.png",
	"res://assets/weapons/p14/p14_reload_1.png",
	"res://assets/weapons/p14/p14_reload_2.png",
	"res://assets/weapons/p14/p14_reload_3.png",
	"res://assets/weapons/p14/p14_reload_4.png",
	"res://assets/weapons/p14/p14_zoom.png",
	"res://assets/weapons/p20/p20_idle.png",
	"res://assets/weapons/p20/p20_side.png",
	"res://assets/weapons/p20/p20_fire_1.png",
	"res://assets/weapons/p20/p20_fire_2.png",
	"res://assets/weapons/p20/p20_fire_3.png",
	"res://assets/weapons/p20/p20_fire_4.png",
	"res://assets/weapons/p20/p20_aim_fire_1.png",
	"res://assets/weapons/p20/p20_aim_fire_2.png",
	"res://assets/weapons/p20/p20_aim_fire_3.png",
	"res://assets/weapons/p20/p20_aim_fire_4.png",
	"res://assets/weapons/p20/p20_reload_1.png",
	"res://assets/weapons/p20/p20_reload_2.png",
	"res://assets/weapons/p20/p20_reload_3.png",
	"res://assets/weapons/p20/p20_reload_4.png",
	"res://assets/weapons/p20/p20_zoom.png",
	"res://scenes/ui/hud.tscn",
	"res://scripts/ui/hud_weapon_presenter.gd",
	"res://scenes/ui/weapons/p01_view.tscn",
	"res://scenes/ui/weapons/p07_view.tscn",
	"res://scenes/ui/weapons/p14_view.tscn",
	"res://scenes/ui/weapons/p20_view.tscn",
	"res://scenes/ui/weapons/sg04_view.tscn",
	"res://scenes/ui/weapons/vx47_view.tscn",
	"res://scenes/ui/weapons/mp90_view.tscn",
	"res://scripts/levels/base_level.gd",
	"res://scripts/actors/enemy_runtime_utils.gd",
	"res://scenes/hub/hub_survivor_presence.tscn",
	"res://scenes/hub/bastion_7.tscn",
	"res://scenes/hub/hub_terminal.tscn",
	"res://scenes/ui/terminal_menu.tscn",
	"res://scripts/ui/terminal_menu.gd",
	"res://assets/ui/bastion_terminal_screen_idle.png",
	"res://assets/world/bastion7/bastion_terminal_controls.png",
	"res://assets/ui/bastion_facility_network.png",
	"res://scenes/hub/hub_weapon_rack.tscn",
	"res://scenes/actors/redviper.tscn",
	"res://scenes/actors/badredviper.tscn",
	"res://scenes/actors/ravager.tscn",
	"res://scenes/actors/hellmagma.tscn",
	"res://scenes/actors/voidweaver.tscn",
	"res://scenes/actors/veilmaw.tscn",
	"res://scenes/actors/veilmaw_projectile.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/tutorial_trigger.tscn",
	"res://scripts/levels/tutorial_trigger.gd",
	"res://resources/missions/vex03.tres",
	"res://scenes/autoload/settings_manager.tscn",
	"res://scenes/ui/keybind_panel.tscn",
	"res://scripts/ui/keybind_panel.gd",
	"res://translations/vex.csv",
	"res://assets/enemies/redviper/redviper_spritesheet.png",
	"res://assets/enemies/badredviper/badredviper_spritesheet.png",
	"res://assets/enemies/ravager/ravager_spritesheet.png",
	"res://assets/enemies/hellmagma/hellmagma_spritesheet.png",
	"res://assets/enemies/voidweaver/voidweaver_spritesheet.png",
	"res://assets/enemies/ravager/ravager_projectile_sheet.png",
	"res://assets/enemies/ravager/ravager_impact_sheet.png",
	"res://assets/enemies/hellmagma/hellmagma_projectile_sheet.png",
	"res://assets/enemies/hellmagma/hellmagma_impact_sheet.png",
	"res://assets/enemies/voidweaver/voidweaver_projectile_sheet.png",
	"res://assets/enemies/voidweaver/voidweaver_impact_sheet.png",
]

var failures: Array[String] = []


func _ready() -> void:
	_check_required_resources()
	_check_level("res://scenes/levels/level_01.tscn", 26, 26, 38, 27)
	_check_level("res://scenes/levels/level_02.tscn", 33, 33, 10, 5)
	_check_level_03()
	_check_bastion_7()
	_check_enemy_visuals()
	_check_scene_authority()
	_check_door()
	_check_input_map()
	_check_key_progression()
	_check_player_movement_contract()
	_check_p01_visuals()
	_check_p07_visuals()
	_check_p14_playable_contract()
	_check_p20_playable_contract()
	_check_localization_contract()

	if failures.is_empty():
		print("VEX integrity test başarılı: Level 1/2/3, Bastion-7, kaynak bağlantıları ve sahne otoritesi temiz.")
	else:
		for message in failures:
			push_error(message)
		push_error("VEX integrity test başarısız: %d hata." % failures.size())


func _check_required_resources() -> void:
	for path in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(path):
			failures.append("Eksik kaynak: %s" % path)


func _check_level(path: String, room_count: int, white_light_count: int, red_light_count: int, door_count: int) -> void:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Bölüm yüklenemedi: %s" % path)
		return
	var level := packed.instantiate()
	if level == null:
		failures.append("Bölüm instantiate edilemedi: %s" % path)
		return
	add_child(level)

	var geometry := level.get_node_or_null("Geometry")
	if geometry == null:
		failures.append("Geometry eksik: %s" % path)
	else:
		var floors := 0
		var ceilings := 0
		for child in geometry.get_children():
			if child.name.begins_with("Floor_"):
				floors += 1
			elif child.name.begins_with("Ceiling_"):
				ceilings += 1
		if floors != room_count:
			failures.append("%s zemin modülü: %d / %d" % [path, floors, room_count])
		if ceilings != room_count:
			failures.append("%s tavan modülü: %d / %d" % [path, ceilings, room_count])

	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != white_light_count:
		failures.append("%s beyaz ışık sayısı yanlış." % path)
	var red_lights := level.get_node_or_null("Lights")
	if red_lights == null or red_lights.get_child_count() != red_light_count:
		failures.append("%s kırmızı ışık sayısı yanlış." % path)
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != door_count:
		failures.append("%s kapı sayısı yanlış." % path)

	if path.ends_with("level_02.tscn"):
		if level.get_node_or_null("Enemies/HellMagma_19") == null:
			failures.append("VEX-02 HellMagma yerleşimi eksik.")
		if level.get_node_or_null("Enemies/Voidweaver_30") == null:
			failures.append("VEX-02 Voidweaver yerleşimi eksik.")

	level.queue_free()


func _check_bastion_7() -> void:
	var packed := load("res://scenes/hub/bastion_7.tscn") as PackedScene
	if packed == null:
		failures.append("Bastion-7 sahnesi yüklenemedi.")
		return
	var hub := packed.instantiate()
	if hub == null:
		failures.append("Bastion-7 instantiate edilemedi.")
		return
	add_child(hub)
	var geometry := hub.get_node_or_null("Geometry")
	if geometry == null:
		failures.append("Bastion-7 Geometry eksik.")
	else:
		var floors := 0
		var ceilings := 0
		for child in geometry.get_children():
			if child.name.begins_with("Floor_"):
				floors += 1
			elif child.name.begins_with("Ceiling_"):
				ceilings += 1
		if floors != 13 or ceilings != 13:
			failures.append("Bastion-7 modül sayısı yanlış: %d floor / %d ceiling" % [floors, ceilings])
	var doors := hub.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 6:
		failures.append("Bastion-7 kapı sayısı yanlış.")
	var lights := hub.get_node_or_null("RoomLights")
	if lights == null or lights.get_child_count() != 9:
		failures.append("Bastion-7 beyaz ışık sayısı yanlış.")
	var door_lights := hub.get_node_or_null("DoorLights")
	if door_lights == null or door_lights.get_child_count() != 12:
		failures.append("Bastion-7 kırmızı kapı ışığı sayısı yanlış.")
	elif door_lights.get_children().any(func(light: Node3D) -> bool: return not is_equal_approx(light.position.y, 6.05)):
		failures.append("Bastion-7 kapı durum ışıkları oda ekranından ayrı Y=6.05 hizasında değil.")
	var room_displays := hub.get_node_or_null("RoomDisplays")
	if room_displays == null or room_displays.get_child_count() != 6:
		failures.append("Bastion-7 dijital oda ekranı sayısı yanlış.")
	else:
		var expected_room_names := [
			"ARMORY", "FIRING RANGE", "RESEARCH LAB",
			"WEAPON WORKSHOP", "ENGINEERING BAY", "OPERATOR PLATFORM",
		]
		for index in room_displays.get_child_count():
			var display := room_displays.get_child(index) as Node3D
			if display == null or not is_equal_approx(display.position.y, 5.25):
				failures.append("Bastion-7 oda ekranı canonical Y=5.25 hizasında değil.")
				continue
			if str(display.get("room_name")) != expected_room_names[index]:
				failures.append("Bastion-7 oda ekranı metni yanlış: %s" % display.name)
	for door_name in ["FiringRangeDoor", "ResearchDoor"]:
		var door := hub.get_node_or_null("Doors/%s" % door_name)
		if door == null or not bool(door.get("permanently_locked")):
			failures.append("Bastion-7 kilitli alan standardı eksik: %s" % door_name)
	for door_name in ["WorkshopDoor", "EngineeringDoor"]:
		var door := hub.get_node_or_null("Doors/%s" % door_name)
		if door == null or int(door.get("campaign_unlock_stage")) != 2:
			failures.append("Bastion-7 stage 2 kapı standardı eksik: %s" % door_name)
	if hub.get_node_or_null("Systems/MissionTerminal") != null:
		failures.append("Bastion-7 MissionTerminal kaldırılmamış.")
	var operations_terminal := hub.get_node_or_null("Systems/DeploymentTerminal")
	if operations_terminal == null or str(operations_terminal.get("display_name")) != "OPERASYON TERMİNALİ":
		failures.append("Bastion-7 tek Operasyon Terminali standardı eksik.")
	elif operations_terminal.get_node_or_null("TerminalMenu") == null:
		failures.append("Bastion-7 Operasyon Terminali tam ekran görev/tesis menüsüne bağlı değil.")
	elif operations_terminal.get_node_or_null("Visuals/ScreenAssembly/ScreenSurface") == null:
		failures.append("Bastion-7 Operasyon Terminali sabit VEX ekranına bağlı değil.")
	elif operations_terminal.get_node_or_null("Visuals/DeckAssembly/ControlSurface") == null:
		failures.append("Bastion-7 Operasyon Terminali 3B kumanda deck yüzeyine bağlı değil.")
	elif operations_terminal.get_node_or_null("PhysicalBody/SolidCollider") == null:
		failures.append("Bastion-7 Operasyon Terminali fiziksel gövde çarpışmasına bağlı değil.")
	elif operations_terminal.get_node_or_null("ScreenInteraction") == null:
		failures.append("Bastion-7 Operasyon Terminali ekran-özel etkileşim alanına bağlı değil.")
	else:
		var solid_collider := operations_terminal.get_node("PhysicalBody/SolidCollider") as StaticBody3D
		var screen_interaction := operations_terminal.get_node("ScreenInteraction") as StaticBody3D
		if solid_collider.collision_layer != 1:
			failures.append("Bastion-7 Operasyon Terminali fiziksel gövdesi layer 1 üzerinde değil.")
		if screen_interaction.collision_layer != 8:
			failures.append("Bastion-7 Operasyon Terminali ekran etkileşimi layer 8 üzerinde değil.")
	var command_terminal := hub.get_node_or_null("Systems/CommandStatusTerminal")
	if command_terminal == null or command_terminal.get_node_or_null("TerminalMenu") == null:
		failures.append("Bastion-7 durum terminali tesis kayıt menüsüne bağlı değil.")
	var mission_definitions: Array = hub.get("mission_definitions") as Array
	if mission_definitions.size() < 3 or str(mission_definitions[2].get("scene_path")) != "res://scenes/levels/level_03.tscn":
		failures.append("Bastion-7 VEX-03 görev bağlantısı eksik.")
	else:
		for definition in mission_definitions:
			if str(definition.get("terminal_code")).is_empty():
				failures.append("Bastion-7 görevinde terminal kodu eksik.")
			if str(definition.get("facility_type")).is_empty():
				failures.append("Bastion-7 görevinde tesis türü eksik.")
			if definition.get("terminal_preview") == null:
				failures.append("Bastion-7 görevinde terminal tesis görseli eksik.")
	for armory_path in [
		"Props/ArmoryCategoryVisuals/PistolCategoryRack",
		"Props/ArmoryCategoryVisuals/ShotgunCategoryRack",
		"Props/ArmoryCategoryVisuals/RifleCategoryRack",
		"Props/ArmoryCategoryVisuals/SmgCategoryRack",
		"Props/ArmoryCategoryVisuals/LaserCategoryRack",
	]:
		if hub.get_node_or_null(armory_path) == null:
			failures.append("Bastion-7 profesyonel cephanelik bileşeni eksik: %s" % armory_path)
	var armory_racks := hub.get_node_or_null("Systems/ArmoryRacks")
	if armory_racks == null or armory_racks.get_child_count() != 5:
		failures.append("Bastion-7 cephanelik kategori rafı sayısı 5 değil.")
	else:
		var slot_count := 0
		for category_rack in armory_racks.get_children():
			if not category_rack.visible or category_rack.get_child_count() != 4:
				failures.append("Bastion-7 kategori rafı 2x2 dört yuvalı değil: %s" % category_rack.name)
			for rack_slot in category_rack.get_children():
				slot_count += 1
				var weapon_visual := rack_slot.get_node_or_null("WeaponVisual") as Sprite3D
				if weapon_visual == null or int(weapon_visual.billboard) != 0:
					failures.append("Bastion-7 raf silahı kameraya dönüyor: %s" % rack_slot.name)
				if rack_slot.get_node_or_null("EmptySlotVisual") == null or rack_slot.get_node_or_null("EmptySlotLabel") == null:
					failures.append("Bastion-7 raf boş-yuva izi eksik: %s" % rack_slot.name)
		if slot_count != 20:
			failures.append("Bastion-7 toplam silah yuvası sayısı 20 değil.")
	var pistol_rack := hub.get_node_or_null("Systems/ArmoryRacks/PistolRack") as Node3D
	var shotgun_rack := hub.get_node_or_null("Systems/ArmoryRacks/ShotgunRack") as Node3D
	var rifle_rack := hub.get_node_or_null("Systems/ArmoryRacks/RifleRack") as Node3D
	var smg_rack := hub.get_node_or_null("Systems/ArmoryRacks/SmgRack") as Node3D
	var laser_rack := hub.get_node_or_null("Systems/ArmoryRacks/LaserRack") as Node3D
	if pistol_rack == null or pistol_rack.position != Vector3(-16, 1.1, -14.35):
		failures.append("Bastion-7 tabanca kategori rafı yanlış konumda.")
	var p07_visual := hub.get_node_or_null("Systems/ArmoryRacks/PistolRack/P07Slot/WeaponVisual") as Sprite3D
	if p07_visual == null or p07_visual.texture == null:
		failures.append("Bastion-7 P-07 rafı yandan silah görseline bağlı değil.")
	if shotgun_rack == null or shotgun_rack.position != Vector3(-12, 1.1, -14.35):
		failures.append("Bastion-7 pompalı kategori rafı yanlış konumda.")
	if rifle_rack == null or rifle_rack.position != Vector3(-8, 1.1, -14.35):
		failures.append("Bastion-7 tüfek kategori rafı yanlış konumda.")
	if smg_rack == null or smg_rack.position != Vector3(-15.5, 1.1, -5.65):
		failures.append("Bastion-7 SMG kategori rafı yanlış konumda.")
	if laser_rack == null or laser_rack.position != Vector3(-8.5, 1.1, -5.65):
		failures.append("Bastion-7 lazer kategori rafı yanlış konumda.")
	var interaction_ray := hub.get_node_or_null("Player/ViewPivot/Camera3D/InteractionRay") as RayCast3D
	if interaction_ray == null or interaction_ray.target_position != Vector3(0.0, 0.0, -3.4):
		failures.append("Bastion-7 üst cephanelik yuvaları için etkileşim mesafesi yanlış.")
	var armory_controller := hub.get_node_or_null("Player/WeaponController") as VexWeaponController
	if armory_controller == null:
		failures.append("Bastion-7 cephanelik oyuncu silah kontrolcüsüne ulaşamıyor.")
	else:
		var stored_result: Dictionary = armory_controller.toggle_armory_weapon(&"p01")
		if not bool(stored_result.get("success", false)) or armory_controller.is_weapon_carried(&"p01"):
			failures.append("Bastion-7 tabancayı rafa bırakma işlemi çalışmıyor.")
		var equipped_result: Dictionary = armory_controller.toggle_armory_weapon(&"p01")
		if not bool(equipped_result.get("success", false)) or not armory_controller.is_weapon_carried(&"p01"):
			failures.append("Bastion-7 tabancayı raftan geri alma işlemi çalışmıyor.")
	hub.queue_free()


func _check_level_03() -> void:
	var packed := load("res://scenes/levels/level_03.tscn") as PackedScene
	if packed == null:
		failures.append("VEX-03 sahnesi yüklenemedi.")
		return
	var level := packed.instantiate()
	if level == null:
		failures.append("VEX-03 instantiate edilemedi.")
		return
	add_child(level)
	for node_path in [
		"Geometry/LowerLevel/Floor_L01_Start",
		"Geometry/LowerLevel/Ceiling_L06_MaintenanceHall",
		"Geometry/UpperLevel/UpperDeck",
		"Geometry/Stairs/Collision/SmoothRampCollision/LowerRamp",
		"Geometry/Stairs/Collision/SmoothRampCollision/Landing",
		"Geometry/Stairs/Collision/SmoothRampCollision/UpperRamp",
		"Geometry/Stairs/Visual/StairLanding",
		"Geometry/Stairs/Visual/StairTread_L10",
		"Geometry/Stairs/Visual/StairRiser_U10",
		"Geometry/Stairs/Visual/RailUpperRight",
		"Doors/Door_UpperLanding/FrameJambLeft",
		"Objectives/KorvathRiftCore",
		"Objectives/RiftIsolationSwitch",
		"Enemies/KorvathWarden",
		"Pickups/BluePowerCard",
		"LoreTerminals/EceTanEmergencySignal",
	]:
		if level.get_node_or_null(node_path) == null:
			failures.append("VEX-03 bileşeni eksik: %s" % node_path)
	var upper_deck := level.get_node_or_null("Geometry/UpperLevel/UpperDeck") as Node3D
	if upper_deck == null or not is_equal_approx(upper_deck.position.y, 7.6):
		failures.append("VEX-03 üst kat bağımsız döşeme kotunda değil.")
	var lower_viper := level.get_node_or_null("Enemies/LowerRedViperA") as Node3D
	if lower_viper == null or not is_equal_approx(lower_viper.position.y, 0.48):
		failures.append("VEX-03 RedViper zemin hizası yanlış.")
	var upper_korvath := level.get_node_or_null("Enemies/UpperKorvathA") as Node3D
	if upper_korvath == null or not is_equal_approx(upper_korvath.position.y, 1.9):
		failures.append("VEX-03 merdiven Korvath'ı alt kat zemin hizasında değil.")
	var lower_stair_ramp := level.get_node_or_null("Geometry/Stairs/Collision/SmoothRampCollision/LowerRamp") as Node3D
	if lower_stair_ramp == null or not lower_stair_ramp.global_position.is_equal_approx(Vector3(17.108667, 1.849965, 3.25)):
		failures.append("VEX-03 alt merdiven yürüyüş rampası görünen basamaklarla hizalı değil.")
	var upper_stair_ramp := level.get_node_or_null("Geometry/Stairs/Collision/SmoothRampCollision/UpperRamp") as Node3D
	if upper_stair_ramp == null or not upper_stair_ramp.global_position.is_equal_approx(Vector3(17.209728, 5.770875, 6.75)):
		failures.append("VEX-03 üst merdiven yürüyüş rampası görünen basamaklarla hizalı değil.")
	var finish_switch := level.get_node_or_null("Objectives/RiftIsolationSwitch") as VexFinishSwitch
	if finish_switch == null:
		failures.append("VEX-03 yarık izolasyon şalteri yüklenemedi.")
	elif finish_switch.required_keys != [&"blue", &"red"]:
		failures.append("VEX-03 yarık izolasyon şalterinin typed anahtar dizisi yanlış.")
	var script_text := FileAccess.get_file_as_string("res://scripts/levels/level_03.gd")
	for forbidden_builder in ["_build_level_geometry", "_spawn_gameplay", "_spawn_enemy(", "_spawn_pickup("]:
		if forbidden_builder in script_text:
			failures.append("VEX-03 runtime sahne üretimi kaldırılmamış: %s" % forbidden_builder)
	var scene_text := FileAccess.get_file_as_string("res://scenes/levels/level_03.tscn")
	for contract in ["vex03_secret_maintenance_cache", "vex03_secret_upper_archive", "vex03_korvath_warden"]:
		if contract not in scene_text:
			failures.append("VEX-03 progression ID eksik: %s" % contract)
	var enemies := level.get_node_or_null("Enemies")
	if enemies == null or enemies.get_child_count() != 16:
		failures.append("VEX-03 sahne düşman yerleşimi 16 düğüm değil.")
	var pickups := level.get_node_or_null("Pickups")
	if pickups == null or pickups.get_child_count() != 12:
		failures.append("VEX-03 sahne pickup yerleşimi 12 düğüm değil.")
	var lower_level := level.get_node_or_null("Geometry/LowerLevel")
	var upper_level := level.get_node_or_null("Geometry/UpperLevel")
	var lower_room_count := 0
	var upper_room_count := 0
	if lower_level != null:
		for child in lower_level.get_children():
			if child.name.begins_with("Room_L"):
				lower_room_count += 1
	if upper_level != null:
		for child in upper_level.get_children():
			if child.name.begins_with("Room_U"):
				upper_room_count += 1
	if lower_room_count != 10 or upper_room_count != 8:
		failures.append("VEX-03 modüler oda standardı yanlış: %d alt / %d üst." % [lower_room_count, upper_room_count])
	var room_lights := level.get_node_or_null("RoomLights")
	if room_lights == null or room_lights.get_child_count() != 17:
		failures.append("VEX-03 bilinçli 17 beyaz ışık standardını kullanmıyor.")
	var door_status_lights := level.get_node_or_null("Lights")
	if door_status_lights == null or door_status_lights.get_child_count() != 28:
		failures.append("VEX-03 her kapının iki yüzünde toplam 28 durum lambası kullanmıyor.")
	var doors := level.get_node_or_null("Doors")
	if doors == null or doors.get_child_count() != 14:
		failures.append("VEX-03 oda-koridor kapı sayısı 14 değil.")
	for removed_contract in ["CargoElevator_Main", "VentLowCeiling", "UpperServiceCeiling", "CrouchInstructionLabel"]:
		if removed_contract in scene_text:
			failures.append("VEX-03 kaldırılan sistem hâlâ sahnede: %s" % removed_contract)
	level.queue_free()


func _check_enemy_visuals() -> void:
	for enemy_name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver", "veilmaw"]:
		var packed := load("res://scenes/actors/%s.tscn" % enemy_name) as PackedScene
		if packed == null:
			continue
		var enemy := packed.instantiate()
		var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		if sprite == null:
			failures.append("%s AnimatedSprite3D eksik." % enemy_name)
		else:
			if int(sprite.billboard) != 2:
				failures.append("%s Fixed-Y billboard kullanmıyor." % enemy_name)
			if int(sprite.texture_filter) != 3:
				failures.append("%s Linear Mipmap kullanmıyor." % enemy_name)
		enemy.queue_free()


func _has_property(object: Object, property_name: StringName) -> bool:
	for property_data in object.get_property_list():
		if StringName(property_data.get("name", "")) == property_name:
			return true
	return false


func _check_scene_authority() -> void:
	var enemy_required := [
		&"maximum_health",
		&"apply_difficulty_scaling",
		&"difficulty_health_multipliers",
		&"difficulty_damage_multipliers",
		&"difficulty_speed_multipliers",
		&"difficulty_detection_multipliers",
		&"difficulty_cooldown_multipliers",
		&"difficulty_windup_multipliers",
		&"floor_snap_max_correction",
		&"burn_remains_scene",
	]
	for enemy_name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver", "veilmaw"]:
		var packed := load("res://scenes/actors/%s.tscn" % enemy_name) as PackedScene
		if packed == null:
			continue
		var enemy := packed.instantiate()
		for property_name in enemy_required:
			if not _has_property(enemy, property_name):
				failures.append("%s sahne ayarı Inspector'da eksik: %s" % [enemy_name, property_name])
		for multiplier_name in [
			&"difficulty_health_multipliers",
			&"difficulty_damage_multipliers",
			&"difficulty_speed_multipliers",
			&"difficulty_detection_multipliers",
			&"difficulty_cooldown_multipliers",
			&"difficulty_windup_multipliers",
		]:
			var values = enemy.get(multiplier_name)
			if values is PackedFloat32Array and values.is_empty():
				failures.append("%s %s boş." % [enemy_name, multiplier_name])
		if enemy.get(&"burn_remains_scene") == null:
			failures.append("%s burn_remains_scene sahneden atanmadı." % enemy_name)
		enemy.queue_free()

	var projectile_required := [
		&"speed", &"lifetime", &"impact_surface_offset",
		&"light_pulse_amplitude", &"light_pulse_speed", &"impact_light_energy",
		&"impact_light_fade_duration", &"impact_start_scale_multiplier",
		&"impact_end_scale_multiplier", &"impact_scale_duration",
		&"impact_fade_delay", &"impact_fade_duration",
	]
	for projectile_name in ["ravager_projectile", "hellmagma_projectile", "voidweaver_projectile", "veilmaw_projectile"]:
		var packed := load("res://scenes/actors/%s.tscn" % projectile_name) as PackedScene
		if packed == null:
			continue
		var projectile := packed.instantiate()
		for property_name in projectile_required:
			if not _has_property(projectile, property_name):
				failures.append("%s sahne ayarı Inspector'da eksik: %s" % [projectile_name, property_name])
		projectile.queue_free()

	var player_packed := load("res://scenes/player/player.tscn") as PackedScene
	if player_packed != null:
		var player := player_packed.instantiate()
		if int(player.get(&"maximum_health")) != 100:
			failures.append("Player maksimum can temel tuning değeri 100 değil.")
		for property_name in [
			&"maximum_health", &"maximum_armor", &"armor_absorption_ratio",
			&"hurt_audio_cooldown", &"floor_stick_velocity", &"pitch_limit_degrees",
			&"bob_speed_multiplier", &"night_vision_shader",
		]:
			if not _has_property(player, property_name):
				failures.append("Player sahne ayarı Inspector'da eksik: %s" % property_name)
		var controller := player.get_node_or_null("WeaponController")
		if controller != null:
			for property_name in [
				&"initial_unlocked_weapons", &"initial_weapon_id", &"equip_cooldown",
				&"empty_trigger_cooldown", &"hitscan_collision_mask",
				&"burst_reset_fire_interval_multiplier", &"weapon_flashlight_path",
			]:
				if not _has_property(controller, property_name):
					failures.append("WeaponController sahne ayarı Inspector'da eksik: %s" % property_name)
		player.queue_free()

	for level_path in ["res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn", "res://scenes/levels/level_03.tscn"]:
		var level_packed := load(level_path) as PackedScene
		if level_packed != null:
			var level := level_packed.instantiate()
			for property_name in [
				&"map_revision", &"level_display_name", &"campaign_completion_stage", &"first_objective", &"total_secrets",
				&"briefing_story", &"briefing_objective", &"briefing_character_delay", &"briefing_start_delay",
				&"automap_title", &"automap_columns", &"automap_rows",
				&"automap_world_min", &"automap_world_max", &"automap_walkable_cells",
				&"automap_start_cell", &"automap_exit_cell", &"automap_merge_adjacent_cells",
				&"automap_show_room_numbers",
			]:
				if not _has_property(level, property_name):
					failures.append("Level sahne ayarı Inspector'da eksik: %s / %s" % [level_path, property_name])
			level.queue_free()

	var hub_packed := load("res://scenes/hub/bastion_7.tscn") as PackedScene
	if hub_packed != null:
		var hub := hub_packed.instantiate()
		for property_name in [
			&"hub_display_name", &"first_objective", &"intro_message_delay", &"arrival_message", &"allow_weapon_fire",
			&"automap_title", &"automap_columns", &"automap_rows", &"automap_world_min",
			&"automap_world_max", &"automap_walkable_cells", &"automap_start_cell",
			&"automap_exit_cell", &"automap_merge_adjacent_cells", &"automap_show_room_numbers",
			&"ambience_volume_db", &"mission_paths", &"mission_labels",
		]:
			if not _has_property(hub, property_name):
				failures.append("Bastion-7 sahne ayarı Inspector'da eksik: %s" % property_name)
		hub.queue_free()

	var hud_packed := load("res://scenes/ui/hud.tscn") as PackedScene
	if hud_packed != null:
		var hud := hud_packed.instantiate()
		for property_name in [&"critical_health_threshold", &"notification_hold_time", &"pickup_hold_time", &"damage_feedback_time"]:
			if not _has_property(hud, property_name):
				failures.append("HUD sahne ayarı Inspector'da eksik: %s" % property_name)
		var automap := hud.get_node_or_null("Root/MapOverlay/AutomapView")
		if automap != null:
			for property_name in [&"map_padding", &"default_zoom", &"redraw_interval", &"player_color", &"exit_color"]:
				if not _has_property(automap, property_name):
					failures.append("Automap sahne ayarı Inspector'da eksik: %s" % property_name)
		hud.queue_free()

	for scene_path in ["res://scenes/world/world_piece.tscn", "res://scenes/world/ceiling_light_white_horror.tscn"]:
		var packed_scene := load(scene_path) as PackedScene
		if packed_scene != null:
			var instance := packed_scene.instantiate()
			if scene_path.ends_with("world_piece.tscn"):
				for property_name in [&"piece_size", &"surface_material", &"cast_shadow", &"occlusion_enabled"]:
					if not _has_property(instance, property_name):
						failures.append("WorldPiece sahne ayarı Inspector'da eksik: %s" % property_name)
			else:
				for property_name in [&"light_color", &"light_energy", &"light_range", &"cone_angle", &"fixture_pixel_size"]:
					if not _has_property(instance, property_name):
						failures.append("RoomLight sahne ayarı Inspector'da eksik: %s" % property_name)
			instance.queue_free()

	for weapon_path in [
		"res://resources/weapons/p01.tres",
		"res://resources/weapons/p07.tres",
		"res://resources/weapons/sg04.tres",
		"res://resources/weapons/vx47.tres",
		"res://resources/weapons/mp90.tres",
	]:
		var weapon = load(weapon_path)
		if weapon == null:
			continue
		if not _has_property(weapon, &"reserve_ammo_capacity"):
			failures.append("Weapon resource ammo kapasitesi Inspector'da eksik: %s" % weapon_path)

	var settings_packed := load("res://scenes/autoload/settings_manager.tscn") as PackedScene
	if settings_packed == null:
		failures.append("Sahne tabanlı SettingsManager yüklenemedi.")
	else:
		var settings := settings_packed.instantiate()
		for property_name in [
			&"supported_locales", &"language_label_keys", &"supported_resolutions",
			&"brightness_min", &"brightness_max", &"mouse_sensitivity_min",
			&"mouse_sensitivity_max", &"difficulty_health_multipliers",
			&"difficulty_resource_multipliers",
		]:
			if not _has_property(settings, property_name):
				failures.append("SettingsManager sahne ayarı Inspector'da eksik: %s" % property_name)
		settings.queue_free()


func _check_door() -> void:
	var packed := load("res://scenes/props/door_side_slide.tscn") as PackedScene
	if packed == null:
		return
	var door := packed.instantiate()
	var front := door.get_node_or_null("DoorPanel/FrontVisual") as Sprite3D
	if front == null or not front.flip_h:
		failures.append("DoorPanel/FrontVisual Flip H standardı eksik.")
	var threshold := door.get_node_or_null("DoorThreshold") as MeshInstance3D
	if threshold == null:
		failures.append("DoorThreshold kapı sahnesinde eksik.")
	var left_panel := door.get_node_or_null("DoorPanel") as Node3D
	var right_panel := door.get_node_or_null("DoorPanelRight") as Node3D
	if left_panel == null or not is_equal_approx(left_panel.position.z, -1.11):
		failures.append("Sol kapı kanadı jamb iç yüzüne sıfır boşlukla hizalı değil.")
	if right_panel == null or not is_equal_approx(right_panel.position.z, 1.11):
		failures.append("Sağ kapı kanadı jamb iç yüzüne sıfır boşlukla hizalı değil.")
	var panel_mesh := door.get_node_or_null("DoorPanel/PanelBody") as MeshInstance3D
	if panel_mesh == null or not (panel_mesh.mesh is BoxMesh) or not is_equal_approx((panel_mesh.mesh as BoxMesh).size.z, 2.22):
		failures.append("Kapı kanadı genişliği canonical 2.22 m değil.")
	for frame_collision_path in ["FrameCollision/JambLeft", "FrameCollision/JambRight", "FrameCollision/Header"]:
		if door.get_node_or_null(frame_collision_path) == null:
			failures.append("Kapı kasası collision eksik: %s" % frame_collision_path)
	for property_name in [&"automatic_open", &"required_enemy_ids", &"objective_on_combat_clear"]:
		if not _has_property(door, property_name):
			failures.append("Kapı Inspector ayarı eksik: %s" % property_name)
	door.queue_free()


func _check_input_map() -> void:
	for action_name in ["move_forward", "move_backward", "move_left", "move_right", "jump", "sprint", "crouch", "aim", "fire", "interact", "reload", "pause", "automap", "night_vision", "weapon_flashlight", "weapon_1", "weapon_2", "weapon_3", "weapon_4", "weapon_5"]:
		if not InputMap.has_action(action_name):
			failures.append("InputMap eksik: %s" % action_name)


func _check_key_progression() -> void:
	for key_path in [
		"res://assets/pickups/key_blue.png",
		"res://assets/pickups/key_red.png",
		"res://assets/pickups/key_yellow.png",
	]:
		if not ResourceLoader.exists(key_path):
			failures.append("Anahtar görseli eksik: %s" % key_path)
	var pickup_script := load("res://scripts/props/pickup.gd")
	if pickup_script == null:
		failures.append("Pickup script yüklenemedi.")
	for scene_path in ["res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn"]:
		var text := FileAccess.get_file_as_string(scene_path)
		if "key_blue" not in text or "key_red" not in text:
			failures.append("%s mavi/kırmızı key progression eksik." % scene_path)
	if "key_yellow" not in FileAccess.get_file_as_string("res://scenes/levels/level_02.tscn"):
		failures.append("VEX-02 sarı key yerleşimi eksik.")


func _check_player_movement_contract() -> void:
	var script_text := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	for required in [
		"Input.is_action_just_pressed(\"jump\")",
		"Input.is_action_pressed(\"sprint\")",
		"event.is_action_pressed(\"crouch\")",
		"func _try_jump()",
		"func _can_stand_up()",
	]:
		if required not in script_text:
			failures.append("Player movement contract eksik: %s" % required)


func _check_p01_visuals() -> void:
	_check_weapon_view("res://scenes/ui/weapons/p01_view.tscn", "P-01", false)


func _check_p07_visuals() -> void:
	_check_weapon_view("res://scenes/ui/weapons/p07_view.tscn", "P-07", false)
	var definition := load("res://resources/weapons/p07.tres") as WeaponDefinition
	if definition == null:
		failures.append("P-07 WeaponDefinition yüklenemedi.")
	else:
		if definition.weapon_id != &"p07" or definition.loadout_group != &"sidearm":
			failures.append("P-07 kimliği veya sidearm grubu yanlış.")
		if not definition.supports_ads_pose or not definition.supports_flashlight:
			failures.append("P-07 ADS/fener özellik bayrakları eksik.")
		if definition.magazine_size != 16 or definition.damage_per_pellet != 17:
			failures.append("P-07 temel şarjör/hasar dengesi yanlış.")
	var player_packed := load("res://scenes/player/player.tscn") as PackedScene
	if player_packed != null:
		var player := player_packed.instantiate()
		var controller := player.get_node_or_null("WeaponController") as VexWeaponController
		var flashlight := player.get_node_or_null("ViewPivot/Camera3D/WeaponFlashlight") as SpotLight3D
		if controller == null or not controller.weapon_definitions.any(
			func(item: WeaponDefinition) -> bool: return item != null and item.weapon_id == &"p07"
		):
			failures.append("Player WeaponController P-07 kaynağına bağlı değil.")
		if flashlight == null or flashlight.visible:
			failures.append("P-07 silah feneri oyuncu sahnesinde kapalı başlangıç durumunda değil.")
		player.queue_free()
	var level_packed := load("res://scenes/levels/level_01.tscn") as PackedScene
	if level_packed != null:
		var level := level_packed.instantiate()
		var pickup := level.get_node_or_null("Pickups/P07SentinelPickup") as VexPickup
		if pickup == null or pickup.pickup_type != "p07":
			failures.append("Level 1 gizli bakım deposunda P-07 pickup eksik.")
		level.queue_free()


func _check_p14_playable_contract() -> void:
	_check_weapon_view("res://scenes/ui/weapons/p14_view.tscn", "P-14", false)
	var definition := load("res://resources/weapons/p14.tres") as WeaponDefinition
	if definition == null:
		failures.append("P-14 WeaponDefinition yüklenemedi.")
	else:
		if definition.weapon_id != &"p14" or definition.loadout_group != &"sidearm":
			failures.append("P-14 kimliği veya sidearm grubu yanlış.")
		if not definition.supports_ads_pose or not definition.supports_flashlight:
			failures.append("P-14 ADS/fener özellik bayrakları eksik.")
		if definition.magazine_size != 14 or definition.damage_per_pellet != 22:
			failures.append("P-14 temel şarjör/hasar dengesi yanlış.")
		if not is_equal_approx(definition.gunshot_noise_multiplier, 0.45):
			failures.append("P-14 susturucu gürültü çarpanı yanlış.")
		if definition.world_pickup_texture == null:
			failures.append("P-14 dünya pickup görseli bağlı değil.")
	var player_packed := load("res://scenes/player/player.tscn") as PackedScene
	if player_packed != null:
		var player := player_packed.instantiate()
		var controller := player.get_node_or_null("WeaponController") as VexWeaponController
		if controller == null or not controller.weapon_definitions.any(
			func(item: WeaponDefinition) -> bool: return item != null and item.weapon_id == &"p14"
		):
			failures.append("Player WeaponController P-14 kaynağına bağlı değil.")
		player.queue_free()
	var player_script := FileAccess.get_file_as_string("res://scripts/player/player.gd")
	if "_spawn_dropped_sidearm_pickup" not in player_script:
		failures.append("Tek tabanca kuralının dünya pickup drop akışı eksik.")


func _check_p20_playable_contract() -> void:
	_check_weapon_view("res://scenes/ui/weapons/p20_view.tscn", "P-20", false)
	var definition := load("res://resources/weapons/p20.tres") as WeaponDefinition
	if definition == null:
		failures.append("P-20 WeaponDefinition yüklenemedi.")
	else:
		if definition.weapon_id != &"p20" or definition.loadout_group != &"sidearm":
			failures.append("P-20 kimliği veya sidearm grubu yanlış.")
		if definition.ammo_type != &"bullets" or definition.hud_ammo_label_key != "HUD_AMMO_PISTOL":
			failures.append("P-20 ortak tabanca mühimmatı/HUD etiketine bağlı değil.")
		if not definition.supports_ads_pose or not definition.supports_flashlight:
			failures.append("P-20 ADS/fener özellik bayrakları eksik.")
		if definition.magazine_size != 8 or definition.damage_per_pellet != 42:
			failures.append("P-20 temel şarjör/hasar dengesi yanlış.")
		if not is_equal_approx(definition.penetration_power, 0.5):
			failures.append("P-20 temel hedef delme olasılığı yanlış.")
		if definition.reserve_ammo_capacity != 180:
			failures.append("P-20 ortak tabanca rezerv kapasitesi yanlış.")
		if definition.world_pickup_texture == null:
			failures.append("P-20 dünya pickup görseli bağlı değil.")
	var player_packed := load("res://scenes/player/player.tscn") as PackedScene
	if player_packed != null:
		var player := player_packed.instantiate()
		var controller := player.get_node_or_null("WeaponController") as VexWeaponController
		if controller == null or not controller.weapon_definitions.any(
			func(item: WeaponDefinition) -> bool: return item != null and item.weapon_id == &"p20"
		):
			failures.append("Player WeaponController P-20 kaynağına bağlı değil.")
		player.queue_free()
	var level_packed := load("res://scenes/levels/level_01.tscn") as PackedScene
	if level_packed != null:
		var level := level_packed.instantiate()
		var pickup := level.get_node_or_null("Pickups/P20MagnumTestPickup") as VexPickup
		if pickup == null or pickup.pickup_type != "p20":
			failures.append("Level 1 başlangıç alanında P-20 test pickup'ı eksik.")
		level.queue_free()
	var controller_script := FileAccess.get_file_as_string("res://scripts/player/weapon_controller.gd")
	if "penetration_power" not in controller_script or "target_limit" not in controller_script:
		failures.append("P-20 hedef delme runtime akışı eksik.")
	if "_migrate_legacy_ammo_dictionary" not in controller_script or "legacy_magnum_count" not in controller_script:
		failures.append("P-20 eski Magnum rezervini bullets havuzuna taşıyan save migration eksik.")


func _check_weapon_view(scene_path: String, weapon_label: String, expects_lowered: bool) -> void:
	var packed := load(scene_path) as PackedScene
	if packed == null:
		failures.append("%s HUD sahnesi yüklenemedi." % weapon_label)
		return
	var sprite := packed.instantiate() as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		failures.append("%s AnimatedSprite2D/SpriteFrames eksik." % weapon_label)
		return
	var required_animations: Array[StringName] = [&"idle", &"fire", &"aim_fire", &"reload", &"zoom"]
	if expects_lowered:
		required_animations.append(&"lowered")
	for animation_name in required_animations:
		if not sprite.sprite_frames.has_animation(animation_name):
			failures.append("%s animasyonu eksik: %s" % [weapon_label, animation_name])
	for animation_name in [&"fire", &"aim_fire", &"reload"]:
		if sprite.sprite_frames.get_frame_count(animation_name) != 4:
			failures.append("%s %s animasyonu dört kare değil." % [weapon_label, animation_name])
	if sprite.position != Vector2(1060.0, 772.0):
		failures.append("%s FPS görünümü ekranın alt-sağ bölgesine hizalı değil." % weapon_label)
	if sprite.scale != Vector2(0.6, 0.6):
		failures.append("%s HUD ölçeği 0.6 değil." % weapon_label)
	sprite.queue_free()


func _check_localization_contract() -> void:
	var project_text := FileAccess.get_file_as_string("res://project.godot")
	for required in [
		"[internationalization]",
		"locale/fallback=\"tr\"",
		"res://translations/vex.en.translation",
		"res://translations/vex.tr.translation",
	]:
		if required not in project_text:
			failures.append("Yerelleştirme project ayarı eksik: %s" % required)
	var csv_text := FileAccess.get_file_as_string("res://translations/vex.csv")
	if not csv_text.begins_with("keys,tr,en"):
		failures.append("Çeviri CSV başlığı keys,tr,en değil.")
	for required_key in [
		"LANGUAGE_TURKISH", "LANGUAGE_ENGLISH", "SETTINGS_LANGUAGE",
		"LEVEL_01_NAME", "BRIEFING_CONTINUE", "HUD_DEATH_BODY",
		"WEAPON_P07_NAME", "PICKUP_P07_ACTIVE", "WEAPON_P14_NAME",
		"PICKUP_P14_ACTIVE", "WEAPON_P20_NAME", "PICKUP_P20_ACTIVE",
		"HUD_AMMO_PISTOL", "DOOR_COMBAT_LOCKED", "DOOR_COMBAT_CLEARED",
		"LEVEL01_TUTORIAL_MOVE_HINT", "LEVEL01_TUTORIAL_FIRE_HINT",
		"LEVEL01_TUTORIAL_RELOAD_HINT", "LEVEL01_TUTORIAL_FINAL_HINT",
		"LEVEL01_OBJECTIVE_RED_ONLY", "LEVEL01_OBJECTIVE_BLUE_ONLY",
		"LEVEL01_OBJECTIVE_BOTH_KEYS", "UPGRADE_INERTIAL_PISTON",
		"UPGRADE_OVERPRESSURE_CORE", "UPGRADE_RUPTURE_ROUND",
		"PICKUP_SIDEARM_SWAP_FORMAT", "KEYBIND_WEAPON_FLASHLIGHT",
	]:
		if required_key not in csv_text:
			failures.append("Çeviri anahtarı eksik: %s" % required_key)
