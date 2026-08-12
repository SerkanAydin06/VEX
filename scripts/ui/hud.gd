class_name VexHUD
extends CanvasLayer

const DOOM3_CROSSHAIR: Texture2D = preload("res://assets/ui/crosshair_doom3_circle.png")
const MP90_VIEW_SCENE: PackedScene = preload("res://scenes/ui/weapons/mp90_view.tscn")

@export_category("Nişangah")
@export var crosshair_default_color := Color(0.93, 0.96, 1.0, 0.78)
@export var crosshair_hit_color := Color(1.0, 0.0, 0.0, 1.0)
@export_range(0.05, 1.0, 0.01) var crosshair_hit_duration := 0.24

@export_category("Performans")
@export_range(0.02, 0.25, 0.01) var world_ui_sample_interval := 0.05

@onready var health_value: Label = %HealthValue
@onready var armor_value: Label = %ArmorValue
@onready var health_meter: ProgressBar = %HealthMeter
@onready var armor_meter: ProgressBar = %ArmorMeter
@onready var health_status: Label = %HealthStatus
@onready var armor_status: Label = %ArmorStatus
@onready var ammo_value: Label = %AmmoValue
@onready var reserve_value: Label = %ReserveValue
@onready var weapon_name: Label = %WeaponName
@onready var weapon_slot: Label = %WeaponSlot
@onready var ammo_type: Label = %AmmoType
@onready var kills_value: Label = %KillsValue
@onready var key_icon: TextureRect = %KeyIcon
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
@onready var pistol_sprite: AnimatedSprite2D = %PistolSprite
@onready var shotgun_sprite: AnimatedSprite2D = %ShotgunSprite
@onready var ak47_sprite: AnimatedSprite2D = %AK47Sprite
var mp90_sprite: AnimatedSprite2D = null
@onready var pistol_audio: AudioStreamPlayer = %PistolAudio
@onready var shotgun_audio: AudioStreamPlayer = %ShotgunAudio
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

var _current_weapon_id: StringName = &"pistol"
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
var _ak47_ready := false
var _mp90_ready := false
var _world_ui_sample_remaining := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_weapon_layer_rest_position = weapon_layer.position
	_crosshair_rest_position = crosshair.position
	crosshair.texture = DOOM3_CROSSHAIR
	crosshair.modulate = crosshair_default_color
	_damage_amount_rest_position = damage_amount.position
	_pickup_left_rest_position = pickup_feed_left.position
	_pickup_right_rest_position = pickup_feed_right.position
	GameState.player_stats_changed.connect(_on_player_stats_changed)
	GameState.weapon_changed.connect(_on_weapon_changed)
	GameState.ammo_changed.connect(_on_ammo_changed)
	GameState.key_inventory_changed.connect(_on_keys_changed)
	GameState.objective_changed.connect(_on_objective_changed)
	GameState.notification_requested.connect(_on_notification_requested)
	GameState.pickup_notification_requested.connect(_on_pickup_notification_requested)
	GameState.level_stats_changed.connect(_on_level_stats_changed)
	GameState.hit_confirmed.connect(_on_hit_confirmed)
	GameState.damage_received.connect(_on_damage_received)
	GameState.player_died.connect(_on_player_died)
	pistol_sprite.animation_finished.connect(_on_weapon_animation_finished.bind(pistol_sprite))
	shotgun_sprite.animation_finished.connect(_on_weapon_animation_finished.bind(shotgun_sprite))
	_configure_weapon_frame_alignment(pistol_sprite)
	_configure_weapon_frame_alignment(shotgun_sprite)
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

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and (key_event.keycode == KEY_TAB or key_event.physical_keycode == KEY_TAB)
		):
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
		weapon_controller.set_process(not open)
		weapon_controller.set_process_unhandled_input(not open)



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
	_ensure_weapon_sprite_ready(weapon_id)
	var sprite := _get_weapon_sprite(weapon_id)
	_set_weapon_sprite_visibility(weapon_id)
	if sprite != null:
		if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(action):
			if weapon_id in [&"ak47", &"mp90"] and action == &"fire":
				# Her mermide üç karelik ateş animasyonunu baştan oynat.
				sprite.stop()
				sprite.play(&"fire")
			else:
				sprite.play(action)
		else:
			sprite.play(&"idle")
	if action == &"fire" and SettingsManager.screen_shake:
		_kick_weapon_layer()
	if action == &"fire":
		var fire_audio := shotgun_audio if weapon_id == &"shotgun" else pistol_audio
		if fire_audio.stream != null:
			match weapon_id:
				&"ak47":
					fire_audio.pitch_scale = 0.82
				&"mp90":
					fire_audio.pitch_scale = 1.18
				_:
					fire_audio.pitch_scale = 1.0
			fire_audio.play()
	elif action == &"reload":
		var reload_player := shotgun_reload_audio if weapon_id == &"shotgun" else pistol_reload_audio
		if reload_player.stream != null:
			match weapon_id:
				&"ak47":
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


