class_name VexSettingsPanel
extends PanelContainer

signal close_requested

const RESOLUTIONS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
]

@onready var resolution_option: OptionButton = %ResolutionOption
@onready var difficulty_option: OptionButton = %DifficultyOption
@onready var graphics_quality_option: OptionButton = %GraphicsQualityOption
@onready var fullscreen_check: CheckButton = %FullscreenCheck
@onready var vsync_check: CheckButton = %VsyncCheck
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
@onready var shake_check: CheckButton = %ShakeCheck
@onready var close_button: Button = %CloseButton

var _syncing := false


func _ready() -> void:
	for resolution: Vector2i in RESOLUTIONS:
		resolution_option.add_item("%d × %d" % [resolution.x, resolution.y])
	for difficulty_label: String in SettingsManager.DIFFICULTY_LABELS:
		difficulty_option.add_item(difficulty_label)
	for quality_label: String in SettingsManager.GRAPHICS_QUALITY_LABELS:
		graphics_quality_option.add_item(quality_label)
	resolution_option.item_selected.connect(_on_resolution_selected)
	difficulty_option.item_selected.connect(_on_difficulty_selected)
	graphics_quality_option.item_selected.connect(_on_graphics_quality_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vsync_check.toggled.connect(_on_vsync_toggled)
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	brightness_slider.value_changed.connect(_on_brightness_changed)
	sensitivity_slider.value_changed.connect(_on_sensitivity_changed)
	shake_check.toggled.connect(_on_shake_toggled)
	close_button.pressed.connect(_on_close_pressed)
	_sync_from_settings()


func show_panel() -> void:
	_sync_from_settings()
	visible = true
	close_button.grab_focus()


func hide_panel() -> void:
	visible = false
	close_requested.emit()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()


func _sync_from_settings() -> void:
	if not is_node_ready():
		return
	_syncing = true
	var resolution_index := RESOLUTIONS.find(SettingsManager.resolution)
	resolution_option.select(maxi(0, resolution_index))
	difficulty_option.select(SettingsManager.difficulty)
	graphics_quality_option.select(SettingsManager.graphics_quality)
	fullscreen_check.button_pressed = SettingsManager.fullscreen
	vsync_check.button_pressed = SettingsManager.vsync
	master_slider.value = SettingsManager.master_volume * 100.0
	music_slider.value = SettingsManager.music_volume * 100.0
	sfx_slider.value = SettingsManager.sfx_volume * 100.0
	brightness_slider.value = SettingsManager.brightness * 100.0
	sensitivity_slider.value = SettingsManager.mouse_sensitivity * 1000.0
	shake_check.button_pressed = SettingsManager.screen_shake
	_update_value_labels()
	_syncing = false


func _update_value_labels() -> void:
	master_value.text = "%d%%" % int(round(master_slider.value))
	music_value.text = "%d%%" % int(round(music_slider.value))
	sfx_value.text = "%d%%" % int(round(sfx_slider.value))
	brightness_value.text = "%d%%" % int(round(brightness_slider.value))
	sensitivity_value.text = "%.2f" % (sensitivity_slider.value / 1000.0)


func _on_resolution_selected(index: int) -> void:
	if _syncing or index < 0 or index >= RESOLUTIONS.size():
		return
	SettingsManager.set_resolution(RESOLUTIONS[index])


func _on_difficulty_selected(index: int) -> void:
	if not _syncing:
		SettingsManager.set_difficulty(index)


func _on_graphics_quality_selected(index: int) -> void:
	if not _syncing:
		SettingsManager.set_graphics_quality(index)


func _on_fullscreen_toggled(value: bool) -> void:
	if not _syncing:
		SettingsManager.set_fullscreen(value)


func _on_vsync_toggled(value: bool) -> void:
	if not _syncing:
		SettingsManager.set_vsync(value)


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


func _on_shake_toggled(value: bool) -> void:
	if not _syncing:
		SettingsManager.set_screen_shake(value)


func _on_close_pressed() -> void:
	hide_panel()
