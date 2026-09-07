extends Node

const SETTINGS_SCHEMA_VERSION := 2
const TRANSLATION_RESOURCE_PATHS := [
	"res://translations/vex.tr.translation",
	"res://translations/vex.en.translation",
	"res://translations/chapter02.tr.translation",
	"res://translations/chapter02.en.translation",
]
const GRAPHICS_NATIVE_RENDER_SCALE := 1.0

signal settings_applied
signal difficulty_changed(difficulty: int)
signal language_changed(locale: String)

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

@export_category("01 - Storage and Language")
@export var settings_path := "user://vex_settings.cfg"
@export var default_language := "tr"
@export var supported_locales: PackedStringArray = ["tr", "en"]
@export var language_label_keys: Array[StringName] = [&"LANGUAGE_TURKISH", &"LANGUAGE_ENGLISH"]

@export_category("02 - Display Defaults")
@export var default_resolution := Vector2i(1920, 1080)
@export var supported_resolutions: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]
@export var default_fullscreen := true
@export var default_vsync := true
@export_enum("Performance", "Balanced", "High") var default_graphics_quality: int = GraphicsQuality.HIGH
@export var graphics_quality_label_keys: Array[StringName] = [
	&"QUALITY_PERFORMANCE",
	&"QUALITY_BALANCED",
	&"QUALITY_HIGH",
]

@export_category("03 - Graphics Quality Profiles")
@export_range(256, 4096, 256) var performance_shadow_atlas_size := 1024
@export_range(256, 4096, 256) var balanced_shadow_atlas_size := 2048
@export_range(256, 4096, 256) var high_shadow_atlas_size := 2048
@export var performance_shadow_atlas_16_bits := true
@export var balanced_shadow_atlas_16_bits := true
@export var high_shadow_atlas_16_bits := false
@export_range(0.1, 8.0, 0.05) var performance_mesh_lod_threshold := 2.0
@export_range(0.1, 8.0, 0.05) var balanced_mesh_lod_threshold := 1.35
@export_range(0.1, 8.0, 0.05) var high_mesh_lod_threshold := 1.0

@export_category("04 - Brightness Mapping")
@export_range(0.1, 1.0, 0.01) var brightness_min := 0.35
@export_range(1.0, 3.0, 0.01) var brightness_max := 2.0
@export_range(0.1, 3.0, 0.01) var default_brightness := 1.15
@export_range(0.1, 1.0, 0.01) var brightness_multiplier_min := 0.42
@export_range(1.0, 3.0, 0.01) var brightness_multiplier_max := 2.15

@export_category("05 - Audio Defaults")
@export_range(0.0, 1.0, 0.01) var default_master_volume := 0.85
@export_range(0.0, 1.0, 0.01) var default_music_volume := 0.65
@export_range(0.0, 1.0, 0.01) var default_sfx_volume := 0.85

@export_category("06 - Controls and Gameplay")
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity_min := 0.03
@export_range(0.01, 1.0, 0.01) var mouse_sensitivity_max := 0.30
@export_range(0.01, 1.0, 0.01) var default_mouse_sensitivity := 0.11
@export var default_screen_shake := true
@export_range(60.0, 120.0, 1.0) var default_fov := 78.0
@export_range(60.0, 120.0, 1.0) var fov_min := 60.0
@export_range(60.0, 120.0, 1.0) var fov_max := 110.0
@export var default_head_bob := true
@export_range(0.1, 10.0, 0.1) var default_controller_look_sensitivity := 2.6
@export_range(0.1, 10.0, 0.1) var controller_look_sensitivity_min := 0.5
@export_range(0.1, 10.0, 0.1) var controller_look_sensitivity_max := 6.0
@export_enum("Easy", "Normal", "Hard", "Nightmare") var default_difficulty: int = Difficulty.NORMAL
@export var difficulty_label_keys: Array[StringName] = [
	&"DIFFICULTY_EASY",
	&"DIFFICULTY_NORMAL",
	&"DIFFICULTY_HARD",
	&"DIFFICULTY_NIGHTMARE",
]
@export var rebindable_actions: Array[StringName] = [
	&"move_forward", &"move_backward", &"move_left", &"move_right",
	&"jump", &"sprint", &"crouch", &"interact", &"reload",
	&"automap", &"night_vision", &"weapon_flashlight",
	&"weapon_1", &"weapon_2", &"weapon_3", &"weapon_4", &"weapon_5",
]