func _get_weapon_sprite(weapon_id: StringName) -> AnimatedSprite2D:
	match weapon_id:
		&"pistol":
			return pistol_sprite
		&"shotgun":
			return shotgun_sprite
		&"ak47":
			return ak47_sprite
		&"mp90":
			return mp90_sprite
	return pistol_sprite


func _set_weapon_sprite_visibility(weapon_id: StringName) -> void:
	pistol_sprite.visible = weapon_id == &"pistol"
	shotgun_sprite.visible = weapon_id == &"shotgun"
	ak47_sprite.visible = weapon_id == &"ak47"
	if mp90_sprite != null:
		mp90_sprite.visible = weapon_id == &"mp90"


func _ensure_weapon_sprite_ready(weapon_id: StringName) -> void:
	match weapon_id:
		&"ak47":
			if _ak47_ready:
				return
			_setup_ak47_sprite_frames()
			ak47_sprite.animation_finished.connect(
				_on_weapon_animation_finished.bind(ak47_sprite)
			)
			_configure_weapon_frame_alignment(ak47_sprite)
		&"mp90":
			if _mp90_ready:
				return
			_ensure_mp90_sprite()
			_setup_mp90_sprite_frames()
			if mp90_sprite != null:
				mp90_sprite.animation_finished.connect(
					_on_weapon_animation_finished.bind(mp90_sprite)
				)
				_configure_weapon_frame_alignment(mp90_sprite)


func _configure_weapon_frame_alignment(sprite: AnimatedSprite2D) -> void:
	if sprite == null or sprite.sprite_frames == null:
		return
	var idle_texture := sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if idle_texture == null:
		return
	var reference_anchor := _get_texture_visual_anchor(idle_texture)
	var offsets: Dictionary = {}
	for animation_name: StringName in sprite.sprite_frames.get_animation_names():
		var frame_count := sprite.sprite_frames.get_frame_count(animation_name)
		for frame_index: int in range(frame_count):
			var texture := sprite.sprite_frames.get_frame_texture(animation_name, frame_index)
			if texture == null:
				continue
			offsets[_weapon_frame_key(animation_name, frame_index)] = (
				reference_anchor - _get_texture_visual_anchor(texture)
			)
	sprite.set_meta("vex_frame_offsets", offsets)
	sprite.frame_changed.connect(_apply_weapon_frame_alignment.bind(sprite))
	_apply_weapon_frame_alignment(sprite)


func _get_texture_visual_anchor(texture: Texture2D) -> Vector2:
	var texture_size := texture.get_size()
	var image := texture.get_image()
	if image == null or image.is_empty():
		return Vector2.ZERO
	var used_rect := image.get_used_rect()
	if used_rect.size == Vector2i.ZERO:
		return Vector2.ZERO
	return Vector2(
		float(used_rect.position.x) + float(used_rect.size.x) * 0.5 - texture_size.x * 0.5,
		float(used_rect.position.y + used_rect.size.y) - texture_size.y * 0.5
	)


func _apply_weapon_frame_alignment(sprite: AnimatedSprite2D) -> void:
	if sprite == null or not sprite.has_meta("vex_frame_offsets"):
		return
	var offsets := sprite.get_meta("vex_frame_offsets") as Dictionary
	sprite.offset = offsets.get(_weapon_frame_key(sprite.animation, sprite.frame), Vector2.ZERO)


func _weapon_frame_key(animation_name: StringName, frame_index: int) -> String:
	return "%s:%d" % [String(animation_name), frame_index]


func _load_first_weapon_texture(candidates: Array[String]) -> Texture2D:
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	return null


