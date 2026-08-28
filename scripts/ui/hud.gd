class_name VexHUD
extends CanvasLayer

const DOOM3_CROSSHAIR: Texture2D = preload("res://assets/ui/crosshair_doom3_circle.png")

@export_category("Nişangah")
@export var crosshair_default_color := Color(0.93, 0.96, 1.0, 0.78)
@export var crosshair_hit_color := Color(1.0, 0.0, 0.0, 1.0)
@export var crosshair_headshot_color := Color(1.0, 0.72, 0.10, 1.0)
@export_range(0.05, 1.0, 0.01) var crosshair_hit_duration := 0.24

@export_category("Performans")
@export_range(0.02, 0.25, 0.01) var world_ui_sample_interval := 0.05

@export_category("HUD Eşikleri ve Zamanlama")
@export_range(1, 99, 1) var critical_health_threshold := 25
@export_range(1, 99, 1) var warning_health_threshold := 50
@export_range(0.1, 0.9, 0.05) var low_health_overlay_ratio := 0.50
@export_range(0.05, 0.8, 0.05) var critical_overlay_ratio := 0.30
@export_range(0.1, 10.0, 0.1) var notification_hold_time := 2.5
@export_range(0.05, 2.0, 0.05) var notification_fade_time := 0.35
@export_range(0.05, 1.0, 0.01) var pickup_slide_time := 0.18
@export_range(0.1, 10.0, 0.05) var pickup_hold_time := 1.85
@export_range(0.05, 2.0, 0.05) var pickup_fade_time := 0.30
@export_range(0.05, 2.0, 0.05) var damage_feedback_time := 0.60

@onready var health_value: Label = %HealthValue
@onready var armor_value: Label = %ArmorValue
@onready var health_meter: ProgressBar = %HealthMeter
@onready var armor_meter: ProgressBar = %ArmorMeter
@onready var health_status: Label = %HealthStatus
@onready var armor_status: Label = %ArmorStatus
@onready var stamina_value: Label = %StaminaValue
@onready var stamina_meter: ProgressBar = %StaminaMeter
@onready var stamina_status: Label = %StaminaStatus
@onready var ammo_value: Label = %AmmoValue
@onready var reserve_value: Label = %ReserveValue
@onready var weapon_name: Label = %WeaponName
@onready var weapon_slot: Label = %WeaponSlot
@onready var ammo_type: Label = %AmmoType
@onready var kills_value: Label = %KillsValue
@onready var key_icon: TextureRect = %KeyIcon
@onready var red_key_icon: TextureRect = %RedKeyIcon
@onready var yellow_key_icon: TextureRect = %YellowKeyIcon
@onready var objective_label: Label = %ObjectiveLabel
@onready var interaction_label: Label = %InteractionLabel
@onready var notification_panel: PanelContainer = %NotificationPanel
@onready var notification_label: Label = %NotificationLabel
@onready var pickup_feed_left: Control = %PickupFeedLeft
@onready var pickup_left_accent: ColorRect = %PickupLeftAccent
@onready var pickup_left_category: Label = %PickupLeftCategory
@onready var pickup_left_value: Label = %PickupLeftValue
@onready var pickup_feed_right: Control = %PickupFeedRight
@onready var pickup_right_accent: ColorRect = %PickupRightAccent
@onready var pickup_right_category: Label = %PickupRightCategory
@onready var pickup_right_value: Label = %PickupRightValue
@onready var crosshair: TextureRect = %Crosshair
@onready var low_health_overlay: TextureRect = %LowHealthOverlay
@onready var critical_health_overlay: TextureRect = %CriticalHealthOverlay
@onready var damage_flash: ColorRect = %DamageFlash
@onready var damage_amount: Label = %DamageAmount
@onready var weapon_layer: Control = %WeaponLayer
@onready var p01_audio: AudioStreamPlayer = %P01Audio
@onready var p07_audio: AudioStreamPlayer = %P07Audio
@onready var p14_audio: AudioStreamPlayer = %P14Audio
@onready var p20_audio: AudioStreamPlayer = %P20Audio
@onready var sg04_audio: AudioStreamPlayer = %Sg04Audio
@onready var sg09_audio: AudioStreamPlayer = %Sg09Audio
@onready var vx47_audio: AudioStreamPlayer = %Vx47Audio
@onready var mp90_audio: AudioStreamPlayer = %Mp90Audio
@onready var pistol_reload_audio: AudioStreamPlayer = %PistolReloadAudio
@onready var shotgun_reload_audio: AudioStreamPlayer = %ShotgunReloadAudio
@onready var empty_gun_audio: AudioStreamPlayer = %EmptyGunAudio
@onready var player_death_audio: AudioStreamPlayer = %PlayerDeathAudio
@onready var game_over_music: AudioStreamPlayer = %GameOverMusic
@onready var map_overlay: Control = %MapOverlay
@onready var automap_view: VexAutomapView = %AutomapView
@onready var map_title: Label = %MapTitle
@onready var map_status: Label = %MapStatus
@onready var pause_menu: VexPauseMenu = %PauseMenu
@onready var death_panel: PanelContainer = %DeathPanel
@onready var restart_button: Button = %RestartButton
@onready var death_main_menu_button: Button = %DeathMainMenuButton

