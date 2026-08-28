class_name VexPlayer
extends CharacterBody3D

const DROPPED_WEAPON_PICKUP_SCENE := preload("res://scenes/props/pickup.tscn")

@export_category("Hareket")
@export_range(1.0, 12.0, 0.1) var walk_speed := 4.0
@export_range(1.0, 16.0, 0.1) var sprint_speed := 8.0
@export_range(1.0, 40.0, 0.5) var acceleration := 18.0
@export_range(1.0, 40.0, 0.5) var deceleration := 22.0
@export_category("Zıplama")
@export_range(1.0, 20.0, 0.1) var jump_velocity := 7.0
@export_range(0.0, 100.0, 1.0) var jump_stamina_cost := 15.0
@export_category("Çömelme")
@export_range(1.0, 12.0, 0.1) var crouch_speed := 2.9
@export_range(0.7, 2.5, 0.01) var crouch_capsule_height := 1.10
@export_range(0.0, 1.8, 0.01) var crouch_view_pivot_height := 0.30
@export_range(1.0, 30.0, 0.5) var crouch_transition_speed := 12.0
@export_range(0.0, 0.1, 0.005) var stand_clearance_margin := 0.02
@export_category("Nişan Alma / ADS")
@export_range(1.0, 500.0, 0.5) var ads_transition_speed := 200.0
@export_range(0.0, 1.0, 0.01) var ads_spread_multiplier := 0.0
@export_range(0.05, 1.0, 0.01) var ads_recoil_multiplier := 0.72
@export_category("Sprint Dayanıklılığı")
@export_range(1.0, 300.0, 1.0) var maximum_stamina := 100.0
@export_range(1.0, 120.0, 0.5) var sprint_stamina_drain_per_second := 26.0
@export_range(1.0, 120.0, 0.5) var stamina_recovery_per_second := 20.0
@export_range(0.0, 5.0, 0.05) var stamina_recovery_delay := 0.65
@export_range(0.0, 1.0, 0.01) var sprint_input_threshold := 0.10
@export_category("Dayanıklılık")
@export_range(1, 500, 1) var maximum_health := 10000000
@export_range(1, 500, 1) var maximum_armor := 100
@export_range(0, 500, 1) var initial_armor := 0
@export_range(0.0, 1.0, 0.01) var armor_absorption_ratio := 0.60
@export_range(0.0, 5.0, 0.05) var hurt_audio_cooldown := 0.90

@export_category("Kamera ve Fizik")
@export_range(-5.0, 0.0, 0.01) var floor_stick_velocity := -0.10
@export_range(0.0, 0.5, 0.01) var max_stair_step_height := 0.30
@export_range(30.0, 89.0, 1.0) var pitch_limit_degrees := 82.0
@export_range(0.0, 1.0, 0.01) var recoil_yaw_recovery_multiplier := 0.85

@export_category("Kamera Sallanması ve Adım")
@export_range(0.0, 1.0, 0.01) var bob_activation_threshold := 0.05
@export_range(0.1, 4.0, 0.05) var bob_speed_multiplier := 1.70
@export_range(0.1, 2.0, 0.05) var bob_horizontal_frequency_multiplier := 0.50
@export_range(0.0, 0.2, 0.001) var bob_horizontal_amplitude := 0.025
@export_range(0.0, 0.2, 0.001) var bob_vertical_amplitude := 0.035
@export_range(1.0, 30.0, 0.5) var bob_lerp_speed := 12.0
@export_range(1.0, 30.0, 0.5) var bob_return_lerp_speed := 10.0
@export_range(0.5, 1.5, 0.01) var footstep_pitch_min := 0.94
@export_range(0.5, 1.5, 0.01) var footstep_pitch_max := 1.06
@export_range(0.05, 2.0, 0.01) var sprint_footstep_interval := 0.34
@export_range(0.05, 2.0, 0.01) var walk_footstep_interval := 0.46
@export_range(0.0, 2.0, 0.05) var sprint_detection_margin := 0.10

@export_category("Night Vision")
@export var night_vision_shader: Shader
@export var night_vision_fallback_color := Color(0.05, 0.32, 0.08, 0.32)
@export_range(-16, 16, 1) var night_vision_canvas_layer := -1