func _setup_ak47_sprite_frames() -> void:
	var idle := _load_first_weapon_texture([
		"res://assets/weapons/ak47_idle.png",
	])
	var fire_1 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_fire_1.png",
	])
	var fire_2 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_fire_2.png",
	])
	var fire_3 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_fire_3.png",
	])
	var reload_1 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_reload_1.png",
	])
	var reload_2 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_reload_2.png",
	])
	var reload_3 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_reload_3.png",
	])
	var reload_4 := _load_first_weapon_texture([
		"res://assets/weapons/ak47_reload_4.png",
	])

	if idle == null:
		push_warning("AK-47 HUD görseli bulunamadı: assets/weapons/ak47_idle.png")
		idle = pistol_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if fire_1 == null:
		push_warning("AK-47 fire_1 görseli bulunamadı.")
		fire_1 = idle
	if fire_2 == null:
		push_warning("AK-47 fire_2 görseli bulunamadı.")
		fire_2 = fire_1
	if fire_3 == null:
		push_warning("AK-47 fire_3 görseli bulunamadı.")
		fire_3 = fire_2
	if reload_1 == null:
		reload_1 = idle
	if reload_2 == null:
		reload_2 = reload_1
	if reload_3 == null:
		reload_3 = reload_2
	if reload_4 == null:
		reload_4 = reload_3

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)
	frames.add_frame(&"idle", idle)

	frames.add_animation(&"fire")
	frames.set_animation_loop(&"fire", false)
	# 3 kare / 0.10 sn: tam otomatik AK-47 atış aralığıyla senkron.
	frames.set_animation_speed(&"fire", 30.0)
	frames.add_frame(&"fire", fire_1)
	frames.add_frame(&"fire", fire_2)
	frames.add_frame(&"fire", fire_3)

	frames.add_animation(&"reload")
	frames.set_animation_loop(&"reload", false)
	# 4 kare / 1.2 saniye: AK-47'nin gerçek reload süresiyle senkron.
	frames.set_animation_speed(&"reload", 4.0 / 1.2)
	frames.add_frame(&"reload", reload_1)
	frames.add_frame(&"reload", reload_2)
	frames.add_frame(&"reload", reload_3)
	frames.add_frame(&"reload", reload_4)

	frames.add_animation(&"equip")
	frames.set_animation_loop(&"equip", false)
	frames.set_animation_speed(&"equip", 1.0)
	frames.add_frame(&"equip", idle)

	ak47_sprite.sprite_frames = frames
	ak47_sprite.animation = &"idle"
	ak47_sprite.play(&"idle")

	var texture_size := idle.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		var fit_scale := minf(1.0, minf(1120.0 / texture_size.x, 680.0 / texture_size.y))
		ak47_sprite.scale = Vector2.ONE * fit_scale
	_ak47_ready = true


func _ensure_mp90_sprite() -> void:
	var existing := weapon_layer.get_node_or_null("MP90Sprite") as AnimatedSprite2D
	if existing != null:
		mp90_sprite = existing
		return
	mp90_sprite = MP90_VIEW_SCENE.instantiate() as AnimatedSprite2D
	if mp90_sprite == null:
		push_error("MP90 HUD sahnesi oluşturulamadı.")
		return
	weapon_layer.add_child(mp90_sprite)


func _setup_mp90_sprite_frames() -> void:
	if mp90_sprite == null:
		return

	var idle := _load_first_weapon_texture([
		"res://assets/weapons/mp90_idle.png",
	])
	var fire_1 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_fire_1.png",
	])
	var fire_2 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_fire_2.png",
	])
	var fire_3 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_fire_3.png",
	])
	var reload_1 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_reload_1.png",
	])
	var reload_2 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_reload_2.png",
	])
	var reload_3 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_reload_3.png",
	])
	var reload_4 := _load_first_weapon_texture([
		"res://assets/weapons/mp90_reload_4.png",
	])

	if idle == null:
		push_warning("MP90 HUD görseli bulunamadı: assets/weapons/mp90_idle.png")
		idle = pistol_sprite.sprite_frames.get_frame_texture(&"idle", 0)
	if fire_1 == null:
		fire_1 = idle
	if fire_2 == null:
		fire_2 = fire_1
	if fire_3 == null:
		fire_3 = fire_2
	if reload_1 == null:
		reload_1 = idle
	if reload_2 == null:
		reload_2 = reload_1
	if reload_3 == null:
		reload_3 = reload_2
	if reload_4 == null:
		reload_4 = reload_3

	var frames := SpriteFrames.new()
	if frames.has_animation(&"default"):
		frames.remove_animation(&"default")

	frames.add_animation(&"idle")
	frames.set_animation_loop(&"idle", true)
	frames.set_animation_speed(&"idle", 1.0)
	frames.add_frame(&"idle", idle)

	frames.add_animation(&"fire")
	frames.set_animation_loop(&"fire", false)
	# 3 kare / 0.07 sn: MP90'un 857 RPM civarı atış hızıyla senkron.
	frames.set_animation_speed(&"fire", 3.0 / 0.07)
	frames.add_frame(&"fire", fire_1)
	frames.add_frame(&"fire", fire_2)
	frames.add_frame(&"fire", fire_3)

	frames.add_animation(&"reload")
	frames.set_animation_loop(&"reload", false)
	# 4 kare / 1.35 sn: gerçek reload süresiyle aynı anda biter.
	frames.set_animation_speed(&"reload", 4.0 / 1.35)
	frames.add_frame(&"reload", reload_1)
	frames.add_frame(&"reload", reload_2)
	frames.add_frame(&"reload", reload_3)
	frames.add_frame(&"reload", reload_4)

	frames.add_animation(&"equip")
	frames.set_animation_loop(&"equip", false)
	frames.set_animation_speed(&"equip", 1.0)
	frames.add_frame(&"equip", idle)

	mp90_sprite.sprite_frames = frames
	mp90_sprite.animation = &"idle"
	mp90_sprite.play(&"idle")

	var texture_size := idle.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		# MP90 ekranda gereğinden büyük görünmesin.
		var fit_scale := minf(0.82, minf(920.0 / texture_size.x, 560.0 / texture_size.y))
		mp90_sprite.scale = Vector2.ONE * fit_scale
	_mp90_ready = true