@export_category("07 - Difficulty Profiles")
@export var difficulty_health_multipliers := PackedFloat32Array([0.75, 1.0, 1.20, 1.45])
@export var difficulty_damage_multipliers := PackedFloat32Array([0.65, 1.0, 1.25, 1.55])
@export var difficulty_speed_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.15])
@export var difficulty_detection_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.20])
@export var difficulty_cooldown_multipliers := PackedFloat32Array([1.25, 1.0, 0.85, 0.70])
@export var difficulty_windup_multipliers := PackedFloat32Array([1.20, 1.0, 0.90, 0.75])
@export var difficulty_resource_multipliers := PackedFloat32Array([1.35, 1.0, 0.80, 0.60])

var language := "tr"
var resolution := Vector2i(1920, 1080)
var fullscreen := true
var vsync := true
var master_volume := 0.85
var music_volume := 0.65
var sfx_volume := 0.85
var brightness := 1.15
var mouse_sensitivity := 0.11
var screen_shake := true
var field_of_view := 78.0
var head_bob := true
var controller_look_sensitivity := 2.6
var difficulty: int = Difficulty.NORMAL
var graphics_quality: int = GraphicsQuality.HIGH
var _default_keycodes: Dictionary = {}
var _registered_translations: Array[Translation] = []


func _ready() -> void:
	_register_imported_translations()
	_ensure_required_input_actions()
	_capture_default_keybindings()
	_ensure_default_gamepad_bindings()
	_reset_to_scene_defaults()
	load_settings()
	_apply_language(false)
	call_deferred("apply_settings")


## CSV çevirileri import sırasında .translation kaynaklarına dönüşür. Bu kaynakları
## proje ayarlarında erken bağlamak temiz klonun ilk taramasında bulunamadı hatası
## ürettiği için, import tamamlandıktan sonra autoload başlangıcında kaydederiz.
func _register_imported_translations() -> void:
	for path: String in TRANSLATION_RESOURCE_PATHS:
		var translation := load(path) as Translation
		if translation == null:
			push_error("VEX çeviri kaynağı yüklenemedi: %s" % path)
			continue
		TranslationServer.add_translation(translation)
		_registered_translations.append(translation)


## Eski proje paketlerinde sonradan eklenen aksiyonlar project.godot içinde
## bulunmayabilir. Ayarlar ve oyuncu kodu çalışmadan önce güvenli varsayılanı
## runtime InputMap'e ekleyerek eksik-action hatasını engeller.
func _ensure_required_input_actions() -> void:
	if InputMap.has_action(&"weapon_flashlight"):
		return
	InputMap.add_action(&"weapon_flashlight")
	var flashlight_key := InputEventKey.new()
	flashlight_key.physical_keycode = KEY_F
	InputMap.action_add_event(&"weapon_flashlight", flashlight_key)


func _reset_to_scene_defaults() -> void:
	language = _validated_locale(default_language)
	resolution = default_resolution
	fullscreen = default_fullscreen
	vsync = default_vsync
	graphics_quality = clampi(default_graphics_quality, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH)
	master_volume = clampf(default_master_volume, 0.0, 1.0)
	music_volume = clampf(default_music_volume, 0.0, 1.0)
	sfx_volume = clampf(default_sfx_volume, 0.0, 1.0)
	brightness = clampf(default_brightness, brightness_min, brightness_max)
	mouse_sensitivity = clampf(
		default_mouse_sensitivity,
		mouse_sensitivity_min,
		mouse_sensitivity_max
	)
	screen_shake = default_screen_shake
	field_of_view = clampf(default_fov, fov_min, fov_max)
	head_bob = default_head_bob
	controller_look_sensitivity = clampf(default_controller_look_sensitivity, controller_look_sensitivity_min, controller_look_sensitivity_max)
	difficulty = clampi(default_difficulty, Difficulty.EASY, Difficulty.NIGHTMARE)