@onready var view_pivot: Node3D = $ViewPivot
@onready var camera: Camera3D = $ViewPivot/Camera3D
@onready var interaction_ray: RayCast3D = $ViewPivot/Camera3D/InteractionRay
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var weapon_controller: Node = $WeaponController
@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio
@onready var hurt_audio: AudioStreamPlayer = $HurtAudio

var health := 0
var armor := 0
var stamina := 0.0
var keys: Array[StringName] = []
var is_dead := false
var is_sprinting := false
var is_crouching := false
var is_aiming := false
var _pitch := 0.0
var _bob_time := 0.0
var _camera_rest_position := Vector3.ZERO
var _gravity := 20.0
var _footstep_remaining := 0.0
var _hurt_audio_cooldown_remaining := 0.0
var _stamina_recovery_delay_remaining := 0.0
var _jump_requested := false
var _standing_capsule_height := 0.0
var _standing_collision_shape_y := 0.0
var _standing_view_pivot_height := 0.0
var _default_fov := 78.0

var _has_night_vision := false
var _night_vision_enabled := false
var _night_vision_layer: CanvasLayer = null
var _night_vision_rect: ColorRect = null

var _recoil_pitch_degrees := 0.0
var _recoil_yaw_degrees := 0.0
var _recoil_recovery_degrees_per_second := 7.0


func _ready() -> void:
	add_to_group("player")
	_camera_rest_position = camera.position
	_default_fov = SettingsManager.field_of_view
	camera.fov = _default_fov
	_setup_crouch_dimensions()
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	health = maximum_health
	armor = clampi(initial_armor, 0, maximum_armor)
	stamina = maximum_stamina
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)
	_setup_night_vision_overlay()


func _physics_process(delta: float) -> void:
	_hurt_audio_cooldown_remaining = maxf(
		0.0,
		_hurt_audio_cooldown_remaining - delta
	)
	if is_dead:
		velocity = Vector3.ZERO
		return
	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var local_direction := Vector3(input_vector.x, 0.0, input_vector.y)
	var world_direction := (transform.basis * local_direction).normalized()
	_update_controller_look(delta)
	_update_aiming(delta)
	# Sample jump in the physics loop so UI/event handling cannot swallow Space.
	if Input.is_action_just_pressed("jump"):
		_try_jump()
	# Sprint is only active while actually moving on the ground. This prevents
	# stamina from draining while standing still or airborne.
	var wants_to_sprint := (
		Input.is_action_pressed("sprint")
		and input_vector.length() >= sprint_input_threshold
		and stamina > 0.0
		and is_on_floor()
		and not is_crouching
		and not is_aiming
	)
	is_sprinting = wants_to_sprint
	_update_stamina(delta)
	var target_speed := (
		crouch_speed
		if is_crouching
		else (sprint_speed if is_sprinting else walk_speed)
	)
	var target_velocity := world_direction * target_speed
	var rate := acceleration if world_direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	var stepped_up := false
	if is_on_floor() and not _jump_requested and not is_crouching:
		stepped_up = _try_step_up(Vector3(velocity.x, 0.0, velocity.z) * delta)
	if _jump_requested:
		# Consume the jump request before floor/gravity handling so the
		# floor-stick velocity cannot overwrite the jump impulse.
		_jump_requested = false
		velocity.y = jump_velocity
	elif not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity
	move_and_slide()
	if stepped_up and not is_on_floor():
		apply_floor_snap()
	_update_crouch_view(delta)
	_update_recoil(delta)
	_update_view_bob(delta, input_vector.length(), target_speed)