func _on_player_stats_changed(health: int, maximum_health: int, armor: int) -> void:
	health_value.text = str(health).pad_zeros(3)
	armor_value.text = str(armor).pad_zeros(3)
	health_meter.max_value = maximum_health
	health_meter.value = health
	armor_meter.value = armor
	_health_ratio = clampf(float(health) / maxf(float(maximum_health), 1.0), 0.0, 1.0)
	if health <= 25:
		health_status.text = "KRİTİK"
		health_status.modulate = Color(1.0, 0.24, 0.14)
		health_value.modulate = Color(1.0, 0.28, 0.18)
	elif health < 50:
		health_status.text = "SİSTEM UYARI"
		health_status.modulate = Color(1.0, 0.62, 0.24)
		health_value.modulate = Color(1.0, 0.72, 0.46)
	else:
		health_status.text = "SİSTEM NORMAL"
		health_status.modulate = Color(0.45, 0.9, 1.0)
		health_value.modulate = Color.WHITE
	armor_status.text = "DARBE EMİCİ AKTİF" if armor > 0 else "KORUMA PASİF"
	armor_status.modulate = Color(0.34, 0.84, 1.0) if armor > 0 else Color(0.42, 0.52, 0.56)
	low_health_overlay.visible = _health_ratio < 0.5
	critical_health_overlay.visible = _health_ratio < 0.3
	if not low_health_overlay.visible:
		low_health_overlay.modulate.a = 0.0
		critical_health_overlay.modulate.a = 0.0
		_danger_pulse_time = 0.0
	elif not critical_health_overlay.visible:
		critical_health_overlay.modulate.a = 0.0


func _on_weapon_changed(weapon_id: StringName, display_name: String) -> void:
	_current_weapon_id = weapon_id
	_ensure_weapon_sprite_ready(weapon_id)
	weapon_name.text = display_name
	match weapon_id:
		&"pistol":
			weapon_slot.text = "SLOT 01"
			ammo_type.text = "9×19 MM // YARI OTOMATİK"
		&"shotgun":
			weapon_slot.text = "SLOT 02"
			ammo_type.text = "12 GA // POMPALI"
		&"ak47":
			weapon_slot.text = "SLOT 03"
			ammo_type.text = "7.62×39 MM // TAM OTOMATİK"
		&"mp90":
			weapon_slot.text = "SLOT 04"
			ammo_type.text = "5.7×28 MM // TAM OTOMATİK"
		_:
			weapon_slot.text = "SLOT --"
			ammo_type.text = "MÜHİMMAT"
	_set_weapon_sprite_visibility(weapon_id)
	var sprite := _get_weapon_sprite(weapon_id)
	if sprite != null and sprite.animation != &"fire" and sprite.animation != &"reload":
		sprite.play(&"idle")


func _on_ammo_changed(current: int, reserve: int) -> void:
	ammo_value.text = str(current).pad_zeros(2)
	reserve_value.text = "/ %03d" % reserve
	ammo_value.modulate = Color(1.0, 0.32, 0.2) if current <= 2 else Color.WHITE


func _on_keys_changed(keys: Array[StringName]) -> void:
	key_icon.visible = keys.has(&"blue")


func _on_objective_changed(text: String) -> void:
	objective_label.text = "GÖREV:  " + text


func _on_level_stats_changed(kills: int, total_enemies: int, secrets: int, total_secrets: int) -> void:
	kills_value.text = "%02d / %02d     GİZLİ: %d / %d" % [kills, total_enemies, secrets, total_secrets]


