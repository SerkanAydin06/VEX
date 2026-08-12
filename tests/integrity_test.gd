extends SceneTree

const REQUIRED_RESOURCES: PackedStringArray = [
	"res://scenes/ui/splash_screen.tscn",
	"res://scenes/ui/main_menu.tscn",
	"res://scenes/ui/settings_panel.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/level_complete.tscn",
	"res://scenes/ui/weapons/mp90_view.tscn",
	"res://scenes/player/player.tscn",
	"res://scenes/actors/ravager.tscn",
	"res://scenes/actors/ravager_projectile.tscn",
	"res://scenes/actors/hellmagma.tscn",
	"res://scenes/actors/hellmagma_projectile.tscn",
	"res://scenes/actors/redviper.tscn",
	"res://scenes/actors/badredviper.tscn",
	"res://scenes/props/door.tscn",
	"res://scenes/props/pickup.tscn",
	"res://scenes/props/explosive_barrel.tscn",
	"res://scenes/props/finish_switch.tscn",
	"res://scenes/props/secret_trigger.tscn",
	"res://scenes/world/world_piece.tscn",
	"res://scenes/world/wall_lamp_red.tscn",
	"res://scenes/world/exit_sign.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scripts/ui/automap_view.gd",
	"res://resources/weapons/pistol.tres",
	"res://resources/weapons/shotgun.tres",
	"res://resources/weapons/ak47.tres",
	"res://resources/weapons/mp90.tres",
	"res://assets/ui/crosshair_doom3_circle.png",
	"res://assets/ui/automap_console_frame_v2.png",
	"res://assets/enemies/Ravager/ravager_idle_1.png",
	"res://assets/enemies/Ravager/ravager_projectile.png",
	"res://assets/enemies/HellMagma/HellMagma_attack_1.png",
	"res://assets/enemies/HellMagma/HellMagma_death_4.png",
	"res://assets/enemies/HellMagma/HellMagma_idle_back_1.png",
	"res://assets/enemies/HellMagma/HellMagma_walk_back_4.png",
	"res://assets/pickups/night_vision.png",
	"res://assets/pickups/ak47.png",
	"res://assets/pickups/mp90.png",
	"res://assets/world/finish_switch.png",
	"res://assets/world/wall_lamp_red.png",
	"res://assets/enemies/redviper/redviper_attack_1.png",
	"res://assets/enemies/redviper/redviper_death_4.png",
	"res://assets/enemies/redviper/redviper_idle_back_1.png",
	"res://assets/enemies/redviper/redviper_walk_back_4.png",
	"res://assets/enemies/badredviper/badredviper_idle_1.png",
	"res://assets/enemies/badredviper/badredviper_walk_back_4.png",
	"res://assets/audio/pistol_fire_pro.wav",
	"res://assets/audio/shotgun_fire_pro.wav",
	"res://assets/audio/door_motion_pro.wav",
	"res://assets/audio/door_locked_pro.wav",
	"res://assets/audio/pickup_pro.wav",
	"res://assets/audio/game_music_pro.mp3",
	"res://assets/audio/facility_ambient_pro.mp3",
	"res://shaders/night_vision.gdshader",
]


func _initialize() -> void:
	call_deferred("_run_integrity_test")


func _run_integrity_test() -> void:
	var failures: Array[String] = []
	_validate_resources(failures)
	_validate_level_01(failures)
	_validate_level_02(failures)
	_validate_shared_scenes(failures)
	_validate_performance_package(failures)
	_validate_enemy_scene_standard(failures)
	_validate_weapons(failures)

	if failures.is_empty():
		print(
			"VEX 3.1.1 bütünlük testi başarılı: %d kaynak ve 2 bölüm doğrulandı."
			% REQUIRED_RESOURCES.size()
		)
		quit(0)
		return

	for failure: String in failures:
		push_error(failure)
	quit(1)


func _validate_resources(failures: Array[String]) -> void:
	for resource_path: String in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(resource_path):
			failures.append("Kaynak bulunamadı: " + resource_path)
			continue
		if ResourceLoader.load(resource_path) == null:
			failures.append("Kaynak yüklenemedi: " + resource_path)