func _try_step_up(horizontal_motion: Vector3) -> bool:
	if max_stair_step_height <= 0.0 or horizontal_motion.length_squared() <= 0.000001:
		return false
	# Only intervene when the normal horizontal move is blocked by a low obstacle.
	if not test_move(global_transform, horizontal_motion):
		return false
	var step_up := Vector3.UP * max_stair_step_height
	# Never step into a ceiling or another obstacle above the player.
	if test_move(global_transform, step_up):
		return false
	var raised_transform := global_transform.translated(step_up)
	# At step height the forward path must be clear. High walls therefore stay walls.
	if test_move(raised_transform, horizontal_motion):
		return false
	global_position += step_up
	return true


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or get_tree().paused:
		return

	if event.is_action_pressed("crouch"):
		# C = toggle crouch. Basili tutma gerekmez. Ayağa kalkmak için
		# yeterli alan yoksa mevcut çömelme korunur.
		if is_crouching:
			if _can_stand_up():
				_set_crouching(false)
		else:
			# Do not enter crouch while airborne.
			if is_on_floor():
				_set_crouching(true)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event := event as InputEventMouseMotion
		rotate_y(deg_to_rad(-mouse_event.relative.x * SettingsManager.mouse_sensitivity))
		_pitch = clampf(
			_pitch - deg_to_rad(mouse_event.relative.y * SettingsManager.mouse_sensitivity),
			deg_to_rad(-pitch_limit_degrees),
			deg_to_rad(pitch_limit_degrees)
		)
		_apply_view_rotation()
	elif event.is_action_pressed("night_vision"):
		if _has_night_vision:
			get_viewport().set_input_as_handled()
			_set_night_vision_enabled(not _night_vision_enabled)
	elif event.is_action_pressed("interact"):
		try_interact()


func _try_jump() -> void:
	if is_dead or get_tree().paused:
		return
	if is_crouching:
		# Crouch + jump önce ayağa kalkma isteğidir. Üstte yeterli alan varsa
		# aynı basışta zıplamadan stand pozuna geç; sıkışık alanda crouch korunur.
		if _can_stand_up():
			_set_crouching(false)
		return
	if not is_on_floor():
		return
	if stamina < jump_stamina_cost:
		return
	stamina -= jump_stamina_cost
	_stamina_recovery_delay_remaining = stamina_recovery_delay
	_jump_requested = true

func try_interact() -> void:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return
	var target := _resolve_interactable(interaction_ray.get_collider())
	if target != null and target.has_method("interact"):
		target.call("interact", self)


func get_interaction_prompt() -> String:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return ""
	var target := _resolve_interactable(interaction_ray.get_collider())
	if target != null and target.has_method("get_interaction_text"):
		return str(target.call("get_interaction_text", self))
	return ""


func collect_pickup(
	pickup_type: StringName,
	amount: int,
	source_pickup: Node3D = null
) -> bool:
	match pickup_type:
		&"health":
			if health >= maximum_health:
				return false
			var collected_health := mini(amount, maximum_health - health)
			health = mini(maximum_health, health + amount)
			GameState.notify_pickup(tr("PICKUP_HEALTH_FORMAT") % collected_health, &"health")
		&"armor":
			if armor >= maximum_armor:
				return false
			var collected_armor := mini(amount, maximum_armor - armor)
			armor = mini(maximum_armor, armor + amount)
			GameState.notify_pickup(tr("PICKUP_ARMOR_FORMAT") % collected_armor, &"armor")
		&"bullets", &"shells", &"rifle_ammo", &"mp90_ammo":
			var collected_ammo := int(weapon_controller.call("add_ammo", pickup_type, amount))
			if collected_ammo <= 0:
				return false
			var ammo_name := tr("AMMO_9X19")
			if pickup_type == &"shells":
				ammo_name = tr("AMMO_12GA")
			elif pickup_type == &"rifle_ammo":
				ammo_name = tr("AMMO_762")
			elif pickup_type == &"mp90_ammo":
				ammo_name = tr("AMMO_57")
			GameState.notify_pickup(tr("PICKUP_AMMO_FORMAT") % [ammo_name, collected_ammo], &"ammo")
		&"p01", &"p07", &"p14", &"p20", &"sg04", &"sg09":
			if not _collect_loadout_weapon_pickup(pickup_type, amount, source_pickup):
				return false
		&"vx47":
			weapon_controller.call("unlock_weapon", &"vx47", amount)
			GameState.notify_pickup(tr("PICKUP_RIFLE_ACTIVE"), &"weapon")
		&"mp90":
			weapon_controller.call("unlock_weapon", &"mp90", amount)
			GameState.notify_pickup(tr("PICKUP_MP90_ACTIVE"), &"weapon")
		&"night_vision":
			if _has_night_vision:
				return false
			_has_night_vision = true
			_set_night_vision_enabled(false, false)
			GameState.notify_pickup(
				tr("PICKUP_NIGHT_VISION"),
				&"equipment"
			)
		&"key_blue":
			if has_key(&"blue"):
				return false
			keys.append(&"blue")
			GameState.publish_keys(keys)
			GameState.notify_pickup(tr("KEY_BLUE"), &"key")
		&"key_red":
			if has_key(&"red"):
				return false
			keys.append(&"red")
			GameState.publish_keys(keys)
			GameState.notify_pickup(tr("KEY_RED"), &"key")
			# Anahtar toplama artık görev metnini değiştirmez; ilerleme kapı/oyun akışı üzerinden gösterilir.
		&"key_yellow":
			if has_key(&"yellow"):
				return false
			keys.append(&"yellow")
			GameState.publish_keys(keys)
			GameState.notify_pickup(tr("KEY_YELLOW"), &"key")
		_:
			return false
	broadcast_state()
	return true