func load_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(settings_path)
	if error != OK:
		return
	var settings_version := int(config.get_value("meta", "version", 1))
	language = _validated_locale(str(config.get_value("localization", "language", default_language)))
	resolution = _validated_resolution(config.get_value("display", "resolution", default_resolution))
	fullscreen = bool(config.get_value("display", "fullscreen", default_fullscreen))
	vsync = bool(config.get_value("display", "vsync", default_vsync))
	graphics_quality = clampi(
		int(config.get_value("display", "graphics_quality", default_graphics_quality)),
		GraphicsQuality.PERFORMANCE,
		GraphicsQuality.HIGH
	)
	master_volume = clampf(
		float(config.get_value("audio", "master", default_master_volume)),
		0.0,
		1.0
	)
	music_volume = clampf(
		float(config.get_value("audio", "music", default_music_volume)),
		0.0,
		1.0
	)
	sfx_volume = clampf(
		float(config.get_value("audio", "sfx", default_sfx_volume)),
		0.0,
		1.0
	)
	brightness = clampf(
		float(config.get_value("display", "brightness", default_brightness)),
		brightness_min,
		brightness_max
	)
	mouse_sensitivity = clampf(
		float(config.get_value("controls", "mouse_sensitivity", default_mouse_sensitivity)),
		mouse_sensitivity_min,
		mouse_sensitivity_max
	)
	screen_shake = bool(config.get_value("accessibility", "screen_shake", default_screen_shake))
	field_of_view = clampf(float(config.get_value("controls", "fov", default_fov)), fov_min, fov_max)
	head_bob = bool(config.get_value("accessibility", "head_bob", default_head_bob))
	controller_look_sensitivity = clampf(float(config.get_value("controls", "controller_look_sensitivity", default_controller_look_sensitivity)), controller_look_sensitivity_min, controller_look_sensitivity_max)
	difficulty = clampi(
		int(config.get_value("gameplay", "difficulty", default_difficulty)),
		Difficulty.EASY,
		Difficulty.NIGHTMARE
	)
	_load_keybindings(config, settings_version)
	if settings_version < SETTINGS_SCHEMA_VERSION:
		save_settings()


func save_settings() -> bool:
	var config := ConfigFile.new()
	config.set_value("meta", "version", SETTINGS_SCHEMA_VERSION)
	config.set_value("localization", "language", language)
	config.set_value("display", "resolution", resolution)
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("audio", "master", master_volume)
	config.set_value("audio", "music", music_volume)
	config.set_value("audio", "sfx", sfx_volume)
	config.set_value("display", "brightness", brightness)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("accessibility", "screen_shake", screen_shake)
	config.set_value("controls", "fov", field_of_view)
	config.set_value("accessibility", "head_bob", head_bob)
	config.set_value("controls", "controller_look_sensitivity", controller_look_sensitivity)
	config.set_value("gameplay", "difficulty", difficulty)
	_store_keybindings(config)
	var error := config.save(settings_path)
	if error != OK:
		push_error("VEX settings could not be saved. Error code: %s" % error)
		return false
	return true


func reset_settings() -> void:
	_reset_to_scene_defaults()
	_apply_language(false)
	apply_settings()
	save_settings()


func apply_settings() -> void:
	var mode := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)
	if not fullscreen:
		DisplayServer.window_set_size(resolution)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	_apply_volume("Master", master_volume)
	_apply_volume("Music", music_volume)
	_apply_volume("SFX", sfx_volume)
	apply_brightness()
	_apply_graphics_quality()
	SettingsManager.settings_applied.emit()