func _on_notification_requested(text: String) -> void:
	if _notification_tween != null and _notification_tween.is_valid():
		_notification_tween.kill()
	notification_label.text = text
	notification_panel.visible = true
	notification_panel.modulate.a = 1.0
	_notification_tween = create_tween()
	_notification_tween.tween_interval(2.5)
	_notification_tween.tween_property(notification_panel, "modulate:a", 0.0, 0.35)
	_notification_tween.tween_callback(func() -> void: notification_panel.visible = false)


func _on_pickup_notification_requested(text: String, category: StringName) -> void:
	var category_text := "// ENVANTER"
	var accent_color := Color(0.35, 0.88, 1.0)
	var use_left := false
	match category:
		&"health":
			category_text = "// YAŞAMSAL DESTEK"
			accent_color = Color(1.0, 0.31, 0.18)
			use_left = true
		&"armor":
			category_text = "// ZIRH SİSTEMİ"
			accent_color = Color(0.26, 0.82, 1.0)
			use_left = true
		&"ammo":
			category_text = "// MÜHİMMAT"
			accent_color = Color(1.0, 0.61, 0.24)
		&"weapon":
			category_text = "// SİLAH AĞI"
			accent_color = Color(1.0, 0.35, 0.2)
		&"key":
			category_text = "// ERİŞİM YETKİSİ"
			accent_color = Color(0.22, 0.82, 1.0)

	if use_left:
		if _pickup_left_tween != null and _pickup_left_tween.is_valid():
			_pickup_left_tween.kill()
		pickup_left_category.text = category_text
		pickup_left_category.modulate = accent_color
		pickup_left_value.text = text
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
		pickup_right_value.text = text
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
	tween.tween_property(feed, "position", rest_position, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(feed, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.85)
	tween.tween_property(feed, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func() -> void: feed.visible = false)
	return tween


func _on_hit_confirmed() -> void:
	_crosshair_hit_timer = crosshair_hit_duration
	crosshair.modulate = crosshair_hit_color


func _on_damage_received(amount: int) -> void:
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
	_damage_tween.tween_property(damage_amount, "position:y", _damage_amount_rest_position.y - 70.0, 0.6)
	_damage_tween.tween_property(damage_amount, "modulate:a", 0.0, 0.6)
	_damage_tween.chain().tween_callback(_hide_damage_effects)


func _hide_damage_effects() -> void:
	damage_flash.visible = false
	damage_amount.visible = false


func _update_low_health_overlay(delta: float) -> void:
	if not low_health_overlay.visible:
		return

	_danger_pulse_time += delta
	var danger := clampf(inverse_lerp(0.5, 0.0, _health_ratio), 0.0, 1.0)
	var pulse_speed := lerpf(2.2, 6.4, danger)
	var pulse := (sin(_danger_pulse_time * pulse_speed) + 1.0) * 0.5
	var base_alpha := lerpf(0.05, 0.38, danger)
	var pulse_alpha := lerpf(0.03, 0.27, danger) * pulse
	low_health_overlay.modulate.a = clampf(base_alpha + pulse_alpha, 0.0, 0.65)

	if critical_health_overlay.visible:
		var critical := clampf(inverse_lerp(0.3, 0.0, _health_ratio), 0.0, 1.0)
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


func _on_weapon_animation_finished(sprite: AnimatedSprite2D) -> void:
	if sprite.animation != &"idle":
		sprite.play(&"idle")


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
		map_title.text = "TESİS HARİTASI"
		map_status.text = "HARİTA VERİSİ YOK"
		return

	var config_value: Variant = current_scene.call("get_automap_config")
	if not (config_value is Dictionary):
		automap_view.configure({}, current_scene)
		map_title.text = "TESİS HARİTASI"
		map_status.text = "HARİTA VERİSİ GEÇERSİZ"
		return

	var config := config_value as Dictionary
	automap_view.configure(config, current_scene)
	map_title.text = automap_view.get_map_title()
	var counts := automap_view.get_discovery_counts()
	_on_automap_discovery_changed(counts.x, counts.y)
	if GameState.player != null and is_instance_valid(GameState.player):
		automap_view.update_player(GameState.player as Node3D)


func _on_automap_discovery_changed(visited_count: int, total_count: int) -> void:
	if total_count <= 0:
		map_status.text = "HARİTA VERİSİ YOK"
		return
	var discovery_percent := clampi(
		int(round(float(visited_count) / float(total_count) * 100.0)),
		0,
		100
	)
	map_status.text = "KEŞİF %02d/%02d  //  %03d%%" % [
		visited_count,
		total_count,
		discovery_percent,
	]