func _collect_loadout_weapon_pickup(
	weapon_id: StringName,
	bonus_ammo: int,
	source_pickup: Node3D
) -> bool:
	var result := weapon_controller.call(
		"equip_world_weapon",
		weapon_id,
		bonus_ammo
	) as Dictionary
	if not bool(result.get("success", false)):
		return false

	var displaced_weapon_id := StringName(str(result.get("displaced_weapon_id", "")))
	var selected_definition := weapon_controller.call(
		"get_weapon_definition",
		weapon_id
	) as WeaponDefinition
	var selected_name := str(weapon_id)
	if selected_definition != null:
		selected_name = tr(selected_definition.display_name)

	if displaced_weapon_id != &"":
		var drop_position := _get_weapon_drop_position(source_pickup)
		call_deferred(
			"_spawn_dropped_weapon_pickup",
			displaced_weapon_id,
			drop_position
		)
		var displaced_definition := weapon_controller.call(
			"get_weapon_definition",
			displaced_weapon_id
		) as WeaponDefinition
		var displaced_name := str(displaced_weapon_id)
		if displaced_definition != null:
			displaced_name = tr(displaced_definition.display_name)
		GameState.notify_pickup(
			tr("PICKUP_SIDEARM_SWAP_FORMAT") % [selected_name, displaced_name],
			&"weapon"
		)
		return true

	match weapon_id:
		&"p01":
			GameState.notify_pickup(tr("PICKUP_P01_ACTIVE"), &"weapon")
		&"p07":
			GameState.notify_pickup(tr("PICKUP_P07_ACTIVE"), &"weapon")
		&"p14":
			GameState.notify_pickup(tr("PICKUP_P14_ACTIVE"), &"weapon")
		&"p20":
			GameState.notify_pickup(tr("PICKUP_P20_ACTIVE"), &"weapon")
		&"sg04", &"sg09":
			GameState.notify_pickup(tr("PICKUP_SHOTGUN_ACTIVE"), &"weapon")
	return true


func _get_weapon_drop_position(source_pickup: Node3D) -> Vector3:
	if source_pickup != null and is_instance_valid(source_pickup):
		return source_pickup.global_position
	return global_position

func _spawn_dropped_weapon_pickup(
	weapon_id: StringName,
	drop_position: Vector3
) -> void:
	if not is_inside_tree():
		return
	var definition := weapon_controller.call(
		"get_weapon_definition",
		weapon_id
	) as WeaponDefinition
	if definition == null or definition.world_pickup_texture == null:
		push_warning("Yere bırakılan silah için pickup görseli eksik: %s" % str(weapon_id))
		return
	var scene_root := get_tree().current_scene
	if scene_root == null:
		return
	var pickup := DROPPED_WEAPON_PICKUP_SCENE.instantiate() as VexPickup
	if pickup == null:
		return
	pickup.name = "Dropped_%s" % str(weapon_id).to_upper()
	pickup.pickup_id = StringName(
		"runtime_drop_%s_%d" % [str(weapon_id), Time.get_ticks_msec()]
	)
	pickup.pickup_type = str(weapon_id)
	pickup.amount = 0
	pickup.display_name = definition.display_name
	pickup.persist_collection = false
	pickup.scale_amount_with_difficulty = false
	pickup.visual_texture = definition.world_pickup_texture
	scene_root.add_child(pickup)
	pickup.global_position = drop_position
	pickup.block_pickup_for(0.5)

