extends Node

signal settings_applied
signal difficulty_changed(difficulty: int)

enum Difficulty {
	EASY,
	NORMAL,
	HARD,
	NIGHTMARE,
}

enum GraphicsQuality {
	PERFORMANCE,
	BALANCED,
	HIGH,
}

const SETTINGS_PATH := "user://vex_settings.cfg"
const DEFAULT_RESOLUTION := Vector2i(1920, 1080)
const DIFFICULTY_LABELS: PackedStringArray = ["KOLAY", "NORMAL", "ZOR", "KÂBUS"]
const GRAPHICS_QUALITY_LABELS: PackedStringArray = ["PERFORMANS", "DENGELİ", "YÜKSEK"]

var resolution: Vector2i = DEFAULT_RESOLUTION
var fullscreen := true
var vsync := true
var master_volume := 0.85
var music_volume := 0.65
var sfx_volume := 0.85
var brightness := 1.15
var mouse_sensitivity := 0.11
var screen_shake := true
var difficulty: int = Difficulty.NORMAL
var graphics_quality: int = GraphicsQuality.HIGH


func _ready() -> void:
	load_settings()
	call_deferred("apply_settings")


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_PATH)
	if error != OK:
		return
	resolution = config.get_value("display", "resolution", DEFAULT_RESOLUTION) as Vector2i
	fullscreen = bool(config.get_value("display", "fullscreen", true))
	vsync = bool(config.get_value("display", "vsync", true))
	graphics_quality = clampi(
		int(config.get_value("display", "graphics_quality", GraphicsQuality.HIGH)),
		GraphicsQuality.PERFORMANCE,
		GraphicsQuality.HIGH
	)
	master_volume = float(config.get_value("audio", "master", 0.85))
	music_volume = float(config.get_value("audio", "music", 0.65))
	sfx_volume = float(config.get_value("audio", "sfx", 0.85))
	brightness = clampf(
		float(config.get_value("display", "brightness", 1.15)),
		0.35,
		2.00
	)
	mouse_sensitivity = float(config.get_value("controls", "mouse_sensitivity", 0.11))
	screen_shake = bool(config.get_value("accessibility", "screen_shake", true))
	difficulty = clampi(
		int(config.get_value("gameplay", "difficulty", Difficulty.NORMAL)),
		Difficulty.EASY,
		Difficulty.NIGHTMARE
	)


func save_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "vsync", vsync)
	config.set_value("display", "graphics_quality", graphics_quality)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "brightness", brightness)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("accessibility", "screen_shake", screen_shake)
	config.set_value("gameplay", "difficulty", difficulty)
	var error := config.save(SETTINGS_PATH)
	if error != OK:
		push_error("VEX ayarları kaydedilemedi. Hata kodu: %s" % error)
		return false
	return true


func apply_settings() -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED
	)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)
		_center_window()
	_set_bus_volume(&"Master", master_volume)
	_set_bus_volume(&"Music", music_volume)
	_set_bus_volume(&"SFX", sfx_volume)
	_set_bus_volume(&"UI", sfx_volume)
	apply_graphics_quality()
	apply_brightness()
	settings_applied.emit()


func set_resolution(value: Vector2i) -> void:
	resolution = value
	if not fullscreen:
		DisplayServer.window_set_size(resolution)
		_center_window()
	save_settings()


func set_fullscreen(value: bool) -> void:
	fullscreen = value
	apply_settings()
	save_settings()


func set_vsync(value: bool) -> void:
	vsync = value
	apply_settings()
	save_settings()


func set_graphics_quality(value: int) -> void:
	graphics_quality = clampi(
		value,
		GraphicsQuality.PERFORMANCE,
		GraphicsQuality.HIGH
	)
	apply_graphics_quality()
	save_settings()


func apply_graphics_quality() -> void:
	if not is_inside_tree():
		return
	var root_viewport := get_tree().root
	root_viewport.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	root_viewport.scaling_3d_scale = get_graphics_quality_scale()


func get_graphics_quality_scale(value: int = -1) -> float:
	var resolved := graphics_quality if value < 0 else value
	match clampi(resolved, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH):
		GraphicsQuality.PERFORMANCE:
			return 0.75
		GraphicsQuality.BALANCED:
			return 0.85
		_:
			return 1.0