var _current_weapon_id: StringName = &"p01"
var _notification_tween: Tween = null
var _pickup_left_tween: Tween = null
var _pickup_right_tween: Tween = null
var _damage_tween: Tween = null
var _weapon_tween: Tween = null
var _is_dead := false
var _weapon_layer_rest_position := Vector2.ZERO
var _damage_amount_rest_position := Vector2.ZERO
var _pickup_left_rest_position := Vector2.ZERO
var _pickup_right_rest_position := Vector2.ZERO
var _health_ratio := 1.0
var _danger_pulse_time := 0.0
var _crosshair_hit_timer := 0.0
var _crosshair_rest_position := Vector2.ZERO
var _crosshair_base_scale := Vector2.ONE
var _world_ui_sample_remaining := 0.0
var _weapon_presenter: VexHudWeaponPresenter = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_weapon_layer_rest_position = weapon_layer.position
	_crosshair_rest_position = crosshair.position
	_crosshair_base_scale = crosshair.scale
	crosshair.pivot_offset = crosshair.size * 0.5
	crosshair.texture = DOOM3_CROSSHAIR
	crosshair.modulate = crosshair_default_color
	_damage_amount_rest_position = damage_amount.position
	_pickup_left_rest_position = pickup_feed_left.position
	_pickup_right_rest_position = pickup_feed_right.position
	GameState.player_stats_changed.connect(_on_player_stats_changed)
	GameState.player_stamina_changed.connect(_on_player_stamina_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	GameState.ammo_changed.connect(_on_ammo_changed)
	GameState.key_inventory_changed.connect(_on_keys_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.notification_requested.connect(_on_notification_requested)
	GameState.pickup_notification_requested.connect(_on_pickup_notification_requested)
	GameState.level_stats_changed.connect(_on_level_stats_changed)
	GameState.hit_confirmed.connect(_on_hit_confirmed)
	GameState.headshot_confirmed.connect(_on_headshot_confirmed)
	GameState.damage_received.connect(_on_damage_received)
	GameState.player_died.connect(_on_player_died)
	SettingsManager.language_changed.connect(_on_language_changed)
	_weapon_presenter = VexHudWeaponPresenter.new()
	add_child(_weapon_presenter)
	_weapon_presenter.setup(weapon_layer)
	restart_button.pressed.connect(_restart_from_beginning)
	death_main_menu_button.pressed.connect(GameState.return_to_main_menu)
	automap_view.discovery_changed.connect(_on_automap_discovery_changed)
	call_deferred("_configure_automap")
	GameState.register_hud(self)


func _process(delta: float) -> void:
	_world_ui_sample_remaining -= delta
	if _world_ui_sample_remaining <= 0.0:
		_world_ui_sample_remaining = world_ui_sample_interval
		_update_world_ui_sample()
	_update_low_health_overlay(delta)
	if _weapon_presenter != null:
		_weapon_presenter.update(delta, get_tree().paused or _is_dead or map_overlay.visible)
	if _crosshair_hit_timer > 0.0:
		_crosshair_hit_timer = maxf(_crosshair_hit_timer - delta, 0.0)
		if _crosshair_hit_timer <= 0.0:
			crosshair.modulate = crosshair_default_color


func _update_world_ui_sample() -> void:
	var player := GameState.player as Node3D
	if player != null and is_instance_valid(player):
		automap_view.update_player(player)
	if (
		not _is_dead
		and not pause_menu.visible
		and not map_overlay.visible
		and player != null
		and is_instance_valid(player)
	):
		interaction_label.text = str(player.call("get_interaction_prompt"))
	else:
		interaction_label.text = ""


func _input(event: InputEvent) -> void:
	if _is_dead:
		return

	# TAB is the primary automap shortcut. Keep the InputMap action as a
	# configurable fallback, but also accept the physical/keycode directly
	# so the map cannot silently stop working when the project input mapping
	# is changed or regenerated.
	var is_tab_pressed := false
	if event is InputEventKey:
		var key_event := event as InputEventKey
		is_tab_pressed = key_event.pressed and not key_event.echo and (
			key_event.keycode == KEY_TAB
			or key_event.physical_keycode == KEY_TAB
		)

	if event.is_action_pressed("automap") or is_tab_pressed:
		if not pause_menu.visible and not get_tree().paused:
			get_viewport().set_input_as_handled()
			_set_map_open(not map_overlay.visible)
		return

	if pause_menu.visible:
		return
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_set_map_open(false)
		pause_menu.open_menu()


func _set_map_open(open: bool) -> void:
	map_overlay.visible = open
	automap_view.set_map_active(open)
	crosshair.visible = not open
	interaction_label.text = ""

	if GameState.player == null or not is_instance_valid(GameState.player):
		return

	# Harita ekranda iken dünya çalışmaya devam eder; sadece oyuncu kontrolleri kilitlenir.
	var player := GameState.player
	player.set_physics_process(not open)
	player.set_process_unhandled_input(not open)

	var weapon_controller := player.get_node_or_null("WeaponController")
	if weapon_controller != null:
		var weapon_fire_allowed := true
		var current_scene := get_tree().current_scene
		if current_scene != null and current_scene.has_method("is_weapon_fire_allowed"):
			weapon_fire_allowed = bool(current_scene.call("is_weapon_fire_allowed"))
		weapon_controller.set_process(not open and weapon_fire_allowed)
		weapon_controller.set_process_unhandled_input(not open and weapon_fire_allowed)



func get_crosshair_screen_position() -> Vector2:
	# Nişangah sahnede nereye taşınırsa atış sistemi aynı ekran noktasını kullanır.
	# Recoil nedeniyle nişangah hareket ediyorsa güncel konumu da hesaba katılır.
	return crosshair.get_global_rect().get_center()


func set_weapon_recoil_offset(recoil_degrees: Vector2) -> void:
	# X = yatay sekme (derece), Y = dikey sekme (derece).
	# Atış ışını, sahnedeki nişangahın güncel konumunu izler.
	var screen_offset := Vector2(
		recoil_degrees.x * 18.0,
		-recoil_degrees.y * 13.0
	)
	crosshair.position = _crosshair_rest_position + screen_offset


func play_weapon_action(weapon_id: StringName, action: StringName) -> void:
	_current_weapon_id = weapon_id
	if _weapon_presenter != null:
		_weapon_presenter.play_action(weapon_id, action)
	if action == &"fire" and SettingsManager.screen_shake:
		_kick_weapon_layer()
	# Weapon audio stays on the current placeholder routing until dedicated VX-47/MP90
	# recordings are added. Visual routing is fully data-driven now.
	if action == &"fire":
		var fire_audio = null
		match weapon_id:
			&"p01": fire_audio = p01_audio
			&"p07": fire_audio = p07_audio
			&"p14": fire_audio = p14_audio
			&"p20": fire_audio = p20_audio
			&"sg04": fire_audio = sg04_audio
			&"sg09": fire_audio = sg09_audio
			&"vx47": fire_audio = vx47_audio
			&"mp90": fire_audio = mp90_audio
		if fire_audio.stream != null: fire_audio.play()
	elif action in [&"reload", &"reload_shell"]:
		var reload_player := shotgun_reload_audio if weapon_id in [&"sg04", &"sg09"] else pistol_reload_audio
		if reload_player.stream != null:
			match weapon_id:
				&"vx47":
					reload_player.pitch_scale = 0.88
				&"mp90":
					reload_player.pitch_scale = 1.12
				_:
					reload_player.pitch_scale = 1.0
			reload_player.stop()
			reload_player.play()
	elif action == &"empty":
		if empty_gun_audio.stream != null:
			empty_gun_audio.stop()
			empty_gun_audio.play()


func _get_weapon_controller() -> VexWeaponController:
	if GameState.player == null or not is_instance_valid(GameState.player):
		return null
	return GameState.player.get_node_or_null("WeaponController") as VexWeaponController


func _get_weapon_definition(weapon_id: StringName) -> WeaponDefinition:
	var controller := _get_weapon_controller()
	if controller == null:
		return null
	return controller.get_weapon_definition(weapon_id)


func _on_player_stats_changed(health: int, maximum_health: int, armor: int) -> void:
	health_value.text = str(health).pad_zeros(3)
	armor_value.text = str(armor).pad_zeros(3)
	health_meter.max_value = maximum_health
	health_meter.value = health
	armor_meter.value = armor
	_health_ratio = clampf(float(health) / maxf(float(maximum_health), 1.0), 0.0, 1.0)
	if health <= critical_health_threshold:
		health_status.text = tr("HUD_STATUS_CRITICAL")
		health_status.modulate = Color(1.0, 0.24, 0.14)
		health_value.modulate = Color(1.0, 0.28, 0.18)
	elif health < warning_health_threshold:
		health_status.text = tr("HUD_STATUS_WARNING")
		health_status.modulate = Color(1.0, 0.62, 0.24)
		health_value.modulate = Color(1.0, 0.72, 0.46)
	else:
		health_status.text = tr("HUD_STATUS_NORMAL")
		health_status.modulate = Color(0.45, 0.9, 1.0)
		health_value.modulate = Color.WHITE
	armor_status.text = tr("HUD_ARMOR_ACTIVE") if armor > 0 else tr("HUD_ARMOR_INACTIVE")
	armor_status.modulate = Color(0.34, 0.84, 1.0) if armor > 0 else Color(0.42, 0.52, 0.56)


func _on_player_stamina_changed(current: float, maximum: float, sprinting: bool) -> void:
	stamina_value.text = str(roundi(current)).pad_zeros(3)
	stamina_meter.max_value = maximum
	stamina_meter.value = current
	if sprinting:
		stamina_status.text = tr("HUD_STAMINA_SPRINTING")
		stamina_status.modulate = Color(1.0, 0.68, 0.24)
	elif current <= 0.0:
		stamina_status.text = tr("HUD_STAMINA_EMPTY")
		stamina_status.modulate = Color(1.0, 0.34, 0.22)
	else:
		stamina_status.text = tr("HUD_STAMINA_READY")
		stamina_status.modulate = Color(0.42, 0.9, 0.68)
	low_health_overlay.visible = _health_ratio < low_health_overlay_ratio
	critical_health_overlay.visible = _health_ratio < critical_overlay_ratio
	if not low_health_overlay.visible:
		low_health_overlay.modulate.a = 0.0
		critical_health_overlay.modulate.a = 0.0
		_danger_pulse_time = 0.0
	elif not critical_health_overlay.visible:
		critical_health_overlay.modulate.a = 0.0


func _on_weapon_changed(weapon_id: StringName, display_name: String) -> void:
	_current_weapon_id = weapon_id
	var definition := _get_weapon_definition(weapon_id)
	weapon_name.text = tr(display_name)
	if definition != null:
		weapon_slot.text = tr(definition.hud_slot_label_key)
		ammo_type.text = tr(definition.hud_ammo_label_key)
	else:
		weapon_slot.text = tr("HUD_SLOT_UNKNOWN")
		ammo_type.text = tr("HUD_AMMUNITION")
	_apply_crosshair_weapon_scale(definition)
	if _weapon_presenter != null:
		_weapon_presenter.set_current_weapon(weapon_id)


func _apply_crosshair_weapon_scale(definition: WeaponDefinition) -> void:
	var multiplier := 1.0
	if definition != null:
		multiplier = maxf(0.5, definition.hud_crosshair_scale_multiplier)
	crosshair.scale = _crosshair_base_scale * multiplier


func _on_ammo_changed(current: int, reserve: int) -> void:
	ammo_value.text = str(current).pad_zeros(2)
	reserve_value.text = "/ %03d" % reserve
	ammo_value.modulate = Color(1.0, 0.32, 0.2) if current <= 2 else Color.WHITE


func _on_keys_changed(keys: Array[StringName]) -> void:
	# Each access key has its own fixed HUD slot; collecting one never changes another icon.
	key_icon.visible = keys.has(&"blue")
	red_key_icon.visible = keys.has(&"red")
	yellow_key_icon.visible = keys.has(&"yellow")


func _on_objective_changed(text: String) -> void:
	objective_label.text = tr("HUD_OBJECTIVE_FORMAT") % tr(text)


func _on_level_stats_changed(kills: int, total_enemies: int, secrets: int, total_secrets: int) -> void:
	kills_value.text = tr("HUD_STATS_FORMAT") % [kills, total_enemies, secrets, total_secrets]


func _on_notification_requested(text: String) -> void:
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	notification_label.text = tr(text)
	notification_panel.visible = true
	notification_panel.modulate.a = 1.0
	_notification_tween = create_tween()
	_notification_tween.tween_interval(notification_hold_time)
	_notification_tween.tween_property(notification_panel, "modulate:a", 0.0, notification_fade_time)
	_notification_tween.tween_callback(func() -> void: notification_panel.visible = false)


func _on_pickup_notification_requested(text: String, category: StringName) -> void:
	var category_text := tr("HUD_CATEGORY_INVENTORY")
	var accent_color := Color(0.35, 0.88, 1.0)
	var use_left := false
	match category:
		&"health":
			category_text = tr("HUD_CATEGORY_HEALTH")
			accent_color = Color(1.0, 0.31, 0.18)
			use_left = true
		&"armor":
			category_text = tr("HUD_CATEGORY_ARMOR")
			accent_color = Color(0.26, 0.82, 1.0)
			use_left = true
		&"ammo":
			category_text = tr("HUD_CATEGORY_AMMO")
			accent_color = Color(1.0, 0.61, 0.24)
		&"weapon":
			category_text = tr("HUD_CATEGORY_WEAPON")
			accent_color = Color(1.0, 0.35, 0.2)
		&"key":
			category_text = tr("HUD_CATEGORY_ACCESS")
			accent_color = Color(0.22, 0.82, 1.0)

	if use_left:
		if _pickup_left_tween != null and _pickup_left_tween.is_valid():
			_pickup_left_tween.kill()
		pickup_left_category.text = category_text
		pickup_left_category.modulate = accent_color
		pickup_left_value.text = tr(text)
		pickup_left_accent.color = accent_color
		pickup_feed_left.position = _pickup_left_rest_position + Vector2(-28.0, 0.0)
		pickup_feed_left.modulate.a = 0.0
		pickup_feed_left.visible = true
		_pickup_left_tween = _animate_pickup_feed(
			pickup_feed_left,
			_pickup_left_rest_position
		)
	else:
		if _pickup_right_tween != null and _pickup_right_tween.is_valid():
			_pickup_right_tween.kill()
		pickup_right_category.text = category_text
		pickup_right_category.modulate = accent_color
		pickup_right_value.text = tr(text)
		pickup_right_accent.color = accent_color
		pickup_feed_right.position = _pickup_right_rest_position + Vector2(28.0, 0.0)
		pickup_feed_right.modulate.a = 0.0
		pickup_feed_right.visible = true
		_pickup_right_tween = _animate_pickup_feed(
			pickup_feed_right,
			_pickup_right_rest_position
		)


func _animate_pickup_feed(feed: Control, rest_position: Vector2) -> Tween:
	var tween := create_tween()
	tween.tween_property(feed, "position", rest_position, pickup_slide_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(feed, "modulate:a", 1.0, 0.12)
	tween.tween_interval(pickup_hold_time)
	tween.tween_property(feed, "modulate:a", 0.0, pickup_fade_time)
	tween.tween_callback(func() -> void: feed.visible = false)
	return tween


func _on_hit_confirmed() -> void:
	_crosshair_hit_timer = crosshair_hit_duration
	crosshair.modulate = crosshair_hit_color


func _on_headshot_confirmed() -> void:
	_crosshair_hit_timer = crosshair_hit_duration * 1.25
	crosshair.modulate = crosshair_headshot_color


func _on_damage_received(amount: int) -> void:
	if amount <= 0:
		return
	if _damage_tween != null and _damage_tween.is_valid():
		_damage_tween.kill()
	damage_flash.visible = true
	damage_flash.color.a = 0.34
	damage_amount.visible = true
	damage_amount.text = "-%d" % amount
	damage_amount.modulate.a = 1.0
	damage_amount.position = _damage_amount_rest_position
	_damage_tween = create_tween().set_parallel(true)
	_damage_tween.tween_property(damage_flash, "color:a", 0.0, 0.42)
	_damage_tween.tween_property(damage_amount, "position:y", _damage_amount_rest_position.y - 70.0, damage_feedback_time)
	_damage_tween.tween_property(damage_amount, "modulate:a", 0.0, damage_feedback_time)
	_damage_tween.chain().tween_callback(_hide_damage_effects)


func _hide_damage_effects() -> void:
	damage_flash.visible = false
	damage_amount.visible = false


func _update_low_health_overlay(delta: float) -> void:
	if not low_health_overlay.visible:
		return

	_danger_pulse_time += delta
	var danger := clampf(inverse_lerp(low_health_overlay_ratio, 0.0, _health_ratio), 0.0, 1.0)
	var pulse_speed := lerpf(2.2, 6.4, danger)
	var pulse := (sin(_danger_pulse_time * pulse_speed) + 1.0) * 0.5
	var base_alpha := lerpf(0.05, 0.38, danger)
	var pulse_alpha := lerpf(0.03, 0.27, danger) * pulse
	low_health_overlay.modulate.a = clampf(base_alpha + pulse_alpha, 0.0, 0.65)

	if critical_health_overlay.visible:
		var critical := clampf(inverse_lerp(critical_overlay_ratio, 0.0, _health_ratio), 0.0, 1.0)
		var critical_pulse := (sin(_danger_pulse_time * (pulse_speed + 0.85)) + 1.0) * 0.5
		var critical_alpha := lerpf(0.03, 0.42, critical)
		critical_alpha += lerpf(0.02, 0.2, critical) * critical_pulse
		critical_health_overlay.modulate.a = clampf(critical_alpha, 0.0, 0.62)


func _on_player_died() -> void:
	_is_dead = true
	map_overlay.visible = false
	automap_view.set_map_active(false)
	crosshair.visible = false
	death_panel.visible = true
	_stop_level_audio()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_play_death_audio_sequence()
	restart_button.grab_focus()


func _stop_level_audio() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null:
		return
	for node_name: StringName in [&"LevelMusic", &"AmbientLoop"]:
		var audio := current_scene.get_node_or_null(NodePath(str(node_name))) as AudioStreamPlayer
		if audio != null:
			audio.stop()


func _play_death_audio_sequence() -> void:
	if player_death_audio.stream != null:
		player_death_audio.stop()
		player_death_audio.play()
	await get_tree().create_timer(0.65, true).timeout
	if not _is_dead or not is_inside_tree():
		return
	if game_over_music.stream != null:
		game_over_music.stop()
		game_over_music.play()


func _restart_from_beginning() -> void:
	death_panel.visible = false
	player_death_audio.stop()
	game_over_music.stop()
	GameState.restart_level()


func _kick_weapon_layer() -> void:
	if _weapon_tween != null and _weapon_tween.is_valid():
		_weapon_tween.kill()
	weapon_layer.position = _weapon_layer_rest_position + Vector2(randf_range(-5.0, 5.0), 12.0)
	_weapon_tween = create_tween()
	_weapon_tween.tween_property(weapon_layer, "position", _weapon_layer_rest_position, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)



func _configure_automap() -> void:
	var current_scene := get_tree().current_scene
	if current_scene == null or not current_scene.has_method("get_automap_config"):
		automap_view.configure({}, current_scene)
		map_title.text = tr("HUD_MAP_TITLE")
		map_status.text = tr("HUD_MAP_NO_DATA")
		return

	var config_value: Variant = current_scene.call("get_automap_config")
	if not (config_value is Dictionary):
		automap_view.configure({}, current_scene)
		map_title.text = tr("HUD_MAP_TITLE")
		map_status.text = tr("HUD_MAP_INVALID_DATA")
		return

	var config := config_value as Dictionary
	automap_view.configure(config, current_scene)
	map_title.text = tr(automap_view.get_map_title())
	var counts := automap_view.get_discovery_counts()
	_on_automap_discovery_changed(counts.x, counts.y)
	if GameState.player != null and is_instance_valid(GameState.player):
		automap_view.update_player(GameState.player as Node3D)


func _on_automap_discovery_changed(visited_count: int, total_count: int) -> void:
	if total_count <= 0:
		map_status.text = tr("HUD_MAP_NO_DATA")
		return
	var discovery_percent := clampi(
		int(round(float(visited_count) / float(total_count) * 100.0)),
		0,
		100
	)
	map_status.text = tr("HUD_MAP_DISCOVERY_FORMAT") % [
		visited_count,
		total_count,
		discovery_percent,
	]


func _on_language_changed(_locale: String) -> void:
	_on_objective_changed(GameState.objective)
	_configure_automap()
	if GameState.player != null and is_instance_valid(GameState.player):
		GameState.player.call_deferred("broadcast_state")
