extends Node

const REQUIRED_RESOURCES := [
	"res://resources/materials/floor_standard.tres",
	"res://resources/materials/ceiling_standard.tres",
	"res://resources/materials/wall_panel.tres",
	"res://scenes/props/door_side_slide.tscn",
	"res://scenes/props/burn_remains.tscn",
	"res://scenes/props/pickup.tscn",
	"res://scenes/props/explosive_barrel.tscn",
	"res://scenes/player/player.tscn",
	"res://resources/weapons/pistol.tres",
	"res://resources/weapons/shotgun.tres",
	"res://resources/weapons/ak47.tres",
	"res://resources/weapons/mp90.tres",
	"res://scenes/world/ceiling_light_white_horror.tscn",
	"res://scenes/world/world_piece.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/hub/bastion_7.tscn",
	"res://scenes/hub/hub_terminal.tscn",
	"res://scenes/hub/hub_weapon_rack.tscn",
	"res://scenes/actors/redviper.tscn",
	"res://scenes/actors/badredviper.tscn",
	"res://scenes/actors/ravager.tscn",
	"res://scenes/actors/hellmagma.tscn",
	"res://scenes/actors/voidweaver.tscn",
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
	_check_level("res://scenes/levels/level_01.tscn", 18, 18, 38, 19)
	_check_level("res://scenes/levels/level_02.tscn", 33, 33, 10, 5)
	_check_bastion_7()
	_check_enemy_visuals()
	_check_scene_authority()
	_check_door()

	if failures.is_empty():
		print("VEX integrity test başarılı: Level 1/2, Bastion-7, kaynak bağlantıları ve sahne otoritesi temiz.")
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
	for door_name in ["FiringRangeDoor", "ResearchDoor", "WorkshopDoor", "EngineeringDoor"]:
		var door := hub.get_node_or_null("Doors/%s" % door_name)
		if door == null or not bool(door.get("permanently_locked")):
			failures.append("Bastion-7 kilitli alan standardı eksik: %s" % door_name)
	if hub.get_node_or_null("Systems/MissionTerminal") != null:
		failures.append("Bastion-7 MissionTerminal kaldırılmamış.")
	var operations_terminal := hub.get_node_or_null("Systems/DeploymentTerminal")
	if operations_terminal == null or str(operations_terminal.get("display_name")) != "OPERASYON TERMİNALİ":
		failures.append("Bastion-7 tek Operasyon Terminali standardı eksik.")
	hub.queue_free()


func _check_enemy_visuals() -> void:
	for enemy_name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver"]:
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
	for enemy_name in ["redviper", "badredviper", "ravager", "hellmagma", "voidweaver"]:
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
	for projectile_name in ["ravager_projectile", "hellmagma_projectile", "voidweaver_projectile"]:
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
				&"burst_reset_fire_interval_multiplier",
			]:
				if not _has_property(controller, property_name):
					failures.append("WeaponController sahne ayarı Inspector'da eksik: %s" % property_name)
		player.queue_free()

	for level_path in ["res://scenes/levels/level_01.tscn", "res://scenes/levels/level_02.tscn"]:
		var level_packed := load(level_path) as PackedScene
		if level_packed != null:
			var level := level_packed.instantiate()
			for property_name in [
				&"map_revision", &"level_display_name", &"campaign_completion_stage", &"first_objective", &"total_secrets",
				&"intro_message_delay", &"automap_title", &"automap_columns", &"automap_rows",
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
				for property_name in [&"piece_size", &"surface_material", &"cast_shadow", &"occlusion_enabled", &"floor_trim_enabled"]:
					if not _has_property(instance, property_name):
						failures.append("WorldPiece sahne ayarı Inspector'da eksik: %s" % property_name)
			else:
				for property_name in [&"light_color", &"light_energy", &"light_range", &"cone_angle", &"fixture_pixel_size"]:
					if not _has_property(instance, property_name):
						failures.append("RoomLight sahne ayarı Inspector'da eksik: %s" % property_name)
			instance.queue_free()

	for weapon_path in [
		"res://resources/weapons/pistol.tres",
		"res://resources/weapons/shotgun.tres",
		"res://resources/weapons/ak47.tres",
		"res://resources/weapons/mp90.tres",
	]:
		var weapon = load(weapon_path)
		if weapon == null:
			continue
		if not _has_property(weapon, &"reserve_ammo_capacity"):
			failures.append("Weapon resource ammo kapasitesi Inspector'da eksik: %s" % weapon_path)


func _check_door() -> void:
	var packed := load("res://scenes/props/door_side_slide.tscn") as PackedScene
	if packed == null:
		return
	var door := packed.instantiate()
	var front := door.get_node_or_null("DoorPanel/FrontVisual") as Sprite3D
	if front == null or not front.flip_h:
		failures.append("DoorPanel/FrontVisual Flip H standardı eksik.")
	door.queue_free()
