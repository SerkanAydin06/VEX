class_name VexHubTerminal
extends Node3D

enum TerminalMode {
	MISSION_CONTROL,
	DEPLOYMENT,
	INFORMATION,
	WEAPON_ARCHIVE,
}

const SCREEN_FONT = preload("res://assets/fonts/vex_mono_bold.ttf")
const WORLD_SCREEN_SIZE := Vector2i(640, 360)

@export_category("Terminal")
@export_enum("Mission Control", "Deployment", "Information", "Weapon Archive") var terminal_mode: int = TerminalMode.INFORMATION
@export var display_name := "BASTION TERMİNALİ"
@export var offline := false
@export var offline_message := "POWER OFFLINE"

@export_category("Screen Signal")
@export var screen_motion_enabled := true
@export_range(0.0, 0.08, 0.001) var screen_signal_strength := 0.018
@export_range(0.2, 6.0, 0.1) var screen_signal_speed := 2.2

@onready var offline_overlay: Label3D = $Visuals/ScreenAssembly/OfflineOverlay
@onready var screen_surface: Sprite3D = $Visuals/ScreenAssembly/ScreenSurface
@onready var terminal_menu: VexTerminalMenu = $TerminalMenu
@onready var archive_terminal: VexArchiveTerminal = $ArchiveTerminal
@onready var weapon_archive_terminal: VexWeaponArchiveTerminal = $WeaponArchiveTerminal

var _screen_base_position := Vector3.ZERO
var _screen_base_pixel_size := 0.0008
var _screen_signal_time := 0.0
var _world_scan_time := 0.0
var _world_display_signature := ""
var _world_screen_viewport: SubViewport
var _world_title_label: Label
var _world_subtitle_label: Label
var _world_line_1_label: Label
var _world_line_2_label: Label
var _world_status_label: Label
var _world_footer_label: Label
var _world_scan_line: ColorRect


func _ready() -> void:
	if screen_surface != null:
		_screen_base_position = screen_surface.position
		_screen_base_pixel_size = screen_surface.pixel_size
	_ensure_world_screen()
	_refresh_world_screen(true)
	_refresh_offline_overlay()
	if Engine.is_editor_hint():
		return
	add_to_group("interactable")
	if not SettingsManager.language_changed.is_connected(_on_language_changed):
		SettingsManager.language_changed.connect(_on_language_changed)


func _process(delta: float) -> void:
	_refresh_world_screen()
	_update_world_scan(delta)
	if screen_surface == null:
		return
	if offline:
		screen_surface.position = _screen_base_position
		screen_surface.pixel_size = _screen_base_pixel_size
		screen_surface.modulate = Color(0.22, 0.28, 0.30, 1.0)
		return
	if not screen_motion_enabled:
		screen_surface.position = _screen_base_position
		screen_surface.pixel_size = _screen_base_pixel_size
		screen_surface.modulate = Color.WHITE
		return

	_screen_signal_time = fmod(
		_screen_signal_time + delta * screen_signal_speed,
		TAU * 64.0
	)
	var slow_wave := sin(_screen_signal_time)
	var scan_wave := sin(_screen_signal_time * 3.7 + 0.9)
	var signal_amount := clampf(screen_signal_strength, 0.0, 0.08)
	var vertical_drift := slow_wave * signal_amount * 0.06
	var scale_pulse := 1.0 + scan_wave * signal_amount * 0.15
	var brightness := 0.96 + (slow_wave * 0.5 + 0.5) * signal_amount * 1.7
	var cyan_bias := 0.985 + (scan_wave * 0.5 + 0.5) * signal_amount * 0.65

	screen_surface.position = _screen_base_position + Vector3(0.0, vertical_drift, 0.0)
	screen_surface.pixel_size = _screen_base_pixel_size * scale_pulse
	screen_surface.modulate = Color(brightness, cyan_bias, 1.0, 1.0)


func get_interaction_text(_player: Node) -> String:
	var resolved_name := _get_display_name()
	if offline:
		return tr("INTERACT_LOCKED") % [resolved_name, tr(offline_message)]
	return tr("TERMINAL_INTERACT_OPEN") % resolved_name


func interact(_player: Node) -> void:
	if offline:
		GameState.notify(tr("DOOR_LOCKED_MESSAGE") % [_get_display_name(), tr(offline_message)])
		return
	if terminal_mode == TerminalMode.INFORMATION:
		archive_terminal.open_terminal()
		return
	if terminal_mode == TerminalMode.WEAPON_ARCHIVE:
		weapon_archive_terminal.open_terminal()
		return
	terminal_menu.open_terminal(
		_get_mission_definitions(),
		true,
		terminal_mode == TerminalMode.DEPLOYMENT
	)


func _get_display_name() -> String:
	if terminal_mode == TerminalMode.INFORMATION:
		return "VEX ANA TERMİNALİ" if TranslationServer.get_locale().begins_with("tr") else "VEX MAIN TERMINAL"
	if terminal_mode == TerminalMode.WEAPON_ARCHIVE:
		return "SİLAH ARŞİV TERMİNALİ" if TranslationServer.get_locale().begins_with("tr") else "WEAPON ARCHIVE TERMINAL"
	return tr(display_name)