func _validate_level_01(failures: Array[String]) -> void:
	var level := _instantiate_scene("res://scenes/levels/level_01.tscn", failures)
	if level == null:
		return

	_expect(str(level.get("map_revision")) == "VEX01-R26-PRO-AUTOMAP", "VEX-01 harita revizyonu yanlış.", failures)
	_expect(int(level.get("total_secrets")) == 0, "VEX-01 gizli alan sayısı 0 olmalı.", failures)
	_validate_piece_size(level, "Geometry/Floor", Vector3(36, 0.5, 60), failures)
	_validate_piece_size(level, "Geometry/Ceiling", Vector3(36, 0.3, 60), failures)
	_validate_collection_count(level, "EnemyNavigation", 18, "VEX-01 rota noktası", failures)
	_validate_collection_count(level, "Doors", 19, "VEX-01 kapı", failures)
	_validate_collection_count(level, "Lights", 38, "VEX-01 kırmızı lamba", failures)
	_validate_collection_count(level, "Props", 4, "VEX-01 varil", failures)
	_validate_collection_count(level, "Enemies", 28, "VEX-01 düşman yerleşimi", failures)
	_validate_collection_count(level, "Pickups", 22, "VEX-01 pickup", failures)
	_validate_unique_ids(level.get_node_or_null("Enemies"), &"enemy_id", failures)
	_validate_unique_ids(level.get_node_or_null("Pickups"), &"pickup_id", failures)
	_validate_enemy_distribution(
		level,
		[
			{"ravager": 10, "hellmagma": 1, "redviper": 0, "badredviper": 0},
			{"ravager": 16, "hellmagma": 1, "redviper": 1, "badredviper": 0},
			{"ravager": 20, "hellmagma": 1, "redviper": 2, "badredviper": 0},
			{"ravager": 24, "hellmagma": 1, "redviper": 3, "badredviper": 0},
		],
		"VEX-01",
		failures
	)
	var hellmagma_test := level.get_node_or_null("Enemies/HellMagma_TestStartRoom")
	_expect(hellmagma_test is VexHellMagma, "VEX-01 başlangıç odası HellMagma testi eksik.", failures)
	if hellmagma_test != null:
		_expect(
			hellmagma_test.get("enemy_id") == &"hellmagma_test_start",
			"HellMagma test kimliği yanlış.",
			failures
		)
		var test_position := (hellmagma_test as Node3D).global_position
		_expect(
			test_position.x >= -18.0 and test_position.x < -6.0
			and test_position.z >= 20.0 and test_position.z < 30.0,
			"HellMagma başlangıç odasında değil.",
			failures
		)
	var hellmagma_test_ammo := level.get_node_or_null("Pickups/HellMagmaTestBullets")
	_expect(hellmagma_test_ammo != null, "HellMagma test mühimmatı eksik.", failures)
	if hellmagma_test_ammo != null:
		_expect(
			hellmagma_test_ammo.get("pickup_id") == &"hellmagma_test_bullets",
			"HellMagma test mühimmatı kimliği yanlış.",
			failures
		)
		_expect(
			str(hellmagma_test_ammo.get("pickup_type")) == "bullets"
			and int(hellmagma_test_ammo.get("amount")) == 30,
			"HellMagma test mühimmatı 30 tabanca mermisi olmalı.",
			failures
		)

	var final_door := level.get_node_or_null("Doors/Door_3_6")
	_expect(final_door != null, "VEX-01 final hava kilidi bulunamadı.", failures)
	if final_door != null:
		var keys: Array = final_door.get("required_keys") as Array
		_expect(keys.size() == 2 and keys.has(&"blue") and keys.has(&"red"), "VEX-01 final kapısı iki anahtar istemeli.", failures)
		_expect(not str(final_door.get("objective_on_unlock")).is_empty(), "VEX-01 final kapısı görev metni eksik.", failures)

	var finish_switch := level.get_node_or_null("Triggers/FinishSwitch")
	_expect(finish_switch != null, "VEX-01 FinishSwitch bulunamadı.", failures)
	if finish_switch != null:
		_expect(str(finish_switch.get("next_level_path")) == "res://scenes/levels/level_02.tscn", "VEX-01 → VEX-02 yolu yanlış.", failures)
		_expect(finish_switch.get("required_enemy_id") == &"ravager_19", "VEX-01 final muhafızı yanlış.", failures)

	var night_vision := level.get_node_or_null("Pickups/NightVisionPickup")
	_expect(night_vision != null, "VEX-01 gece görüşü pickup'ı sahnede bulunamadı.", failures)
	if night_vision != null:
		_expect(str(night_vision.get("pickup_type")) == "night_vision", "Gece görüşü pickup türü yanlış.", failures)
	var shotgun := level.get_node_or_null("Pickups/ShotgunPickup")
	_expect(
		shotgun != null and int(shotgun.get("amount")) == 8,
		"VEX-01 pompalı pickup'ı 8 yedek fişek vermeli.",
		failures
	)

	var map_config: Dictionary = level.call("get_automap_config")
	_validate_automap_config(map_config, 3, 6, 18, "VEX-01", failures)
	var door_connections: Array = map_config.get("door_connections", []) as Array
	_expect(door_connections.size() == 19, "VEX-01 haritasında 19 kapı bağlantısı olmalı.", failures)
	_expect(not bool(map_config.get("merge_adjacent_cells", true)), "VEX-01 odaları ayrı çizilmeli.", failures)
	level.free()


func _validate_level_02(failures: Array[String]) -> void:
	var level := _instantiate_scene("res://scenes/levels/level_02.tscn", failures)
	if level == null:
		return

	_expect(str(level.get("map_revision")) == "VEX02-R46-PRO-AUTOMAP", "VEX-02 harita revizyonu yanlış.", failures)
	_expect(int(level.get("total_secrets")) == 2, "VEX-02 gizli alan sayısı 2 olmalı.", failures)
	_validate_collection_count(level, "EnemyNavigation", 33, "VEX-02 rota noktası", failures)
	_validate_collection_count(level, "Doors", 5, "VEX-02 kapı", failures)
	_validate_collection_count(level, "Lights", 10, "VEX-02 kırmızı lamba", failures)
	_validate_collection_count(level, "Props", 6, "VEX-02 varil", failures)
	_validate_collection_count(level, "Enemies", 31, "VEX-02 düşman yerleşimi", failures)
	_validate_collection_count(level, "Pickups", 24, "VEX-02 pickup", failures)
	_validate_collection_count(level, "Triggers", 4, "VEX-02 tetikleyici", failures)
	_validate_unique_ids(level.get_node_or_null("Enemies"), &"enemy_id", failures)
	_validate_unique_ids(level.get_node_or_null("Pickups"), &"pickup_id", failures)
	_validate_enemy_distribution(
		level,
		[
			{"ravager": 11, "hellmagma": 0, "redviper": 2, "badredviper": 1},
			{"ravager": 15, "hellmagma": 0, "redviper": 3, "badredviper": 2},
			{"ravager": 20, "hellmagma": 0, "redviper": 3, "badredviper": 3},
			{"ravager": 24, "hellmagma": 0, "redviper": 3, "badredviper": 4},
		],
		"VEX-02",
		failures
	)

	var finish_switch := level.get_node_or_null("Triggers/FinishSwitch")
	_expect(finish_switch != null, "VEX-02 FinishSwitch bulunamadı.", failures)
	if finish_switch != null:
		_expect(str(finish_switch.get("next_level_path")).is_empty(), "VEX-02 son bölüm olarak bitmeli.", failures)
		_expect(finish_switch.get("required_enemy_id") == &"v2_badredviper_final_guard", "VEX-02 final BadRedViper kimliği yanlış.", failures)

	var final_guard := level.get_node_or_null("Enemies/BadRedViper_FinalGuard")
	_expect(final_guard is VexBadRedViper, "VEX-02 final muhafızı BadRedViper olmalı.", failures)
	if final_guard != null:
		_expect(int(final_guard.get("maximum_health")) == 260, "VEX-02 final muhafız canı 260 olmalı.", failures)
		_expect(int(final_guard.get("attack_damage")) == 32, "VEX-02 final muhafız hasarı 32 olmalı.", failures)

	var shotgun := level.get_node_or_null("Pickups/ShotgunPickup")
	_expect(
		shotgun != null and int(shotgun.get("amount")) == 8,
		"VEX-02 pompalı pickup'ı 8 yedek fişek vermeli.",
		failures
	)

	var map_config: Dictionary = level.call("get_automap_config")
	_validate_automap_config(map_config, 9, 7, 33, "VEX-02", failures)
	_expect(bool(map_config.get("merge_adjacent_cells", false)), "VEX-02 koridor hücreleri birleşmeli.", failures)
	level.free()


