class_name VexSettingsPanel
extends PanelContainer

signal close_requested

@onready var language_option: OptionButton = %LanguageOption
@onready var resolution_option: OptionButton = %ResolutionOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var graphics_quality_option: OptionButton = %GraphicsQualityOption
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VsyncCheck
@onready var fps_check: CheckButton = %FpsCheck
@onready var master_slider: HSlider = %MasterSlider
@onready var master_value: Label = %MasterValue
@onready var music_slider: HSlider = %MusicSlider
@onready var music_value: Label = %MusicValue
@onready var sfx_slider: HSlider = %SfxSlider
@onready var sfx_value: Label = %SfxValue
@onready var brightness_slider: HSlider = %BrightnessSlider
@onready var brightness_value: Label = %BrightnessValue
@onready var sensitivity_slider: HSlider = %SensitivitySlider
@onready var sensitivity_value: Label = %SensitivityValue
@onready var controller_sensitivity_slider: HSlider = %ControllerSensitivitySlider
@onready var controller_sensitivity_value: Label = %ControllerSensitivityValue
@onready var shake_check: CheckButton = %ShakeCheck
@onready var fov_slider: HSlider = %FovSlider
@onready var fov_value: Label = %FovValue
@onready var head_bob_check: CheckButton = %HeadBobCheck
@onready var close_button: Button = %CloseButton
@onready var keybind_button: Button = %KeyBindingsButton
@onready var keybind_panel: VexKeybindPanel = %KeybindPanel

var _syncing := false