func _on_language_changed(_locale: String) -> void:
	_world_display_signature = ""
	_refresh_world_screen(true)
	_refresh_offline_overlay()


func _get_hub_scene() -> Node:
	if not is_inside_tree():
		return null
	var current: Node = self
	while current != null:
		if current.has_method("get_mission_definitions"):
			return current
		current = current.get_parent()
	return null


func _get_mission_definitions() -> Array:
	var hub := _get_hub_scene()
	if hub != null:
		return hub.call("get_mission_definitions") as Array
	return []


func _refresh_offline_overlay() -> void:
	if offline_overlay == null:
		return
	offline_overlay.visible = offline
	offline_overlay.text = tr(offline_message)


func _ensure_world_screen() -> void:
	if screen_surface == null:
		return
	_world_screen_viewport = get_node_or_null("WorldScreenViewport") as SubViewport
	if _world_screen_viewport != null:
		_cache_world_screen_nodes()
		screen_surface.texture = _world_screen_viewport.get_texture()
		return

	_world_screen_viewport = SubViewport.new()
	_world_screen_viewport.name = "WorldScreenViewport"
	_world_screen_viewport.size = WORLD_SCREEN_SIZE
	_world_screen_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_world_screen_viewport.gui_disable_input = true
	_world_screen_viewport.transparent_bg = false
	add_child(_world_screen_viewport)

	var root := Control.new()
	root.name = "DisplayRoot"
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_world_screen_viewport.add_child(root)

	var background := ColorRect.new()
	background.name = "Background"
	background.color = Color(0.004, 0.012, 0.017, 1.0)
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(background)

	var header_bar := ColorRect.new()
	header_bar.name = "HeaderBar"
	header_bar.position = Vector2(0.0, 0.0)
	header_bar.size = Vector2(640.0, 58.0)
	header_bar.color = Color(0.015, 0.12, 0.15, 1.0)
	root.add_child(header_bar)

	var left_accent := ColorRect.new()
	left_accent.name = "LeftAccent"
	left_accent.position = Vector2(18.0, 82.0)
	left_accent.size = Vector2(5.0, 218.0)
	left_accent.color = Color(0.22, 0.90, 1.0, 0.85)
	root.add_child(left_accent)

	var separator := ColorRect.new()
	separator.name = "Separator"
	separator.position = Vector2(32.0, 250.0)
	separator.size = Vector2(576.0, 2.0)
	separator.color = Color(0.12, 0.38, 0.42, 0.8)
	root.add_child(separator)

	var facility_label := _make_world_label("FacilityLabel", 17, Color(0.35, 0.88, 1.0, 1.0))
	facility_label.position = Vector2(28.0, 17.0)
	facility_label.size = Vector2(360.0, 28.0)
	facility_label.text = "VEX // BASTION-7"
	root.add_child(facility_label)

	_world_status_label = _make_world_label("StatusLabel", 16, Color(0.30, 1.0, 0.62, 1.0))
	_world_status_label.position = Vector2(390.0, 17.0)
	_world_status_label.size = Vector2(220.0, 28.0)
	_world_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	root.add_child(_world_status_label)

	_world_title_label = _make_world_label("TitleLabel", 38, Color(0.34, 0.91, 1.0, 1.0))
	_world_title_label.position = Vector2(42.0, 88.0)
	_world_title_label.size = Vector2(566.0, 56.0)
	_world_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_world_title_label)

	_world_subtitle_label = _make_world_label("SubtitleLabel", 18, Color(1.0, 0.31, 0.18, 1.0))
	_world_subtitle_label.position = Vector2(42.0, 151.0)
	_world_subtitle_label.size = Vector2(566.0, 34.0)
	_world_subtitle_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_world_subtitle_label)

	_world_line_1_label = _make_world_label("Line1Label", 16, Color(0.65, 0.83, 0.87, 1.0))
	_world_line_1_label.position = Vector2(42.0, 202.0)
	_world_line_1_label.size = Vector2(566.0, 30.0)
	_world_line_1_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_world_line_1_label)

	_world_line_2_label = _make_world_label("Line2Label", 16, Color(0.48, 0.69, 0.73, 1.0))
	_world_line_2_label.position = Vector2(42.0, 266.0)
	_world_line_2_label.size = Vector2(566.0, 30.0)
	_world_line_2_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_world_line_2_label)

	_world_footer_label = _make_world_label("FooterLabel", 13, Color(0.31, 0.55, 0.60, 1.0))
	_world_footer_label.position = Vector2(28.0, 321.0)
	_world_footer_label.size = Vector2(582.0, 24.0)
	root.add_child(_world_footer_label)

	_world_scan_line = ColorRect.new()
	_world_scan_line.name = "ScanLine"
	_world_scan_line.position = Vector2(0.0, 68.0)
	_world_scan_line.size = Vector2(640.0, 2.0)
	_world_scan_line.color = Color(0.2, 0.92, 1.0, 0.24)
	root.add_child(_world_scan_line)

	screen_surface.texture = _world_screen_viewport.get_texture()