func _validate_automap_config(
	map_config: Dictionary,
	columns: int,
	rows: int,
	expected_cell_count: int,
	label: String,
	failures: Array[String]
) -> void:
	_expect(
		int(map_config.get("columns", 0)) == columns
		and int(map_config.get("rows", 0)) == rows,
		"%s harita ızgara boyutu yanlış." % label,
		failures
	)
	var world_min: Vector2 = map_config.get("world_min", Vector2.ZERO) as Vector2
	var world_max: Vector2 = map_config.get("world_max", Vector2.ZERO) as Vector2
	_expect(
		world_max.x > world_min.x and world_max.y > world_min.y,
		"%s dünya sınırları geçersiz." % label,
		failures
	)
	var cells: Array = map_config.get("walkable_cells", []) as Array
	_expect(
		cells.size() == expected_cell_count,
		"%s yürünebilir hücre sayısı yanlış." % label,
		failures
	)
	var unique_cells: Dictionary = {}
	for cell_value: Variant in cells:
		_expect(cell_value is Vector2i, "%s hücre tipi geçersiz." % label, failures)
		if cell_value is Vector2i:
			var cell := cell_value as Vector2i
			_expect(
				cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows,
				"%s hücresi ızgara dışında: %s" % [label, cell],
				failures
			)
			unique_cells[cell] = true
	_expect(unique_cells.size() == cells.size(), "%s haritasında yinelenen hücre var." % label, failures)
	for legacy_key: String in ["texture_path", "texture_region", "content_rect", "grid_x_edges", "grid_y_edges"]:
		_expect(not map_config.has(legacy_key), "%s eski PNG hizalama alanını kullanıyor: %s" % [label, legacy_key], failures)