func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if is_dead or amount <= 0:
		return
	var absorbed := mini(armor, int(round(float(amount) * armor_absorption_ratio)))
	armor -= absorbed
	var health_damage := amount - absorbed
	health = maxi(0, health - health_damage)
	GameState.report_damage(health_damage)

	# Oyuncu gerçekten can kaybettiğinde hurt sesi çal.
	# Sürekli hasarda sesin üst üste binmesini engellemek için 0.9 sn cooldown.
	if (
		health_damage > 0
		and _hurt_audio_cooldown_remaining <= 0.0
		and hurt_audio.stream != null
	):
		if hurt_audio.playing:
			hurt_audio.stop()
		hurt_audio.play()
		_hurt_audio_cooldown_remaining = hurt_audio_cooldown

	broadcast_state()
	if health <= 0:
		_die()


func has_key(key_id: StringName) -> bool:
	return keys.has(key_id)


func get_view_camera() -> Camera3D:
	return camera


func get_weapon_spread_multiplier() -> float:
	return ads_spread_multiplier if is_aiming else 1.0


func get_weapon_recoil_multiplier() -> float:
	return ads_recoil_multiplier if is_aiming else 1.0


func apply_weapon_recoil(
	vertical_degrees: float,
	horizontal_degrees: float,
	max_vertical_degrees: float,
	max_horizontal_degrees: float,
	recovery_degrees_per_second: float
) -> void:
	if is_dead:
		return
	_recoil_pitch_degrees = clampf(
		_recoil_pitch_degrees + maxf(0.0, vertical_degrees),
		0.0,
		maxf(0.0, max_vertical_degrees)
	)
	_recoil_yaw_degrees = clampf(
		_recoil_yaw_degrees + horizontal_degrees,
		-maxf(0.0, max_horizontal_degrees),
		maxf(0.0, max_horizontal_degrees)
	)
	_recoil_recovery_degrees_per_second = maxf(0.1, recovery_degrees_per_second)
	_apply_view_rotation()
	_publish_recoil_to_hud()


func clear_weapon_recoil() -> void:
	_recoil_pitch_degrees = 0.0
	_recoil_yaw_degrees = 0.0
	_apply_view_rotation()
	_publish_recoil_to_hud()


func _update_recoil(delta: float) -> void:
	_recoil_pitch_degrees = move_toward(
		_recoil_pitch_degrees,
		0.0,
		_recoil_recovery_degrees_per_second * delta
	)
	_recoil_yaw_degrees = move_toward(
		_recoil_yaw_degrees,
		0.0,
		_recoil_recovery_degrees_per_second * recoil_yaw_recovery_multiplier * delta
	)
	_apply_view_rotation()
	_publish_recoil_to_hud()


func _apply_view_rotation() -> void:
	view_pivot.rotation.x = clampf(
		_pitch + deg_to_rad(_recoil_pitch_degrees),
		deg_to_rad(-pitch_limit_degrees),
		deg_to_rad(pitch_limit_degrees)
	)
	view_pivot.rotation.y = deg_to_rad(_recoil_yaw_degrees)


func _publish_recoil_to_hud() -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("set_weapon_recoil_offset"):
		var hud_recoil := (
			Vector2.ZERO
			if is_aiming
			else Vector2(_recoil_yaw_degrees, _recoil_pitch_degrees)
		)
		GameState.hud.call("set_weapon_recoil_offset", hud_recoil)


func broadcast_state() -> void:
	GameState.publish_player_stats(health, maximum_health, armor)
	GameState.publish_player_stamina(stamina, maximum_stamina, is_sprinting)
	GameState.publish_keys(keys)
	if weapon_controller != null and weapon_controller.has_method("broadcast_state"):
		weapon_controller.call("broadcast_state")


func capture_run_state() -> Dictionary:
	var weapon_state: Dictionary = weapon_controller.call("capture_state")
	return {
		"health": health,
		"armor": armor,
		"stamina": stamina,
		"keys": keys.duplicate(),
		"position": global_position,
		"rotation_y": rotation.y,
		"weapon_state": weapon_state,
		"night_vision_owned": _has_night_vision,
		"night_vision_enabled": _night_vision_enabled,
		"is_crouching": is_crouching,
	}


