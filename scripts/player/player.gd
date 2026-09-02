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
@export_range(1, 500, 1) var maximum_health := 100
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
var _gravity := 20.0
var _movement_runtime := VexPlayerMovementRuntime.new()
var _view_runtime := VexPlayerViewRuntime.new()
var _survivability_runtime := VexPlayerSurvivabilityRuntime.new()
var _interaction_runtime := VexPlayerInteractionRuntime.new()
var _pickup_runtime := VexPlayerPickupRuntime.new()
var _impact_feedback_runtime := VexPlayerImpactFeedbackRuntime.new()
var _standing_capsule_height := 0.0
var _standing_collision_shape_y := 0.0
var _standing_view_pivot_height := 0.0
var _default_fov := 78.0

var _has_night_vision := false
var _night_vision_enabled := false
var _night_vision_layer: CanvasLayer = null
var _night_vision_rect: ColorRect = null

var _impact_shock_layer: CanvasLayer = null
var _impact_shock_rect: ColorRect = null
var _impact_shock_tween: Tween = null


func _ready() -> void:
	add_to_group("player")
	_view_runtime.initialize(camera.position)
	_view_runtime.configure_bob(
		bob_activation_threshold,
		bob_speed_multiplier,
		bob_horizontal_frequency_multiplier,
		bob_horizontal_amplitude,
		bob_vertical_amplitude,
		bob_lerp_speed,
		bob_return_lerp_speed,
		footstep_pitch_min,
		footstep_pitch_max,
		sprint_footstep_interval,
		walk_footstep_interval,
		walk_speed,
		sprint_detection_margin
	)
	_default_fov = SettingsManager.field_of_view
	camera.fov = _default_fov
	_setup_crouch_dimensions()
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	_survivability_runtime.initialize(
		maximum_health,
		maximum_armor,
		initial_armor,
		armor_absorption_ratio,
		hurt_audio_cooldown
	)
	_sync_survivability_state()
	_pickup_runtime.initialize(keys, _has_night_vision)
	stamina = maximum_stamina
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameState.register_player(self)
	_setup_night_vision_overlay()