func _validate_shared_scenes(failures: Array[String]) -> void:
	var finish_switch := _instantiate_scene("res://scenes/props/finish_switch.tscn", failures)
	if finish_switch != null:
		_expect(finish_switch.has_node("PanelBody/FinishSwitchVisual"), "FinishSwitchVisual düğümü eksik.", failures)
		_expect(finish_switch.has_method("interact"), "FinishSwitch etkileşim metodu eksik.", failures)
		finish_switch.free()

	var door := _instantiate_scene("res://scenes/props/door.tscn", failures)
	if door != null:
		_expect(door.has_node("SafetySensor"), "Kapı güvenlik sensörü eksik.", failures)
		_expect(door.get("required_keys") is Array, "Kapı çoklu anahtar alanı eksik.", failures)
		_expect(door.get("objective_on_unlock") is String, "Kapı görev alanı eksik.", failures)
		_expect(
			float(door.get("opening_height")) >= 4.2,
			"Kapı HellMagma için yeterli baş boşluğu bırakmıyor.",
			failures
		)
		var door_sensor := door.get_node_or_null("SafetySensor") as Area3D
		_expect(
			door_sensor != null and door_sensor.collision_mask == 6,
			"Kapı güvenlik sensörü oyuncu ve düşman katmanlarını izlemiyor.",
			failures
		)
		var door_collision := (
			door.get_node_or_null("DoorPanel/CollisionShape3D") as CollisionShape3D
		)
		var door_shape := (
			door_collision.shape as BoxShape3D if door_collision != null else null
		)
		_expect(
			door_shape != null and door_shape.size.z >= 3.5,
			"Kapı yatay açıklığı büyük düşman için yetersiz.",
			failures
		)
		door.free()

	var lamp := _instantiate_scene("res://scenes/world/wall_lamp_red.tscn", failures)
	if lamp != null:
		var light := lamp.get_node_or_null("Light")
		_expect(light is SpotLight3D, "Kırmızı lamba SpotLight3D olmalı.", failures)
		if light is SpotLight3D:
			_expect((light as SpotLight3D).spot_range <= 3.2, "Kırmızı lamba menzili sızıntı sınırını aşıyor.", failures)
		lamp.free()

	var pickup := _instantiate_scene("res://scenes/props/pickup.tscn", failures)
	if pickup != null:
		var pickup_visual := pickup.get_node_or_null("VisualPivot/Visual") as Sprite3D
		_expect(
			pickup_visual != null
			and int(pickup_visual.billboard) == int(BaseMaterial3D.BILLBOARD_FIXED_Y),
			"Pickup yalnızca Y ekseninde kameraya dönmeli.",
			failures
		)
		_expect(
			pickup_visual != null
			and pickup_visual.scale.is_equal_approx(Vector3.ONE)
			and is_equal_approx(pickup_visual.pixel_size, 0.00255),
			"Pickup billboard ölçeği eski görünür boyutu korumuyor.",
			failures
		)
		pickup.free()

	var barrel := _instantiate_scene("res://scenes/props/explosive_barrel.tscn", failures)
	if barrel != null:
		var barrel_visual := barrel.get_node_or_null("BarrelVisual") as Sprite3D
		_expect(
			barrel_visual != null
			and int(barrel_visual.billboard) == int(BaseMaterial3D.BILLBOARD_FIXED_Y),
			"Varil yalnızca Y ekseninde kameraya dönmeli.",
			failures
		)
		barrel.free()

	var hud := _instantiate_scene("res://scenes/ui/hud.tscn", failures)
	if hud != null:
		_expect(not hud.has_node("Root/Hitmarker"), "Kullanılmayan ayrı hitmarker düğümü kalmış.", failures)
		_expect(not hud.has_node("Root/WeaponLayer/MP90Sprite"), "MP90 sahne açılışında yüklenmemeli.", failures)
		_expect(hud.has_node("Root/MapOverlay/AutomapFrame"), "Yeni harita konsol görseli eksik.", failures)
		var automap_view := hud.get_node_or_null("Root/MapOverlay/AutomapView")
		_expect(automap_view is VexAutomapView, "Canlı AutomapView düğümü veya scripti eksik.", failures)
		_expect(not hud.has_node("Root/MapOverlay/MapTexture"), "Eski statik MapTexture düğümü kalmış.", failures)
		_expect(not hud.has_node("Root/MapOverlay/MapMarker"), "Eski PNG oyuncu işareti kalmış.", failures)
		var crosshair := hud.get_node_or_null("Root/Crosshair") as TextureRect
		_expect(
			crosshair != null and crosshair.size.is_equal_approx(Vector2(48, 48)),
			"Nişangah ölçüsü 48×48 olmalı.",
			failures
		)
		var crosshair_hit_color: Color = hud.get("crosshair_hit_color") as Color
		_expect(
			crosshair_hit_color.is_equal_approx(Color(1, 0, 0, 1)),
			"Nişangah isabet rengi belirgin saf kırmızı olmalı.",
			failures
		)
		_expect(
			float(hud.get("crosshair_hit_duration")) >= 0.24,
			"Nişangah isabet rengi yeterince uzun görünmüyor.",
			failures
		)
		var ak_sprite := hud.get_node_or_null("Root/WeaponLayer/AK47Sprite") as AnimatedSprite2D
		_expect(ak_sprite != null and ak_sprite.sprite_frames == null, "AK-47 kareleri seçimden önce yüklenmemeli.", failures)
		hud.free()


func _validate_performance_package(failures: Array[String]) -> void:
	_expect(
		bool(ProjectSettings.get_setting(
			"rendering/occlusion_culling/use_occlusion_culling",
			false
		)),
		"Proje oklüzyon ayarı etkin değil.",
		failures
	)

	var world_piece := _instantiate_scene("res://scenes/world/world_piece.tscn", failures)
	if world_piece != null:
		var wall_occluder := (
			world_piece.get_node_or_null("OccluderInstance3D") as OccluderInstance3D
		)
		var wall_box := (
			wall_occluder.occluder as BoxOccluder3D
			if wall_occluder != null
			else null
		)
		_expect(
			wall_box != null and wall_box.size.is_equal_approx(Vector3(4, 3, 0.3)),
			"WorldPiece kutu oklüderi eksik veya ölçüsü yanlış.",
			failures
		)
		world_piece.free()

	var door := _instantiate_scene("res://scenes/props/door.tscn", failures)
	if door != null:
		var door_occluder := door.get_node_or_null("DoorOccluder") as OccluderInstance3D
		_expect(
			door_occluder != null and door_occluder.visible,
			"Kapalı kapı oklüderi eksik veya devre dışı.",
			failures
		)
		door.free()

	for projectile_path: String in [
		"res://scenes/actors/ravager_projectile.tscn",
		"res://scenes/actors/hellmagma_projectile.tscn",
	]:
		var projectile := _instantiate_scene(projectile_path, failures)
		if projectile == null:
			continue
		var projectile_light := projectile.get_node_or_null("Light") as OmniLight3D
		_expect(
			projectile_light != null
			and not projectile_light.shadow_enabled
			and projectile_light.distance_fade_enabled,
			"Mermi ışığı performans standardında değil: " + projectile_path,
			failures
		)
		projectile.free()

	var lamp := _instantiate_scene("res://scenes/world/wall_lamp_red.tscn", failures)
	if lamp != null:
		var lamp_light := lamp.get_node_or_null("Light") as SpotLight3D
		_expect(
			lamp_light != null and lamp_light.distance_fade_enabled,
			"Duvar lambası uzaklık LOD'u kullanmıyor.",
			failures
		)
		lamp.free()

	var settings_panel := _instantiate_scene("res://scenes/ui/settings_panel.tscn", failures)
	if settings_panel != null:
		_expect(
			settings_panel.has_node("Margin/VBox/SettingsGrid/GraphicsQualityOption"),
			"Ayarlar sahnesinde 3B kalite seçimi eksik.",
			failures
		)
		settings_panel.free()

	_expect(
		is_equal_approx(SettingsManager.get_graphics_quality_scale(0), 0.75)
		and is_equal_approx(SettingsManager.get_graphics_quality_scale(1), 0.85)
		and is_equal_approx(SettingsManager.get_graphics_quality_scale(2), 1.0),
		"3B kalite ölçek profilleri yanlış.",
		failures
	)