func apply_brightness() -> void:
	var scene := get_tree().current_scene
	if scene == null:
		return
	var world_environment := scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_environment == null or world_environment.environment == null:
		return
	var brightness_value := inverse_lerp(brightness_min, brightness_max, brightness)
	var brightness_multiplier := lerpf(
		brightness_multiplier_min,
		brightness_multiplier_max,
		brightness_value
	)
	world_environment.environment.adjustment_enabled = true
	world_environment.environment.adjustment_brightness = brightness_multiplier


func _apply_volume(bus_name: String, value: float) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(bus_index, value <= 0.0001)


func _apply_language(emit_signal := true) -> void:
	TranslationServer.set_locale(language)
	if emit_signal:
		language_changed.emit(language)


func set_language(value: String) -> void:
	language = _validated_locale(value)
	_apply_language()
	save_settings()


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, Difficulty.EASY, Difficulty.NIGHTMARE)
	difficulty_changed.emit(difficulty)
	save_settings()


func get_difficulty_display_name(value := -1) -> String:
	var difficulty_value := difficulty if value < 0 else clampi(value, Difficulty.EASY, Difficulty.NIGHTMARE)
	return tr(difficulty_label_keys[difficulty_value])


func get_difficulty_profile(value := -1) -> Dictionary:
	var difficulty_value := difficulty if value < 0 else clampi(value, Difficulty.EASY, Difficulty.NIGHTMARE)
	return {
		"health_multiplier": difficulty_health_multipliers[difficulty_value],
		"damage_multiplier": difficulty_damage_multipliers[difficulty_value],
		"speed_multiplier": difficulty_speed_multipliers[difficulty_value],
		"detection_multiplier": difficulty_detection_multipliers[difficulty_value],
		"cooldown_multiplier": difficulty_cooldown_multipliers[difficulty_value],
		"windup_multiplier": difficulty_windup_multipliers[difficulty_value],
		"resource_multiplier": difficulty_resource_multipliers[difficulty_value],
	}


func get_graphics_quality() -> int:
	return graphics_quality


func get_graphics_quality_display_name(value := -1) -> String:
	var quality_value := graphics_quality if value < 0 else clampi(value, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH)
	return tr(graphics_quality_label_keys[quality_value])


func set_graphics_quality(value: int) -> void:
	graphics_quality = clampi(value, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH)
	_apply_graphics_quality()
	save_settings()


func _apply_graphics_quality() -> void:
	var profile := get_graphics_profile()
	var viewport := get_tree().root
	if viewport != null:
		viewport.positional_shadow_atlas_size = int(profile.get("shadow_atlas_size", high_shadow_atlas_size))
		viewport.positional_shadow_atlas_16_bits = bool(profile.get("shadow_atlas_16_bits", high_shadow_atlas_16_bits))
		viewport.mesh_lod_threshold = float(profile.get("mesh_lod_threshold", high_mesh_lod_threshold))
	if has_node("/root/EnemyPerformance"):
		EnemyPerformance.apply_profile(graphics_quality)


func get_graphics_profile() -> Dictionary:
	match graphics_quality:
		GraphicsQuality.PERFORMANCE:
			return {
				"shadow_atlas_size": performance_shadow_atlas_size,
				"shadow_atlas_16_bits": performance_shadow_atlas_16_bits,
				"mesh_lod_threshold": performance_mesh_lod_threshold,
			}
		GraphicsQuality.BALANCED:
			return {
				"shadow_atlas_size": balanced_shadow_atlas_size,
				"shadow_atlas_16_bits": balanced_shadow_atlas_16_bits,
				"mesh_lod_threshold": balanced_mesh_lod_threshold,
			}
		_:
			return {
				"shadow_atlas_size": high_shadow_atlas_size,
				"shadow_atlas_16_bits": high_shadow_atlas_16_bits,
				"mesh_lod_threshold": high_mesh_lod_threshold,
			}


func _capture_default_keybindings() -> void:
	_default_keycodes.clear()
	for action in rebindable_actions:
		_default_keycodes[action] = _first_keycode_for_action(action)