func _ready() -> void:
	_populate_options()
	language_option.item_selected.connect(_on_language_selected)
	resolution_option.item_selected.connect(_on_resolution_selected)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	graphics_quality_option.item_selected.connect(_on_graphics_quality_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	fps_check.toggled.connect(_on_fps_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	controller_sensitivity_slider.value_changed.connect(_on_controller_sensitivity_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	fov_slider.value_changed.connect(_on_fov_changed)
	head_bob_check.toggled.connect(_on_head_bob_toggled)
	close_button.pressed.connect(_on_close_pressed)
	keybind_button.pressed.connect(keybind_panel.show_panel)
	SettingsManager.language_changed.connect(_on_language_changed)
	brightness_slider.min_value = SettingsManager.brightness_min * 100.0
	brightness_slider.max_value = SettingsManager.brightness_max * 100.0
	sensitivity_slider.min_value = SettingsManager.mouse_sensitivity_min * 1000.0
	sensitivity_slider.max_value = SettingsManager.mouse_sensitivity_max * 1000.0
	controller_sensitivity_slider.min_value = SettingsManager.controller_look_sensitivity_min * 100.0
	controller_sensitivity_slider.max_value = SettingsManager.controller_look_sensitivity_max * 100.0
	fov_slider.min_value = SettingsManager.fov_min
	fov_slider.max_value = SettingsManager.fov_max
	_sync_from_settings()


func _populate_options() -> void:
	resolution_option.clear()
	for resolution: Vector2i in SettingsManager.supported_resolutions:
		resolution_option.add_item("%d × %d" % [resolution.x, resolution.y])
	difficulty_option.clear()
	for label_key: StringName in SettingsManager.difficulty_label_keys:
		difficulty_option.add_item(tr(str(label_key)))
	graphics_quality_option.clear()
	for label_key: StringName in SettingsManager.graphics_quality_label_keys:
		graphics_quality_option.add_item(tr(str(label_key)))
	language_option.clear()
	for locale: String in SettingsManager.supported_locales:
		language_option.add_item(SettingsManager.get_language_display_name(locale))


func show_panel() -> void:
	_sync_from_settings()
	visible = true
	close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	close_requested.emit()


func is_capturing_key_input() -> bool:
	return keybind_panel.visible and keybind_panel.is_waiting_for_key()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or keybind_panel.visible:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()


func _sync_from_settings() -> void:
	if not is_node_ready():
		return
	_syncing = true
	var language_index := SettingsManager.supported_locales.find(SettingsManager.language)
	language_option.select(maxi(0, language_index))
	var resolution_index := SettingsManager.supported_resolutions.find(SettingsManager.resolution)
	resolution_option.select(maxi(0, resolution_index))
	difficulty_option.select(SettingsManager.difficulty)
	difficulty_option.disabled = _is_difficulty_locked()
	graphics_quality_option.select(SettingsManager.graphics_quality)
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	vsync_check.button_pressed = SettingsManager.vsync
	fps_check.button_pressed = FpsDisplay.enabled
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	brightness_slider.value = SettingsManager.brightness * 100.0
	sensitivity_slider.value = SettingsManager.mouse_sensitivity * 1000.0
	controller_sensitivity_slider.value = SettingsManager.controller_look_sensitivity * 100.0
	shake_check.button_pressed = SettingsManager.screen_shake
	fov_slider.value = SettingsManager.field_of_view
	head_bob_check.button_pressed = SettingsManager.head_bob
	_update_value_labels()
	_update_toggle_labels()
	_syncing = false


func _is_difficulty_locked() -> bool:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return false
	return current_scene.scene_file_path != GameState.MAIN_MENU_PATH


func _update_value_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	brightness_value.text = "%d%%" % int(round(brightness_slider.value))
	sensitivity_value.text = "%.2f" % (sensitivity_slider.value / 1000.0)
	controller_sensitivity_value.text = "%.1f" % (controller_sensitivity_slider.value / 100.0)
	fov_value.text = "%d°" % int(round(fov_slider.value))


func _update_toggle_labels() -> void:
	fullscreen_check.text = _toggle_text(fullscreen_check.button_pressed)
	vsync_check.text = _toggle_text(vsync_check.button_pressed)
	fps_check.text = _toggle_text(fps_check.button_pressed)
	shake_check.text = _toggle_text(shake_check.button_pressed)
	head_bob_check.text = _toggle_text(head_bob_check.button_pressed)


func _toggle_text(value: bool) -> String:
	if value:
		return tr("UI_ENABLED")
	return "KAPALI" if TranslationServer.get_locale().begins_with("tr") else "OFF"


func _on_resolution_selected(index: int) -> void:
	if _syncing or index < 0 or index >= SettingsManager.supported_resolutions.size():
		return
	SettingsManager.set_resolution(SettingsManager.supported_resolutions[index])


func _on_language_selected(index: int) -> void:
	if _syncing or index < 0 or index >= SettingsManager.supported_locales.size():
		return
	SettingsManager.set_language(SettingsManager.supported_locales[index])


func _on_language_changed(_locale: String) -> void:
	_populate_options()
	_sync_from_settings()


func _on_difficulty_selected(index: int) -> void:
	if not _syncing and not _is_difficulty_locked():
		SettingsManager.set_difficulty(index)


func _on_graphics_quality_selected(index: int) -> void:
	if not _syncing:
		SettingsManager.set_graphics_quality(index)


func _on_fullscreen_toggled(value: bool) -> void:
	if _syncing:
		return
	_update_toggle_labels()
	SettingsManager.set_fullscreen(value)


func _on_vsync_toggled(value: bool) -> void:
	if _syncing:
		return
	_update_toggle_labels()
	SettingsManager.set_vsync(value)


func _on_fps_toggled(value: bool) -> void:
	if _syncing:
		return
	_update_toggle_labels()
	FpsDisplay.set_enabled(value)


func _on_master_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_master_volume(value / 100.0)


func _on_music_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_music_volume(value / 100.0)


func _on_sfx_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_sfx_volume(value / 100.0)


func _on_brightness_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_brightness(value / 100.0)


func _on_sensitivity_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_mouse_sensitivity(value / 1000.0)


func _on_controller_sensitivity_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_controller_look_sensitivity(value / 100.0)


func _on_shake_toggled(value: bool) -> void:
	if _syncing:
		return
	_update_toggle_labels()
	SettingsManager.set_screen_shake(value)


func _on_fov_changed(value: float) -> void:
	_update_value_labels()
	if not _syncing:
		SettingsManager.set_field_of_view(value)


func _on_head_bob_toggled(value: bool) -> void:
	if _syncing:
		return
	_update_toggle_labels()
	SettingsManager.set_head_bob(value)


func _on_close_pressed() -> void:
	hide_panel()