func _validate_enemy_scene_standard(failures: Array[String]) -> void:
	var common_properties: Array[StringName] = [
		&"enemy_id",
		&"maximum_health",
		&"spawn_min_difficulty",
		&"apply_difficulty_scaling",
		&"move_speed",
		&"movement_acceleration",
		&"braking_acceleration",
		&"gravity_scale",
		&"floor_stick_velocity",
		&"patrol_offset",
		&"detection_range",
		&"pursuit_range",
		&"initial_view_angle",
		&"lost_sight_timeout",
		&"search_duration",
		&"ally_alert_radius",
		&"sight_origin_height",
		&"sight_target_height",
		&"attack_damage",
		&"attack_range",
		&"attack_cooldown",
		&"attack_windup",
		&"attack_range_tolerance",
		&"back_view_threshold",
		&"hurt_reaction_duration",
		&"corpse_visual_y",
		&"near_sight_interval",
		&"dormant_distance",
	]
	var scene_paths := [
		"res://scenes/actors/ravager.tscn",
		"res://scenes/actors/hellmagma.tscn",
		"res://scenes/actors/redviper.tscn",
		"res://scenes/actors/badredviper.tscn",
	]
	var enemy_pixel_sizes := {}
	for scene_path: String in scene_paths:
		var enemy := _instantiate_scene(scene_path, failures)
		if enemy == null:
			continue
		for property_name: StringName in common_properties:
			_expect(
				_has_property(enemy, property_name),
				"Düşman sahne ayarı eksik: %s > %s" % [scene_path, property_name],
				failures
			)

		var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
		_expect(sprite != null, "Düşman AnimatedSprite3D düğümü eksik: " + scene_path, failures)
		if sprite != null:
			_expect(sprite.pixel_size > 0.0, "Düşman Pixel Size geçersiz: " + scene_path, failures)
			_expect(sprite.sprite_frames != null, "Düşman SpriteFrames eksik: " + scene_path, failures)
			_expect(sprite.shaded, "Düşman karanlık sahne ışığına bağlı değil: " + scene_path, failures)
			_expect(
				int(sprite.cast_shadow)
				== int(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),
				"Düşman billboard'u pahalı dinamik gölge üretiyor: " + scene_path,
				failures
			)
			enemy_pixel_sizes[scene_path] = sprite.pixel_size

		var body_collision := enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
		var body_capsule := (
			body_collision.shape as CapsuleShape3D if body_collision != null else null
		)
		_expect(body_collision != null, "Düşman çarpışma düğümü eksik: " + scene_path, failures)
		var ground_shadow := enemy.get_node_or_null("GroundShadow") as Sprite3D
		_expect(ground_shadow != null, "Düşman zemin temas gölgesi eksik: " + scene_path, failures)
		if ground_shadow != null:
			_expect(
				ground_shadow.texture != null
				and ground_shadow.texture.resource_path
				== "res://assets/world/contact_shadow.png",
				"Düşman yanlış zemin gölgesi kullanıyor: " + scene_path,
				failures
			)
			_expect(
				int(ground_shadow.cast_shadow)
				== int(GeometryInstance3D.SHADOW_CASTING_SETTING_OFF),
				"Temas gölgesi kendi dinamik gölgesini üretmemeli: " + scene_path,
				failures
			)
		if sprite != null and body_collision != null and body_capsule != null:
			var visual_floor := sprite.position.y - 543.0 * sprite.pixel_size * 0.5
			var hitbox_floor := body_collision.position.y - body_capsule.height * 0.5
			_expect(
				is_equal_approx(visual_floor, hitbox_floor)
				or absf(visual_floor - hitbox_floor) <= 0.01,
				"Düşman görseli ve hitbox zemini eşleşmiyor: " + scene_path,
				failures
			)
			_expect(
				ground_shadow != null
				and ground_shadow.position.y > hitbox_floor
				and ground_shadow.position.y - hitbox_floor <= 0.035,
				"Düşman temas gölgesi zeminden kopuk: " + scene_path,
				failures
			)
			_expect(
				is_equal_approx(float(enemy.get("corpse_visual_y")), sprite.position.y),
				"Düşman ölüm karesi zemin hizasını değiştiriyor: " + scene_path,
				failures
			)
		for audio_name: String in ["AttackAudio", "HurtAudio", "DeathAudio"]:
			_expect(enemy.has_node(audio_name), "Düşman ses düğümü eksik: %s > %s" % [scene_path, audio_name], failures)

		if scene_path == "res://scenes/actors/hellmagma.tscn" and sprite != null:
			var expected_hellmagma_frames := {
				&"idle": 4,
				&"idle_back": 4,
				&"walk": 4,
				&"walk_back": 4,
				&"attack": 4,
				&"hurt": 1,
				&"death": 4,
			}
			for animation_name: StringName in expected_hellmagma_frames:
				_expect(
					sprite.sprite_frames.has_animation(animation_name)
					and sprite.sprite_frames.get_frame_count(animation_name)
					== int(expected_hellmagma_frames[animation_name]),
					"HellMagma animasyon karesi yanlış: " + String(animation_name),
					failures
				)
			var hell_hurt_texture := sprite.sprite_frames.get_frame_texture(&"hurt", 0)
			var hell_death_texture := sprite.sprite_frames.get_frame_texture(&"death", 0)
			_expect(hell_hurt_texture == hell_death_texture, "HellMagma hurt karesi death_1 olmalı.", failures)
			_expect(enemy is VexHellMagma, "HellMagma sınıf bağlantısı yanlış.", failures)
			_expect(enemy.get("enemy_id") == &"hellmagma", "HellMagma temel kimliği yanlış.", failures)
			_expect(int(enemy.get("maximum_health")) == 240, "HellMagma canı 240 olmalı.", failures)
			_expect(int(enemy.get("attack_damage")) == 28, "HellMagma hasarı 28 olmalı.", failures)
			_expect(float(enemy.get("attack_range")) >= 15.0, "HellMagma atış menzili yetersiz.", failures)
			_expect(float(enemy.get("move_speed")) > 2.7, "HellMagma Ravager'dan hızlı olmalı.", failures)
			_expect(
				float(enemy.get("attack_approach_speed")) >= 2.4,
				"HellMagma atışlar arasında oyuncuya yeterince yaklaşmıyor.",
				failures
			)
			_expect(
				float(enemy.get("attack_strafe_speed")) >= 1.0,
				"HellMagma atışlar arasında yan hareket yapmıyor.",
				failures
			)
			_expect(
				float(enemy.get("attack_preferred_distance")) < float(enemy.get("attack_range")),
				"HellMagma tercih mesafesi atış menzilinden küçük olmalı.",
				failures
			)
			_expect(
				enemy.has_method("_move_during_attack_recovery"),
				"HellMagma hareketli atış toparlanma davranışını kullanmıyor.",
				failures
			)
			_expect(
				is_equal_approx(sprite.pixel_size, 0.0073547),
				"HellMagma 543×543 kareleri için Pixel Size yanlış.",
				failures
			)
			_expect(is_equal_approx(sprite.position.y, 0.2), "HellMagma zemin hizası değişti.", failures)
			_expect(
				body_capsule != null
				and is_equal_approx(body_capsule.radius, 1.0)
				and is_equal_approx(body_capsule.height, 3.6),
				"HellMagma hitbox ölçüsü mevcut boyuyla eşleşmiyor.",
				failures
			)
			var hell_projectile := enemy.get("projectile_scene") as PackedScene
			_expect(
				hell_projectile != null
				and hell_projectile.resource_path == "res://scenes/actors/hellmagma_projectile.tscn",
				"HellMagma bağımsız güçlü mermi sahnesini kullanmıyor.",
				failures
			)
			if hell_projectile != null:
				var hell_projectile_instance := hell_projectile.instantiate()
				_expect(
					hell_projectile_instance is VexRavagerProjectile,
					"HellMagma mermi davranışı yüklenemiyor.",
					failures
				)
				_expect(
					is_equal_approx(float(hell_projectile_instance.get("speed")), 20.0),
					"HellMagma mermi hızı 20 olmalı.",
					failures
				)
				var hell_collision := (
					hell_projectile_instance.get_node_or_null("CollisionShape3D")
					as CollisionShape3D
				)
				var hell_sphere := (
					hell_collision.shape as SphereShape3D
					if hell_collision != null
					else null
				)
				_expect(
					hell_sphere != null and is_equal_approx(hell_sphere.radius, 0.48),
					"HellMagma mermi yarıçapı 0,48 olmalı.",
					failures
				)
				hell_projectile_instance.free()
		elif scene_path == "res://scenes/actors/ravager.tscn" and sprite != null:
			var expected_ravager_frames := {
				&"idle": 4,
				&"idle_back": 4,
				&"walk": 4,
				&"walk_back": 4,
				&"attack": 4,
				&"hurt": 1,
				&"death": 4,
			}
			for animation_name: StringName in expected_ravager_frames:
				_expect(
					sprite.sprite_frames.has_animation(animation_name)
					and sprite.sprite_frames.get_frame_count(animation_name)
					== int(expected_ravager_frames[animation_name]),
					"Ravager animasyon karesi yanlış: " + String(animation_name),
					failures
				)
			_expect(
				not sprite.sprite_frames.has_animation(&"death_back"),
				"Ravager paket dışı eski death_back animasyonunu kullanmamalı.",
				failures
			)
			var ravager_hurt_texture := sprite.sprite_frames.get_frame_texture(&"hurt", 0)
			var ravager_death_texture := sprite.sprite_frames.get_frame_texture(&"death", 0)
			_expect(
				ravager_hurt_texture == ravager_death_texture,
				"Ravager hurt karesi death_1 olmalı.",
				failures
			)
			_expect(
				is_equal_approx(sprite.pixel_size, 0.003315),
				"Ravager 1,80 m insan boyu standardında değil.",
				failures
			)
			_expect(
				is_equal_approx(sprite.position.y, -0.1),
				"Ravager görselinin zemin hizası yanlış.",
				failures
			)
			_expect(sprite.modulate == Color.WHITE, "Ravager üzerinde eski gri tint kalmış.", failures)
			var ravager_collision := (
				enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
			)
			var ravager_capsule := (
				ravager_collision.shape as CapsuleShape3D
				if ravager_collision != null
				else null
			)
			_expect(
				ravager_capsule != null
				and is_equal_approx(ravager_capsule.radius, 0.42)
				and is_equal_approx(ravager_capsule.height, 1.8),
				"Ravager çarpışma gövdesi insan boyuyla eşleşmiyor.",
				failures
			)
			_expect(
				ravager_collision != null
				and is_equal_approx(ravager_collision.position.y, -0.1),
				"Ravager çarpışma gövdesinin zemin hizası yanlış.",
				failures
			)
			_expect(int(enemy.get("maximum_health")) == 75, "Ravager canı 75 olmalı.", failures)
			_expect(int(enemy.get("attack_damage")) == 14, "Ravager hasarı 14 olmalı.", failures)
			_expect(float(enemy.get("attack_range")) >= 12.0, "Ravager atış menzili yetersiz.", failures)
			_expect(float(enemy.get("attack_range_tolerance")) >= 4.0, "Ravager başlamış atışı çok kolay iptal oluyor.", failures)
			_expect(float(enemy.get("projectile_lead_factor")) >= 0.9, "Ravager hareketli hedefe yeterli önleme yapmıyor.", failures)
			_expect(float(enemy.get("projectile_max_lead_time")) >= 1.6, "Ravager önleme süresi yetersiz.", failures)
			_expect(float(enemy.get("sight_origin_height")) >= 0.24, "Ravager görüş yüksekliği insan boyu için düşük.", failures)
			_expect(float(enemy.get("projectile_spawn_height")) >= 0.3, "Ravager mermisi namlunun altından çıkıyor.", failures)
			_expect(
				float(enemy.get("projectile_spawn_side_offset")) >= 0.38,
				"Ravager mermisi yaratığın kendi sağındaki namluya hizalı değil.",
				failures
			)
			_expect(
				float(enemy.get("attack_approach_speed")) > 0.0
				and float(enemy.get("attack_strafe_speed")) > 0.0,
				"Ravager atışlar arasında yeniden konumlanmıyor.",
				failures
			)
		elif scene_path == "res://scenes/actors/redviper.tscn" and sprite != null:
			var expected_redviper_frames := {
				&"idle": 4,
				&"idle_back": 4,
				&"walk": 4,
				&"walk_back": 4,
				&"attack": 4,
				&"hurt": 1,
				&"death": 4,
			}
			for animation_name: StringName in expected_redviper_frames:
				_expect(
					sprite.sprite_frames.has_animation(animation_name)
					and sprite.sprite_frames.get_frame_count(animation_name)
					== int(expected_redviper_frames[animation_name]),
					"RedViper animasyon karesi yanlış: " + String(animation_name),
					failures
				)
			var legacy_spawn_animation := StringName("tele" + "port")
			_expect(
				not sprite.sprite_frames.has_animation(legacy_spawn_animation),
				"RedViper yeni sette bulunmayan eski doğma animasyonunu kullanmamalı.",
				failures
			)
			var red_hurt_texture := sprite.sprite_frames.get_frame_texture(&"hurt", 0)
			var red_death_texture := sprite.sprite_frames.get_frame_texture(&"death", 0)
			_expect(red_hurt_texture == red_death_texture, "RedViper hurt karesi death_1 olmalı.", failures)
			_expect(is_equal_approx(sprite.pixel_size, 0.003315), "RedViper 1,80 m insan boyu standardında değil.", failures)
			_expect(is_equal_approx(sprite.position.y, 0.4032), "RedViper görselinin zemin hizası yanlış.", failures)
			_expect(sprite.modulate == Color.WHITE, "RedViper üzerinde eski gri tint kalmış.", failures)
			var red_collision := enemy.get_node_or_null("CollisionShape3D") as CollisionShape3D
			var red_capsule := (
				red_collision.shape as CapsuleShape3D
				if red_collision != null
				else null
			)
			_expect(
				red_capsule != null
				and is_equal_approx(red_capsule.radius, 0.42)
				and is_equal_approx(red_capsule.height, 1.8),
				"RedViper çarpışma gövdesi insan boyuyla eşleşmiyor.",
				failures
			)
			_expect(
				red_collision != null
				and is_equal_approx(red_collision.position.y, 0.4032),
				"RedViper çarpışma gövdesinin zemin hizası yanlış.",
				failures
			)
			_expect(is_equal_approx(float(enemy.get("move_speed")), 3.2), "RedViper hızı 3,2 olmalı.", failures)
			_expect(int(enemy.get("maximum_health")) == 140, "RedViper canı 140 olmalı.", failures)
			_expect(int(enemy.get("attack_damage")) == 22, "RedViper hasarı 22 olmalı.", failures)
			_expect(float(enemy.get("chase_speed")) >= 6.4, "RedViper hareketli oyuncuyu takip edemiyor.", failures)
			_expect(float(enemy.get("attack_range")) >= 2.0, "RedViper saldırı menzili yetersiz.", failures)
			_expect(
				float(enemy.get("attack_lunge_speed")) > 8.0,
				"RedViper saldırı hamlesi oyuncu koşu hızını aşmalı.",
				failures
			)
			_expect(not bool(enemy.get("hurt_stops_movement")), "RedViper hasar alınca hareketi kesmemeli.", failures)
			_expect(enemy.has_method("receive_ally_alert"), "RedViper müttefik uyarısı eksik.", failures)
			_expect(float(enemy.get("sight_origin_height")) >= 0.75, "RedViper görüş noktası insan boyu için düşük.", failures)
		elif scene_path == "res://scenes/actors/badredviper.tscn" and sprite != null:
			var expected_animation_frames := {
				&"idle": 4,
				&"idle_back": 4,
				&"walk": 4,
				&"walk_back": 4,
				&"attack": 4,
				&"hurt": 1,
				&"death": 4,
			}
			for animation_name: StringName in expected_animation_frames:
				_expect(
					sprite.sprite_frames.has_animation(animation_name)
					and sprite.sprite_frames.get_frame_count(animation_name)
					== int(expected_animation_frames[animation_name]),
					"BadRedViper animasyon karesi yanlış: " + String(animation_name),
					failures
				)
			var hurt_texture := sprite.sprite_frames.get_frame_texture(&"hurt", 0)
			var death_texture := sprite.sprite_frames.get_frame_texture(&"death", 0)
			_expect(hurt_texture == death_texture, "BadRedViper hurt karesi death_1 olmalı.", failures)
			_expect(enemy is VexBadRedViper, "BadRedViper sınıf bağlantısı yanlış.", failures)
			_expect(enemy.get("enemy_id") == &"badredviper", "BadRedViper temel kimliği yanlış.", failures)
			_expect(is_equal_approx(sprite.pixel_size, 0.0062), "BadRedViper orta boy standardında değil.", failures)
			_expect(is_equal_approx(sprite.position.y, 1.1865), "BadRedViper zemin hizası yanlış.", failures)
			_expect(
				body_capsule != null
				and is_equal_approx(body_capsule.radius, 0.82)
				and is_equal_approx(body_capsule.height, 3.1),
				"BadRedViper hitbox ölçüsü orta boyla eşleşmiyor.",
				failures
			)
			_expect(
				body_collision != null
				and is_equal_approx(body_collision.position.y, 1.0532),
				"BadRedViper hitbox zemin hizası yanlış.",
				failures
			)
			_expect(float(enemy.get("sight_origin_height")) >= 1.65, "BadRedViper görüş noktası yeni gövde için düşük.", failures)
			_expect(int(enemy.get("maximum_health")) == 190, "BadRedViper canı 190 olmalı.", failures)
			_expect(int(enemy.get("attack_damage")) == 28, "BadRedViper hasarı 28 olmalı.", failures)
			_expect(float(enemy.get("chase_speed")) >= 6.8, "BadRedViper elit takip hızı yetersiz.", failures)
			_expect(float(enemy.get("attack_range")) >= 2.2, "BadRedViper saldırı menzili yetersiz.", failures)
			_expect(
				float(enemy.get("attack_lunge_speed")) > 8.0,
				"BadRedViper saldırı hamlesi oyuncu koşu hızını aşmalı.",
				failures
			)
			_expect(not bool(enemy.get("hurt_stops_movement")), "BadRedViper hasar alınca hareketi kesmemeli.", failures)
			_expect(enemy.has_method("receive_ally_alert"), "BadRedViper RedViper yapay zekâsını kullanmıyor.", failures)
		enemy.free()

	_expect(
		enemy_pixel_sizes.has("res://scenes/actors/ravager.tscn")
		and enemy_pixel_sizes.has("res://scenes/actors/redviper.tscn")
		and enemy_pixel_sizes.has("res://scenes/actors/badredviper.tscn")
		and enemy_pixel_sizes.has("res://scenes/actors/hellmagma.tscn")
		and is_equal_approx(
			float(enemy_pixel_sizes["res://scenes/actors/ravager.tscn"]),
			float(enemy_pixel_sizes["res://scenes/actors/redviper.tscn"])
		)
		and float(enemy_pixel_sizes["res://scenes/actors/redviper.tscn"])
		< float(enemy_pixel_sizes["res://scenes/actors/badredviper.tscn"])
		and float(enemy_pixel_sizes["res://scenes/actors/badredviper.tscn"])
		< float(enemy_pixel_sizes["res://scenes/actors/hellmagma.tscn"]),
		"Düşman insan/orta/büyük boy sırası yanlış.",
		failures
	)