func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(&"Master", master_volume)
	save_settings()


func set_music_volume(value: float) -> void:
	music_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(&"Music", music_volume)
	save_settings()


func set_sfx_volume(value: float) -> void:
	sfx_volume = clampf(value, 0.0, 1.0)
	_set_bus_volume(&"SFX", sfx_volume)
	_set_bus_volume(&"UI", sfx_volume)
	save_settings()


func set_brightness(value: float) -> void:
	brightness = clampf(value, 0.35, 2.00)
	apply_brightness()
	save_settings()


func apply_brightness() -> void:
	if not is_inside_tree():
		return

	# Slider artık yalnız post-process parlaklığını değil, sahnenin gerçek
	# pozlamasını ve ortam ışığını da değiştirir. Böylece minimum/maksimum
	# arasında gözle görülür bir fark oluşur; ek OmniLight maliyeti yoktur.
	var normalized := inverse_lerp(0.35, 2.00, brightness)
	var post_brightness := lerpf(0.42, 2.15, normalized)
	var exposure := lerpf(0.52, 1.55, normalized)
	var ambient_energy := lerpf(0.24, 1.42, normalized)
	var fog_energy := lerpf(0.20, 0.58, normalized)

	for node: Node in get_tree().get_nodes_in_group("brightness_environment"):
		if node is WorldEnvironment:
			var world_environment := node as WorldEnvironment
			if world_environment.environment != null:
				var environment := world_environment.environment
				environment.adjustment_enabled = true
				environment.adjustment_brightness = post_brightness
				environment.tonemap_exposure = exposure
				environment.ambient_light_energy = ambient_energy
				environment.fog_light_energy = fog_energy


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, 0.03, 0.3)
	save_settings()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, Difficulty.EASY, Difficulty.NIGHTMARE)
	save_settings()
	difficulty_changed.emit(difficulty)


func get_difficulty_display_name(value: int = -1) -> String:
	var resolved := difficulty if value < 0 else value
	resolved = clampi(resolved, Difficulty.EASY, Difficulty.NIGHTMARE)
	return DIFFICULTY_LABELS[resolved]


func get_difficulty_profile(value: int = -1) -> Dictionary:
	var resolved := difficulty if value < 0 else value
	match clampi(resolved, Difficulty.EASY, Difficulty.NIGHTMARE):
		Difficulty.EASY:
			return {
				"health_multiplier": 0.75,
				"damage_multiplier": 0.65,
				"speed_multiplier": 0.90,
				"detection_multiplier": 0.90,
				"cooldown_multiplier": 1.25,
				"windup_multiplier": 1.20,
				"resource_multiplier": 1.35,
			}
		Difficulty.HARD:
			return {
				"health_multiplier": 1.20,
				"damage_multiplier": 1.25,
				"speed_multiplier": 1.08,
				"detection_multiplier": 1.08,
				"cooldown_multiplier": 0.85,
				"windup_multiplier": 0.90,
				"resource_multiplier": 0.80,
			}
		Difficulty.NIGHTMARE:
			return {
				"health_multiplier": 1.45,
				"damage_multiplier": 1.55,
				"speed_multiplier": 1.15,
				"detection_multiplier": 1.20,
				"cooldown_multiplier": 0.70,
				"windup_multiplier": 0.75,
				"resource_multiplier": 0.60,
			}
		_:
			return {
				"health_multiplier": 1.0,
				"damage_multiplier": 1.0,
				"speed_multiplier": 1.0,
				"detection_multiplier": 1.0,
				"cooldown_multiplier": 1.0,
				"windup_multiplier": 1.0,
				"resource_multiplier": 1.0,
			}


func _set_bus_volume(bus_name: StringName, linear_value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	var safe_value := maxf(linear_value, 0.0001)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(safe_value))
	AudioServer.set_bus_mute(bus_index, linear_value <= 0.0001)


func _center_window() -> void:
	var screen := DisplayServer.window_get_current_screen()
	var screen_size := DisplayServer.screen_get_size(screen)
	var new_position := (screen_size - resolution) / 2
	DisplayServer.window_set_position(new_position)
