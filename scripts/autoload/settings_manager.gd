extends Node

const SETTINGS_SCHEMA_VERSION := 2

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
@export_range(0.5, 1.0, 0.01) var performance_render_scale := 0.75
@export_range(0.5, 1.0, 0.01) var balanced_render_scale := 0.85
@export_range(0.5, 1.0, 0.01) var high_render_scale := 1.0

@export_category("03 - Brightness Mapping")
@export_range(0.1, 1.0, 0.01) var brightness_min := 0.35
@export_range(1.0, 3.0, 0.01) var brightness_max := 2.0
@export_range(0.1, 3.0, 0.01) var default_brightness := 1.15
@export_range(0.1, 1.0, 0.01) var brightness_multiplier_min := 0.42
@export_range(1.0, 3.0, 0.01) var brightness_multiplier_max := 2.15

@export_category("04 - Audio Defaults")
@export_range(0.0, 1.0, 0.01) var default_master_volume := 0.85
@export_range(0.0, 1.0, 0.01) var default_music_volume := 0.65
@export_range(0.0, 1.0, 0.01) var default_sfx_volume := 0.85

@export_category("05 - Controls and Gameplay")
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
	&"automap", &"night_vision", &"weapon_1", &"weapon_2", &"weapon_3", &"weapon_4", &"weapon_5",
]

@export_category("06 - Difficulty Profiles")
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


func _ready() -> void:
	_capture_default_keybindings()
	_ensure_default_gamepad_bindings()
	_reset_to_scene_defaults()
	load_settings()
	_apply_language(false)
	call_deferred("apply_settings")


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
	resolution = config.get_value("display", "resolution", default_resolution) as Vector2i
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
	config.set_value("display", "vsync", vsync)
	config.set_value("display", "graphics_quality", graphics_quality)
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


func apply_settings() -> void:
	_apply_language(false)
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


func set_language(value: String) -> void:
	var validated := _validated_locale(value)
	if language == validated and TranslationServer.get_locale() == validated:
		return
	language = validated
	_apply_language(true)
	save_settings()


func _apply_language(notify_listeners: bool) -> void:
	TranslationServer.set_locale(language)
	if notify_listeners:
		language_changed.emit(language)
		settings_applied.emit()


func get_language_display_name(locale: String = "") -> String:
	var resolved := language if locale.is_empty() else _validated_locale(locale)
	var index := supported_locales.find(resolved)
	if index >= 0 and index < language_label_keys.size():
		return tr(str(language_label_keys[index]))
	return resolved


func _validated_locale(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	if supported_locales.has(normalized):
		return normalized
	if supported_locales.has(default_language):
		return default_language
	return supported_locales[0] if not supported_locales.is_empty() else "tr"


func set_resolution(value: Vector2i) -> void:
	resolution = value if supported_resolutions.has(value) else default_resolution
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
	graphics_quality = clampi(value, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH)
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
			return performance_render_scale
		GraphicsQuality.BALANCED:
			return balanced_render_scale
		_:
			return high_render_scale


func get_graphics_quality_display_name(value: int = -1) -> String:
	var resolved := graphics_quality if value < 0 else value
	resolved = clampi(resolved, GraphicsQuality.PERFORMANCE, GraphicsQuality.HIGH)
	if resolved < graphics_quality_label_keys.size():
		return tr(str(graphics_quality_label_keys[resolved]))
	return str(resolved)


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
	brightness = clampf(value, brightness_min, brightness_max)
	apply_brightness()
	save_settings()


func _get_brightness_multiplier() -> float:
	var neutral := clampf(default_brightness, brightness_min, brightness_max)
	if brightness <= neutral:
		if is_equal_approx(neutral, brightness_min):
			return 1.0
		var low_t := inverse_lerp(brightness_min, neutral, brightness)
		return lerpf(brightness_multiplier_min, 1.0, low_t)
	if is_equal_approx(brightness_max, neutral):
		return 1.0
	var high_t := inverse_lerp(neutral, brightness_max, brightness)
	return lerpf(1.0, brightness_multiplier_max, high_t)


func _capture_scene_brightness_baseline(environment: Environment) -> void:
	if environment.has_meta(&"vex_scene_brightness_baseline"):
		return
	environment.set_meta(&"vex_scene_brightness_baseline", environment.adjustment_brightness)
	environment.set_meta(&"vex_scene_adjustment_enabled", environment.adjustment_enabled)


func apply_brightness() -> void:
	if not is_inside_tree():
		return
	var multiplier := _get_brightness_multiplier()
	for node: Node in get_tree().get_nodes_in_group("brightness_environment"):
		if node is not WorldEnvironment:
			continue
		var world_environment := node as WorldEnvironment
		if world_environment.environment == null:
			continue
		var environment := world_environment.environment
		_capture_scene_brightness_baseline(environment)
		var scene_brightness := float(environment.get_meta(&"vex_scene_brightness_baseline", 1.0))
		var scene_adjustment_enabled := bool(environment.get_meta(&"vex_scene_adjustment_enabled", false))
		environment.adjustment_enabled = scene_adjustment_enabled or not is_equal_approx(multiplier, 1.0)
		environment.adjustment_brightness = scene_brightness * multiplier


func set_mouse_sensitivity(value: float) -> void:
	mouse_sensitivity = clampf(value, mouse_sensitivity_min, mouse_sensitivity_max)
	save_settings()


func set_screen_shake(value: bool) -> void:
	screen_shake = value
	save_settings()


func set_field_of_view(value: float) -> void:
	field_of_view = clampf(value, fov_min, fov_max)
	save_settings()
	settings_applied.emit()


func set_head_bob(value: bool) -> void:
	head_bob = value
	save_settings()


func set_controller_look_sensitivity(value: float) -> void:
	controller_look_sensitivity = clampf(value, controller_look_sensitivity_min, controller_look_sensitivity_max)
	save_settings()


func rebind_key(action: StringName, keycode: Key) -> bool:
	if not rebindable_actions.has(action) or not InputMap.has_action(action):
		return false
	_apply_key_binding(action, keycode)
	return save_settings()


func reset_keybindings() -> void:
	for action: StringName in rebindable_actions:
		if _default_keycodes.has(action):
			_apply_key_binding(action, int(_default_keycodes[action]) as Key)
	save_settings()


func get_keybinding_text(action: StringName) -> String:
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			var key_event := event as InputEventKey
			var code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
			return OS.get_keycode_string(code)
	return "—"


func _capture_default_keybindings() -> void:
	_default_keycodes.clear()
	for action: StringName in rebindable_actions:
		if not InputMap.has_action(action):
			continue
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var key_event := event as InputEventKey
				_default_keycodes[action] = key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
				break


func _apply_key_binding(action: StringName, keycode: Key) -> void:
	if not InputMap.has_action(action):
		return
	for event in InputMap.action_get_events(action):
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)
	var key_event := InputEventKey.new()
	key_event.physical_keycode = keycode
	InputMap.action_add_event(action, key_event)