func _validate_enemy_distribution(
	level: Node,
	expected_by_difficulty: Array,
	label: String,
	failures: Array[String]
) -> void:
	var enemies := level.get_node_or_null("Enemies")
	if enemies == null:
		return
	for difficulty: int in range(expected_by_difficulty.size()):
		var counts := {
			"ravager": 0,
			"hellmagma": 0,
			"redviper": 0,
			"badredviper": 0,
		}
		for enemy: Node in enemies.get_children():
			if int(enemy.get("spawn_min_difficulty")) > difficulty:
				continue
			var role := ""
			if enemy is VexHellMagma:
				role = "hellmagma"
			elif enemy is VexBadRedViper:
				role = "badredviper"
			elif enemy is VexRedViper:
				role = "redviper"
			elif enemy is VexRavager:
				role = "ravager"
			else:
				failures.append("%s bilinmeyen düşman türü: %s" % [label, enemy.name])
				continue
			counts[role] = int(counts[role]) + 1

		var expected: Dictionary = expected_by_difficulty[difficulty] as Dictionary
		_expect(
			counts == expected,
			"%s zorluk %d dağılımı yanlış: beklenen=%s gerçek=%s"
			% [label, difficulty, expected, counts],
			failures
		)


func _validate_weapons(failures: Array[String]) -> void:
	var expected_reload := {
		"res://resources/weapons/pistol.tres": 1.1,
		"res://resources/weapons/shotgun.tres": 1.45,
		"res://resources/weapons/ak47.tres": 1.2,
		"res://resources/weapons/mp90.tres": 1.35,
	}
	for path: String in expected_reload:
		var weapon := load(path)
		if weapon == null:
			continue
		_expect(
			is_equal_approx(float(weapon.get("reload_duration")), float(expected_reload[path])),
			"Silah reload süresi yanlış: " + path,
			failures
		)