func restore_run_state(state: Dictionary) -> void:
	health = clampi(int(state.get("health", maximum_health)), 1, maximum_health)
	armor = clampi(int(state.get("armor", 0)), 0, maximum_armor)
	stamina = clampf(float(state.get("stamina", maximum_stamina)), 0.0, maximum_stamina)
	is_sprinting = false
	_stamina_recovery_delay_remaining = 0.0
	_set_crouching(bool(state.get("is_crouching", false)))
	keys.clear()
	var stored_keys: Array = state.get("keys", []) as Array
	for stored_key: Variant in stored_keys:
		keys.append(StringName(str(stored_key)))
	if state.has("position"):
		global_position = state["position"] as Vector3
	rotation.y = float(state.get("rotation_y", rotation.y))
	var weapon_state: Dictionary = state.get("weapon_state", {}) as Dictionary
	weapon_controller.call("restore_state", weapon_state)
	_has_night_vision = bool(state.get("night_vision_owned", false))
	_set_night_vision_enabled(
		bool(state.get("night_vision_enabled", false)),
		false
	)
	broadcast_state()


func _setup_night_vision_overlay() -> void:
	if _night_vision_layer != null and is_instance_valid(_night_vision_layer):
		return

	_night_vision_layer = CanvasLayer.new()
	_night_vision_layer.name = "NightVisionLayer"

	# HUD layer 0'da kalır. -1 layer, efekti 3D dünya görüntüsüne uygular
	# fakat HUD/harita/menü yazılarını yeşile boyamaz.
	_night_vision_layer.layer = night_vision_canvas_layer
	add_child(_night_vision_layer)

	_night_vision_rect = ColorRect.new()
	_night_vision_rect.name = "NightVisionScreenEffect"
	_night_vision_layer.add_child(_night_vision_rect)
	_night_vision_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_vision_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_vision_rect.color = Color.WHITE
	_night_vision_rect.visible = false

	if night_vision_shader != null:
		var material := ShaderMaterial.new()
		material.shader = night_vision_shader
		_night_vision_rect.material = material
	else:
		# Shader bulunamazsa tamamen bozulmak yerine basit yeşil filtre kalır.
		_night_vision_rect.color = night_vision_fallback_color


func _set_night_vision_enabled(enabled: bool, show_message := true) -> void:
	if enabled and not _has_night_vision:
		enabled = false

	_night_vision_enabled = enabled

	if _night_vision_rect != null and is_instance_valid(_night_vision_rect):
		_night_vision_rect.visible = enabled

	if show_message:
		GameState.notify(
			tr("NIGHT_VISION_ACTIVE")
			if enabled
			else tr("NIGHT_VISION_INACTIVE")
		)


func _update_controller_look(delta: float) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		return
	var device: int = pads[0]
	var look := Vector2(Input.get_joy_axis(device, JOY_AXIS_RIGHT_X), Input.get_joy_axis(device, JOY_AXIS_RIGHT_Y))
	if look.length() < 0.16:
		return
	var sensitivity := SettingsManager.controller_look_sensitivity * delta
	rotate_y(-look.x * sensitivity)
	_pitch = clampf(_pitch - look.y * sensitivity, deg_to_rad(-pitch_limit_degrees), deg_to_rad(pitch_limit_degrees))
	_apply_view_rotation()


func _update_view_bob(delta: float, movement_amount: float, movement_speed: float) -> void:
	_footstep_remaining = maxf(0.0, _footstep_remaining - delta)
	if is_on_floor() and movement_amount > bob_activation_threshold:
		_bob_time += delta * movement_speed * bob_speed_multiplier
		var bob_offset := Vector3.ZERO
		if SettingsManager.head_bob:
			bob_offset = Vector3(
				cos(_bob_time * bob_horizontal_frequency_multiplier) * bob_horizontal_amplitude,
				sin(_bob_time) * bob_vertical_amplitude,
				0.0
			)
		camera.position = camera.position.lerp(
			_camera_rest_position + bob_offset,
			delta * bob_lerp_speed
		)
		if footstep_audio.stream != null and _footstep_remaining <= 0.0:
			footstep_audio.pitch_scale = randf_range(footstep_pitch_min, footstep_pitch_max)
			footstep_audio.play()
			_footstep_remaining = (
				sprint_footstep_interval
				if movement_speed > walk_speed + sprint_detection_margin
				else walk_footstep_interval
			)
			var footstep_loudness := 0.18 if is_crouching else (0.95 if is_sprinting else 0.45)
			GameState.emit_noise(global_position, footstep_loudness, self)
	else:
		camera.position = camera.position.lerp(
			_camera_rest_position,
			delta * bob_return_lerp_speed
		)