func _ensure_default_gamepad_bindings() -> void:
	_add_default_joy_button(&"jump", JOY_BUTTON_A)
	_add_default_joy_button(&"interact", JOY_BUTTON_X)
	_add_default_joy_button(&"reload", JOY_BUTTON_B)
	_add_default_joy_button(&"pause", JOY_BUTTON_START)
	_add_default_joy_button(&"automap", JOY_BUTTON_BACK)
	_add_default_joy_button(&"night_vision", JOY_BUTTON_DPAD_UP)
	_add_default_joy_button(&"weapon_flashlight", JOY_BUTTON_DPAD_DOWN)
	_add_default_joy_button(&"weapon_next", JOY_BUTTON_RIGHT_SHOULDER)
	_add_default_joy_button(&"weapon_previous", JOY_BUTTON_LEFT_SHOULDER)
	_add_default_joy_axis(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_default_joy_axis(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_default_joy_axis(&"move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_default_joy_axis(&"move_backward", JOY_AXIS_LEFT_Y, 1.0)
	_add_default_joy_axis(&"aim", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_default_joy_axis(&"fire", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_default_joy_axis(&"controller_look_left", JOY_AXIS_RIGHT_X, -1.0)
	_add_default_joy_axis(&"controller_look_right", JOY_AXIS_RIGHT_X, 1.0)
	_add_default_joy_axis(&"controller_look_up", JOY_AXIS_RIGHT_Y, -1.0)
	_add_default_joy_axis(&"controller_look_down", JOY_AXIS_RIGHT_Y, 1.0)


func _add_default_joy_button(action: StringName, button_index: JoyButton) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if _action_has_joy_button(action, button_index):
		return
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)


func _add_default_joy_axis(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	if _action_has_joy_axis(action, axis, axis_value):
		return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)


func _action_has_joy_button(action: StringName, button_index: JoyButton) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadButton and event.button_index == button_index:
			return true
	return false


func _action_has_joy_axis(action: StringName, axis: JoyAxis, axis_value: float) -> bool:
	for event in InputMap.action_get_events(action):
		if event is InputEventJoypadMotion and event.axis == axis and is_equal_approx(event.axis_value, axis_value):
			return true
	return false


func _store_keybindings(config: ConfigFile) -> void:
	for action in rebindable_actions:
		config.set_value("keybinds", String(action), _first_keycode_for_action(action))


func _load_keybindings(config: ConfigFile, settings_version: int) -> void:
	for action in rebindable_actions:
		var default_keycode := int(_default_keycodes.get(action, 0))
		var stored_keycode := int(config.get_value("keybinds", String(action), default_keycode))
		if settings_version < SETTINGS_SCHEMA_VERSION and action == &"weapon_flashlight":
			stored_keycode = default_keycode
		_apply_keycode_to_action(action, stored_keycode)


func _apply_keycode_to_action(action: StringName, keycode: int) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	if keycode <= 0:
		return
	var event := InputEventKey.new()
	event.physical_keycode = keycode as Key
	InputMap.action_add_event(action, event)


func set_keybind(action: StringName, keycode: int) -> void:
	if not rebindable_actions.has(action):
		return
	_apply_keycode_to_action(action, keycode)
	save_settings()


func reset_keybinds() -> void:
	for action in rebindable_actions:
		_apply_keycode_to_action(action, int(_default_keycodes.get(action, 0)))
	save_settings()


func get_keybind_keycode(action: StringName) -> int:
	return _first_keycode_for_action(action)


func get_keybind_display_name(action: StringName) -> String:
	var keycode := _first_keycode_for_action(action)
	if keycode <= 0:
		return "—"
	return OS.get_keycode_string(keycode)


func get_keybind_action_label(action: StringName) -> String:
	return tr("KEYBIND_%s" % String(action).to_upper())


func _first_keycode_for_action(action: StringName) -> int:
	if not InputMap.has_action(action):
		return 0
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			return int(event.physical_keycode if event.physical_keycode != 0 else event.keycode)
	return 0


func _validated_locale(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	return normalized if supported_locales.has(normalized) else default_language


func _validated_resolution(value: Variant) -> Vector2i:
	if value is Vector2i and supported_resolutions.has(value):
		return value
	return default_resolution