func _cache_world_screen_nodes() -> void:
	if _world_screen_viewport == null:
		return
	var root := _world_screen_viewport.get_node_or_null("DisplayRoot") as Control
	if root == null:
		return
	_world_title_label = root.get_node_or_null("TitleLabel") as Label
	_world_subtitle_label = root.get_node_or_null("SubtitleLabel") as Label
	_world_line_1_label = root.get_node_or_null("Line1Label") as Label
	_world_line_2_label = root.get_node_or_null("Line2Label") as Label
	_world_status_label = root.get_node_or_null("StatusLabel") as Label
	_world_footer_label = root.get_node_or_null("FooterLabel") as Label
	_world_scan_line = root.get_node_or_null("ScanLine") as ColorRect


func _make_world_label(node_name: String, font_size: int, font_color: Color) -> Label:
	var label := Label.new()
	label.name = node_name
	label.add_theme_font_override("font", SCREEN_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", font_color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = false
	return label


func _refresh_world_screen(force := false) -> void:
	if _world_title_label == null:
		return
	var locale := TranslationServer.get_locale()
	var signature := "%d|%s|%s" % [terminal_mode, str(offline), locale]
	if not force and signature == _world_display_signature:
		return
	_world_display_signature = signature
	var turkish := locale.begins_with("tr")
	var title := ""
	var subtitle := ""
	var line_1 := ""
	var line_2 := ""
	match terminal_mode:
		TerminalMode.MISSION_CONTROL:
			title = "GÖREV KONTROLÜ" if turkish else "MISSION CONTROL"
			subtitle = "OPERASYON AĞI // BRİFİNG VERİSİ" if turkish else "OPERATION NETWORK // BRIEFING DATA"
			line_1 = "VEX-01 // VEX-02 // VEX-03"
			line_2 = "GÖREV DURUMU // YETKİ // SAHA VERİSİ" if turkish else "MISSION STATUS // CLEARANCE // FIELD DATA"
		TerminalMode.DEPLOYMENT:
			title = "OPERASYON TERMİNALİ" if turkish else "DEPLOYMENT TERMINAL"
			subtitle = "AKTİF GÖREV // GÖREVE ÇIKIŞ" if turkish else "ACTIVE OPERATION // DEPLOYMENT"
			line_1 = "OPERASYON HAZIR" if turkish else "OPERATION READY"
			line_2 = "ONAY SONRASI SAHA TRANSFERİ" if turkish else "FIELD TRANSFER AFTER CONFIRMATION"
		TerminalMode.INFORMATION:
			title = "VEX ANA TERMİNALİ" if turkish else "VEX MAIN TERMINAL"
			subtitle = "XENO ARŞİVİ // GERÇEKLİK VERİSİ" if turkish else "XENO ARCHIVE // REALITY DATA"
			line_1 = "YARATIKLAR // EVRENLER // KAYITLAR" if turkish else "CREATURES // REALITIES // RECORDS"
			line_2 = "TEHDİT ANALİZİ // YARIK AĞI // PROTOKOLLER" if turkish else "THREAT ANALYSIS // RIFT NETWORK // PROTOCOLS"
		TerminalMode.WEAPON_ARCHIVE:
			title = "SİLAH ARŞİVİ" if turkish else "WEAPON ARCHIVE"
			subtitle = "CANLI BALİSTİK // WEAPON DEFINITION"
			line_1 = "HASAR // RPM // MENZİL // SEKME" if turkish else "DAMAGE // RPM // RANGE // RECOIL"
			line_2 = "MÜHİMMAT // ÖZEL SİSTEM // UPGRADE HATTI" if turkish else "AMMUNITION // SPECIAL SYSTEM // UPGRADE TRACK"
		_:
			title = "VEX TERMİNALİ" if turkish else "VEX TERMINAL"
			subtitle = "BASTION-7 // SECURE NODE"
			line_1 = "SYSTEM LINK"
			line_2 = "DATA READY"
	_world_title_label.text = title
	_world_subtitle_label.text = subtitle
	_world_line_1_label.text = line_1
	_world_line_2_label.text = line_2
	_world_status_label.text = ("GÜÇ KAPALI" if turkish else "POWER OFFLINE") if offline else ("SİSTEM AKTİF" if turkish else "SYSTEM ONLINE")
	_world_status_label.add_theme_color_override(
		"font_color",
		Color(1.0, 0.22, 0.12, 1.0) if offline else Color(0.30, 1.0, 0.62, 1.0)
	)
	_world_footer_label.text = "[E] ERİŞİM // BASTION-7 GÜVENLİ DÜĞÜM" if turkish else "[E] ACCESS // BASTION-7 SECURE NODE"


func _update_world_scan(delta: float) -> void:
	if _world_scan_line == null:
		return
	_world_scan_time = fmod(_world_scan_time + delta * 74.0, 244.0)
	_world_scan_line.position.y = 68.0 + _world_scan_time