func _update_stamina(delta: float) -> void:
	if is_sprinting:
		stamina = maxf(0.0, stamina - sprint_stamina_drain_per_second * delta)
		_stamina_recovery_delay_remaining = stamina_recovery_delay
		if stamina <= 0.0:
			is_sprinting = false
		GameState.publish_player_stamina(stamina, maximum_stamina, is_sprinting)
		return

	_stamina_recovery_delay_remaining = maxf(
		0.0,
		_stamina_recovery_delay_remaining - delta
	)
	if _stamina_recovery_delay_remaining <= 0.0:
		stamina = minf(
			maximum_stamina,
			stamina + stamina_recovery_per_second * delta
		)
	GameState.publish_player_stamina(stamina, maximum_stamina, is_sprinting)


func _setup_crouch_dimensions() -> void:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		push_error("Player için CapsuleShape3D gerekli; çömelme devre dışı bırakıldı.")
		return
	_standing_capsule_height = capsule.height
	_standing_collision_shape_y = collision_shape.position.y
	_standing_view_pivot_height = view_pivot.position.y
	crouch_capsule_height = clampf(
		crouch_capsule_height,
		capsule.radius * 2.0,
		_standing_capsule_height
	)


func _set_crouching(value: bool) -> void:
	if value == is_crouching:
		return
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null or _standing_capsule_height <= 0.0:
		return
	is_crouching = value
	var target_height := crouch_capsule_height if is_crouching else _standing_capsule_height
	capsule.height = target_height
	collision_shape.position.y = _standing_collision_shape_y - (
		(_standing_capsule_height - target_height) * 0.5
	)


func _can_stand_up() -> bool:
	if _standing_capsule_height <= 0.0:
		return true
	var current_capsule := collision_shape.shape as CapsuleShape3D
	if current_capsule == null:
		return true

	# Tam ayakta kapsülü taramak zemini de çakışma olarak görebilir. Yalnızca
	# çömelmiş kapsülün üstüne eklenecek baş/omuz hacmini kontrol ediyoruz.
	var added_height := _standing_capsule_height - crouch_capsule_height
	if added_height <= 0.0:
		return true
	var clearance_shape := BoxShape3D.new()
	clearance_shape.size = Vector3(
		current_capsule.radius * 2.0,
		added_height,
		current_capsule.radius * 2.0
	)
	var crouch_center_y := _standing_collision_shape_y - (added_height * 0.5)
	var crouch_top_y := crouch_center_y + (crouch_capsule_height * 0.5)
	var stand_top_y := _standing_collision_shape_y + (_standing_capsule_height * 0.5)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = clearance_shape
	query.transform = global_transform * Transform3D(
		Basis.IDENTITY,
		Vector3(0.0, (crouch_top_y + stand_top_y) * 0.5, 0.0)
	)
	query.collision_mask = collision_mask
	query.collide_with_areas = false
	query.exclude = [get_rid()]
	query.margin = stand_clearance_margin
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()


func _update_crouch_view(delta: float) -> void:
	if _standing_view_pivot_height <= 0.0:
		return
	var target_height := (
		crouch_view_pivot_height
		if is_crouching
		else _standing_view_pivot_height
	)
	view_pivot.position.y = move_toward(
		view_pivot.position.y,
		target_height,
		crouch_transition_speed * delta
	)


func _update_aiming(delta: float) -> void:
	_default_fov = SettingsManager.field_of_view
	var current_weapon: WeaponDefinition = null
	if weapon_controller != null and weapon_controller.has_method("get_current_weapon"):
		current_weapon = weapon_controller.call("get_current_weapon") as WeaponDefinition
	var supports_ads := current_weapon != null and current_weapon.supports_ads_pose
	is_aiming = supports_ads and Input.is_action_pressed("aim")
	var target_fov := _default_fov
	if is_aiming:
		target_fov = clampf(
			_default_fov * current_weapon.ads_fov_multiplier,
			30.0,
			_default_fov
		)
	camera.fov = move_toward(camera.fov, target_fov, ads_transition_speed * delta)


func _resolve_interactable(collider: Object) -> Node:
	if collider is Node and collider.has_method("interact"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("interact"):
			return parent
	return null


func _die() -> void:
	is_dead = true
	_set_night_vision_enabled(false, false)
	velocity = Vector3.ZERO
	clear_weapon_recoil()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	weapon_controller.set_process(false)
	GameState.report_player_death()