func _instantiate_scene(path: String, failures: Array[String]) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Sahne yüklenemedi: " + path)
		return null
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Sahne örneklenemedi: " + path)
	return instance


func _validate_piece_size(
	level: Node,
	path: String,
	expected_size: Vector3,
	failures: Array[String]
) -> void:
	var piece := level.get_node_or_null(NodePath(path))
	_expect(piece != null, "Geometri parçası eksik: " + path, failures)
	if piece != null:
		_expect(piece.get("piece_size") == expected_size, "Geometri ölçüsü yanlış: " + path, failures)


func _validate_collection_count(
	level: Node,
	path: String,
	expected_count: int,
	label: String,
	failures: Array[String]
) -> void:
	var collection := level.get_node_or_null(NodePath(path))
	_expect(collection != null, label + " grubu eksik.", failures)
	if collection != null:
		_expect(collection.get_child_count() == expected_count, "%s sayısı %d olmalı." % [label, expected_count], failures)


func _validate_unique_ids(collection: Node, property_name: StringName, failures: Array[String]) -> void:
	if collection == null:
		return
	var seen: Dictionary = {}
	for child: Node in collection.get_children():
		var id := StringName(str(child.get(property_name)))
		if id == &"":
			failures.append("Boş kimlik: " + str(child.get_path()))
		elif seen.has(id):
			failures.append("Yinelenen kimlik: " + String(id))
		else:
			seen[id] = true


func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _expect(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