func _load_keybindings(config: ConfigFile, settings_version: int = SETTINGS_SCHEMA_VERSION) -> void:
	for action: StringName in rebindable_actions:
		if not config.has_section_key("keybindings", str(action)):
			continue
		var code := int(config.get_value("keybindings", str(action), 0))
		# Schema v1 accidentally shipped Automap as Backspace. Preserve deliberate
		# user mappings in current files, but migrate that historical default once.
		if settings_version < 2 and action == &"automap" and code == KEY_BACKSPACE:
			code = KEY_TAB
		if code > 0:
			_apply_key_binding(action, code as Key)


func _store_keybindings(config: ConfigFile) -> void:
	for action: StringName in rebindable_actions:
		for event in InputMap.action_get_events(action):
			if event is InputEventKey:
				var key_event := event as InputEventKey
				var code := key_event.physical_keycode if key_event.physical_keycode != KEY_NONE else key_event.keycode
				config.set_value("keybindings", str(action), int(code))
				break


func _ensure_default_gamepad_bindings() -> void:
	_add_joy_motion(&"move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_motion(&"move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_motion(&"move_forward", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_motion(&"move_backward", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_motion(&"fire", JOY_AXIS_TRIGGER_RIGHT, 1.0)
	_add_joy_motion(&"aim", JOY_AXIS_TRIGGER_LEFT, 1.0)
	_add_joy_button(&"jump", JOY_BUTTON_A)
	_add_joy_button(&"crouch", JOY_BUTTON_B)
	_add_joy_button(&"interact", JOY_BUTTON_X)
	_add_joy_button(&"reload", JOY_BUTTON_Y)
	_add_joy_button(&"sprint", JOY_BUTTON_LEFT_STICK)
	_add_joy_button(&"weapon_next", JOY_BUTTON_RIGHT_SHOULDER)
	_add_joy_button(&"weapon_previous", JOY_BUTTON_LEFT_SHOULDER)
	_add_joy_button(&"automap", JOY_BUTTON_BACK)
	_add_joy_button(&"pause", JOY_BUTTON_START)
	_add_joy_button(&"night_vision", JOY_BUTTON_DPAD_UP)


func _add_joy_motion(action: StringName, axis: JoyAxis, axis_value: float) -> void:
	if not InputMap.has_action(action):
		return
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadMotion:
			var motion := existing as InputEventJoypadMotion
			if motion.axis == axis and signf(motion.axis_value) == signf(axis_value):
				return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = axis_value
	InputMap.action_add_event(action, event)


func _add_joy_button(action: StringName, button: JoyButton) -> void:
	if not InputMap.has_action(action):
		return
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and (existing as InputEventJoypadButton).button_index == button:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button
	InputMap.action_add_event(action, event)


func set_difficulty(value: int) -> void:
	difficulty = clampi(value, Difficulty.EASY, Difficulty.NIGHTMARE)
	save_settings()
	difficulty_changed.emit(difficulty)


func get_difficulty_display_name(value: int = -1) -> String:
	var resolved := difficulty if value < 0 else value
	resolved = clampi(resolved, Difficulty.EASY, Difficulty.NIGHTMARE)
	if resolved < difficulty_label_keys.size():
		return tr(str(difficulty_label_keys[resolved]))
	return str(resolved)


func get_difficulty_profile(value: int = -1) -> Dictionary:
	var resolved := difficulty if value < 0 else value
	resolved = clampi(resolved, Difficulty.EASY, Difficulty.NIGHTMARE)
	return {
		"health_multiplier": _profile_value(difficulty_health_multipliers, resolved),
		"damage_multiplier": _profile_value(difficulty_damage_multipliers, resolved),
		"speed_multiplier": _profile_value(difficulty_speed_multipliers, resolved),
		"detection_multiplier": _profile_value(difficulty_detection_multipliers, resolved),
		"cooldown_multiplier": _profile_value(difficulty_cooldown_multipliers, resolved),
		"windup_multiplier": _profile_value(difficulty_windup_multipliers, resolved),
		"resource_multiplier": _profile_value(difficulty_resource_multipliers, resolved),
	}


func _profile_value(values: PackedFloat32Array, index: int) -> float:
	if index >= 0 and index < values.size():
		return maxf(0.0, values[index])
	return 1.0


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
	var new_position := (screen_size - resolution) / 2.0
	DisplayServer.window_set_position(new_position)