func _physics_process(delta: float) -> void:
	_survivability_runtime.update(delta)
	_update_impact_camera_shake(delta)
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
	is_sprinting = _movement_runtime.wants_to_sprint(
		Input.is_action_pressed("sprint"),
		input_vector.length(),
		stamina,
		is_on_floor(),
		is_crouching,
		is_aiming,
		sprint_input_threshold
	)
	_update_stamina(delta)
	var target_speed := (
		crouch_speed
		if is_crouching
		else (sprint_speed if is_sprinting else walk_speed)
	)
	var target_velocity := world_direction * target_speed
	var rate := acceleration if world_direction != Vector3.ZERO else deceleration
	velocity = _movement_runtime.update_horizontal_velocity(
		velocity,
		target_velocity,
		rate,
		delta
	)
	var stepped_up := false
	if is_on_floor() and not _movement_runtime.has_jump_request() and not is_crouching:
		stepped_up = _try_step_up(Vector3(velocity.x, 0.0, velocity.z) * delta)
	velocity.y = _movement_runtime.resolve_vertical_velocity(
		velocity.y,
		is_on_floor(),
		jump_velocity,
		_gravity,
		floor_stick_velocity,
		delta
	)
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
		rotate_y(
			_view_runtime.apply_mouse_look(
				mouse_event.relative,
				SettingsManager.mouse_sensitivity,
				pitch_limit_degrees
			)
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
	_movement_runtime.queue_jump(stamina_recovery_delay)

func try_interact() -> void:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return
	_interaction_runtime.try_interact(interaction_ray.get_collider(), self)


func get_interaction_prompt() -> String:
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return ""
	return _interaction_runtime.get_interaction_prompt(
		interaction_ray.get_collider(),
		self
	)


func collect_pickup(
	pickup_type: StringName,
	amount: int,
	source_pickup: Node3D = null
) -> bool:
	_sync_pickup_runtime_from_public()
	_sync_survivability_runtime_from_public()
	var result := _pickup_runtime.collect_pickup(
		pickup_type,
		amount,
		_survivability_runtime,
		weapon_controller
	)
	_sync_pickup_state()
	_sync_survivability_state()
	if not bool(result.get("success", false)):
		return false
	_apply_pickup_feedback(result, source_pickup)
	broadcast_state()
	return true


func _apply_pickup_feedback(result: Dictionary, source_pickup: Node3D) -> void:
	var kind := StringName(str(result.get("kind", "")))
	var pickup_type := StringName(str(result.get("pickup_type", "")))
	var collected_amount := int(result.get("collected_amount", 0))
	match kind:
		&"health":
			GameState.notify_pickup(tr("PICKUP_HEALTH_FORMAT") % collected_amount, &"health")
		&"armor":
			GameState.notify_pickup(tr("PICKUP_ARMOR_FORMAT") % collected_amount, &"armor")
		&"ammo":
			GameState.notify_pickup(
				tr("PICKUP_AMMO_FORMAT") % [_ammo_display_name(pickup_type), collected_amount],
				&"ammo"
			)
		&"world_weapon":
			_apply_world_weapon_pickup_feedback(result, source_pickup)
		&"direct_weapon":
			if pickup_type == &"vx47":
				GameState.notify_pickup(tr("PICKUP_RIFLE_ACTIVE"), &"weapon")
			elif pickup_type == &"mp90":
				GameState.notify_pickup(tr("PICKUP_MP90_ACTIVE"), &"weapon")
		&"equipment":
			_set_night_vision_enabled(false, false)
			GameState.notify_pickup(tr("PICKUP_NIGHT_VISION"), &"equipment")
		&"key":
			GameState.publish_keys(keys)
			match StringName(str(result.get("key_id", ""))):
				&"blue":
					GameState.notify_pickup(tr("KEY_BLUE"), &"key")
				&"red":
					GameState.notify_pickup(tr("KEY_RED"), &"key")
				&"yellow":
					GameState.notify_pickup(tr("KEY_YELLOW"), &"key")


func _ammo_display_name(ammo_type: StringName) -> String:
	match ammo_type:
		&"shells":
			return tr("AMMO_12GA")
		&"rifle_ammo":
			return tr("AMMO_762")
		&"mp90_ammo":
			return tr("AMMO_57")
	return tr("AMMO_9X19")


func _apply_world_weapon_pickup_feedback(
	result: Dictionary,
	source_pickup: Node3D
) -> void:
	var weapon_id := StringName(str(result.get("weapon_id", "")))
	var displaced_weapon_id := StringName(str(result.get("displaced_weapon_id", "")))
	var selected_definition := weapon_controller.call(
		"get_weapon_definition",
		weapon_id
	) as WeaponDefinition
	var selected_name := str(weapon_id)
	if selected_definition != null:
		selected_name = tr(selected_definition.display_name)

	if displaced_weapon_id != &"":
		call_deferred(
			"_spawn_dropped_weapon_pickup",
			displaced_weapon_id,
			_get_weapon_drop_position(source_pickup)
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
		return

	match weapon_id:
		&"p01":
			GameState.notify_pickup(tr("PICKUP_P01_ACTIVE"), &"weapon")
		&"p07":
			GameState.notify_pickup(tr("PICKUP_P07_ACTIVE"), &"weapon")
		&"p14":
			GameState.notify_pickup(tr("PICKUP_P14_ACTIVE"), &"weapon")
		&"p20":
			GameState.notify_pickup(tr("PICKUP_P20_ACTIVE"), &"weapon")
		&"sg04", &"sg09", &"sg15":
			GameState.notify_pickup(tr("PICKUP_SHOTGUN_ACTIVE"), &"weapon")


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
	_sync_survivability_runtime_from_public()
	var damage_result := _survivability_runtime.apply_damage(
		amount,
		hurt_audio.stream != null
	)
	if not bool(damage_result.get("applied", false)):
		return
	_sync_survivability_state()
	var health_damage := int(damage_result.get("health_damage", 0))
	GameState.report_damage(health_damage)

	if bool(damage_result.get("play_hurt_feedback", false)):
		if hurt_audio.playing:
			hurt_audio.stop()
		hurt_audio.play()

	broadcast_state()
	if bool(damage_result.get("died", false)):
		_die()


func apply_external_impulse(
	direction: Vector3,
	horizontal_speed: float,
	upward_speed: float,
	duration: float
) -> void:
	if is_dead:
		return
	if _movement_runtime.apply_external_impulse(
		direction,
		horizontal_speed,
		upward_speed,
		duration
	):
		is_sprinting = false


func request_camera_shake(strength: float, duration: float) -> void:
	if is_dead or not SettingsManager.screen_shake:
		return
	_impact_feedback_runtime.request_camera_shake(
		strength,
		duration,
		Vector2(camera.h_offset, camera.v_offset)
	)

func request_impact_shock(tint: Color, peak_alpha: float, duration: float) -> void:
	if not is_inside_tree():
		return
	var shock_plan := _impact_feedback_runtime.begin_impact_shock(peak_alpha, duration)
	if not bool(shock_plan.get("accepted", false)):
		return
	_ensure_impact_shock_overlay()
	if _impact_shock_rect == null:
		return
	if _impact_shock_tween != null and _impact_shock_tween.is_valid():
		_impact_shock_tween.kill()

	var shock_generation := int(shock_plan.get("generation", 0))
	var safe_peak_alpha := float(shock_plan.get("peak_alpha", 0.0))
	var rise_duration := float(shock_plan.get("rise_duration", 0.0))
	var fade_duration := float(shock_plan.get("fade_duration", 0.0))
	_impact_shock_rect.color = Color(tint.r, tint.g, tint.b, 1.0)
	_impact_shock_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_impact_shock_rect.visible = true

	# Tek bir koyu darbe darbesi kullanılır: parlak flaş veya tekrarlayan titreşim yoktur.
	_impact_shock_tween = create_tween()
	_impact_shock_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_impact_shock_tween.tween_property(
		_impact_shock_rect,
		"modulate:a",
		safe_peak_alpha,
		rise_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_impact_shock_tween.tween_property(
		_impact_shock_rect,
		"modulate:a",
		0.0,
		fade_duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_impact_shock_tween.finished.connect(
		_finish_impact_shock.bind(shock_generation),
		CONNECT_ONE_SHOT
	)

func _ensure_impact_shock_overlay() -> void:
	if (
		_impact_shock_layer != null
		and is_instance_valid(_impact_shock_layer)
		and _impact_shock_rect != null
		and is_instance_valid(_impact_shock_rect)
	):
		return
	_impact_shock_layer = CanvasLayer.new()
	_impact_shock_layer.name = "ImpactShockOverlay"
	_impact_shock_layer.layer = 120
	_impact_shock_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_impact_shock_layer)

	_impact_shock_rect = ColorRect.new()
	_impact_shock_rect.name = "ImpactShockTint"
	_impact_shock_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_impact_shock_layer.add_child(_impact_shock_rect)
	_impact_shock_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_impact_shock_rect.visible = false


func _finish_impact_shock(shock_generation: int) -> void:
	if not _impact_feedback_runtime.is_impact_shock_generation_current(shock_generation):
		return
	if _impact_shock_rect != null and is_instance_valid(_impact_shock_rect):
		_impact_shock_rect.modulate = Color(1.0, 1.0, 1.0, 0.0)
		_impact_shock_rect.visible = false
	_impact_shock_tween = null

func _update_impact_camera_shake(delta: float) -> void:
	var shake_result := _impact_feedback_runtime.update_camera_shake(
		delta,
		SettingsManager.screen_shake
	)
	if not bool(shake_result.get("apply_offset", false)):
		return
	var camera_offset := shake_result.get(
		"camera_offset",
		Vector2(camera.h_offset, camera.v_offset)
	) as Vector2
	camera.h_offset = camera_offset.x
	camera.v_offset = camera_offset.y

func _clear_impact_camera_shake() -> void:
	var clear_result := _impact_feedback_runtime.clear_camera_shake()
	if not bool(clear_result.get("apply_offset", false)):
		return
	if camera != null and is_instance_valid(camera):
		var camera_offset := clear_result.get(
			"camera_offset",
			Vector2(camera.h_offset, camera.v_offset)
		) as Vector2
		camera.h_offset = camera_offset.x
		camera.v_offset = camera_offset.y

func has_key(key_id: StringName) -> bool:
	_sync_pickup_runtime_from_public()
	return _pickup_runtime.has_key(key_id)


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
	_view_runtime.apply_recoil(
		vertical_degrees,
		horizontal_degrees,
		max_vertical_degrees,
		max_horizontal_degrees,
		recovery_degrees_per_second
	)
	_apply_view_rotation()
	_publish_recoil_to_hud()


func clear_weapon_recoil() -> void:
	_view_runtime.clear_recoil()
	_apply_view_rotation()
	_publish_recoil_to_hud()


func _update_recoil(delta: float) -> void:
	_view_runtime.update_recoil(delta, recoil_yaw_recovery_multiplier)
	_apply_view_rotation()
	_publish_recoil_to_hud()


func _apply_view_rotation() -> void:
	var view_rotation := _view_runtime.get_view_rotation(pitch_limit_degrees)
	view_pivot.rotation.x = view_rotation.x
	view_pivot.rotation.y = view_rotation.y


func _publish_recoil_to_hud() -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("set_weapon_recoil_offset"):
		GameState.hud.call(
			"set_weapon_recoil_offset",
			_view_runtime.get_hud_recoil(is_aiming)
		)


func _sync_pickup_runtime_from_public() -> void:
	_pickup_runtime.sync_state(keys, _has_night_vision)


func _sync_pickup_state() -> void:
	keys = _pickup_runtime.get_keys()
	_has_night_vision = _pickup_runtime.owns_night_vision()


func _sync_survivability_runtime_from_public() -> void:
	_survivability_runtime.sync_state(health, armor, is_dead)


func _sync_survivability_state() -> void:
	health = _survivability_runtime.get_health()
	armor = _survivability_runtime.get_armor()
	is_dead = _survivability_runtime.get_is_dead()


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
	_survivability_runtime.restore_state(
		int(state.get("health", maximum_health)),
		int(state.get("armor", 0))
	)
	_sync_survivability_state()
	stamina = clampf(float(state.get("stamina", maximum_stamina)), 0.0, maximum_stamina)
	is_sprinting = false
	_movement_runtime.reset_stamina_recovery_delay()
	_set_crouching(bool(state.get("is_crouching", false)))
	var stored_keys: Array = state.get("keys", []) as Array
	_pickup_runtime.restore_state(
		stored_keys,
		bool(state.get("night_vision_owned", false))
	)
	_sync_pickup_state()
	if state.has("position"):
		global_position = state["position"] as Vector3
	rotation.y = float(state.get("rotation_y", rotation.y))
	var weapon_state: Dictionary = state.get("weapon_state", {}) as Dictionary
	weapon_controller.call("restore_state", weapon_state)
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
	rotate_y(
		_view_runtime.apply_controller_look(
			look,
			SettingsManager.controller_look_sensitivity,
			delta,
			pitch_limit_degrees
		)
	)
	_apply_view_rotation()


func _update_view_bob(delta: float, movement_amount: float, movement_speed: float) -> void:
	var bob_result := _view_runtime.update_view_bob(
		delta,
		camera.position,
		is_on_floor(),
		movement_amount,
		movement_speed,
		SettingsManager.head_bob,
		footstep_audio.stream != null,
		is_crouching,
		is_sprinting
	)
	camera.position = bob_result.get("camera_position", camera.position) as Vector3
	if bool(bob_result.get("play_footstep", false)):
		footstep_audio.pitch_scale = float(bob_result.get("footstep_pitch", 1.0))
		footstep_audio.play()
		GameState.emit_noise(
			global_position,
			float(bob_result.get("footstep_loudness", 0.0)),
			self
		)


func _update_stamina(delta: float) -> void:
	var stamina_result := _movement_runtime.update_stamina(
		delta,
		stamina,
		is_sprinting,
		maximum_stamina,
		sprint_stamina_drain_per_second,
		stamina_recovery_per_second,
		stamina_recovery_delay
	)
	stamina = float(stamina_result.get("stamina", stamina))
	is_sprinting = bool(stamina_result.get("is_sprinting", is_sprinting))
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
	var ads_fov_multiplier := 1.0
	if supports_ads:
		ads_fov_multiplier = current_weapon.ads_fov_multiplier
	var aiming_result := _view_runtime.update_aiming(
		camera.fov,
		_default_fov,
		ads_transition_speed,
		delta,
		Input.is_action_pressed("aim"),
		supports_ads,
		ads_fov_multiplier
	)
	is_aiming = bool(aiming_result.get("is_aiming", false))
	camera.fov = float(aiming_result.get("camera_fov", camera.fov))

func _die() -> void:
	_survivability_runtime.force_dead()
	_sync_survivability_state()
	_set_night_vision_enabled(false, false)
	velocity = Vector3.ZERO
	clear_weapon_recoil()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	weapon_controller.set_process(false)
	GameState.report_player_death()
