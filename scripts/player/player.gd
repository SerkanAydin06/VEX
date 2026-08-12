class_name VexPlayer
extends CharacterBody3D

@export_category("Hareket")
@export_range(1.0, 12.0, 0.1) var walk_speed := 5.4
@export_range(1.0, 16.0, 0.1) var sprint_speed := 8.0
@export_range(1.0, 40.0, 0.5) var acceleration := 18.0
@export_range(1.0, 40.0, 0.5) var deceleration := 22.0
@export_category("Dayanıklılık")
@export_range(1, 500, 1) var maximum_health := 100
@export_range(0, 500, 1) var maximum_armor := 100

@onready var view_pivot: Node3D = $ViewPivot
@onready var camera: Camera3D = $ViewPivot/Camera3D
@onready var interaction_ray: RayCast3D = $ViewPivot/Camera3D/InteractionRay
@onready var weapon_controller: Node = $WeaponController
@onready var footstep_audio: AudioStreamPlayer3D = $FootstepAudio
@onready var hurt_audio: AudioStreamPlayer = $HurtAudio

var health := 100
var armor := 0
var keys: Array[StringName] = []
var is_dead := false
var _pitch := 0.0
var _bob_time := 0.0
var _camera_rest_position := Vector3.ZERO
var _gravity := 20.0
var _footstep_remaining := 0.0
var _hurt_audio_cooldown_remaining := 0.0
const HURT_AUDIO_COOLDOWN := 0.9
const NIGHT_VISION_SHADER_PATH := "res://shaders/night_vision.gdshader"

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
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
	health = maximum_health
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
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var target_velocity := world_direction * target_speed
	var rate := acceleration if world_direction != Vector3.ZERO else deceleration
	velocity.x = move_toward(velocity.x, target_velocity.x, rate * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, rate * delta)
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = -0.1
	move_and_slide()
	_update_recoil(delta)
	_update_view_bob(delta, input_vector.length(), target_speed)


func _unhandled_input(event: InputEvent) -> void:
	if is_dead or get_tree().paused:
		return

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if (
			key_event.pressed
			and not key_event.echo
			and (
				key_event.keycode == KEY_N
				or key_event.physical_keycode == KEY_N
			)
		):
			if _has_night_vision:
				get_viewport().set_input_as_handled()
				_set_night_vision_enabled(not _night_vision_enabled)
			return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_event := event as InputEventMouseMotion
		rotate_y(deg_to_rad(-mouse_event.relative.x * SettingsManager.mouse_sensitivity))
		_pitch = clampf(
			_pitch - deg_to_rad(mouse_event.relative.y * SettingsManager.mouse_sensitivity),
			deg_to_rad(-82.0),
			deg_to_rad(82.0)
		)
		_apply_view_rotation()
	elif event.is_action_pressed("interact"):
		try_interact()


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


func collect_pickup(pickup_type: StringName, amount: int) -> bool:
	match pickup_type:
		&"health":
			if health >= maximum_health:
				return false
			var collected_health := mini(amount, maximum_health - health)
			health = mini(maximum_health, health + amount)
			GameState.notify_pickup("SAĞLIK +%d" % collected_health, &"health")
		&"armor":
			if armor >= maximum_armor:
				return false
			var collected_armor := mini(amount, maximum_armor - armor)
			armor = mini(maximum_armor, armor + amount)
			GameState.notify_pickup("ZIRH +%d" % collected_armor, &"armor")
		&"bullets", &"shells", &"rifle_ammo", &"mp90_ammo":
			if not weapon_controller.call("add_ammo", pickup_type, amount):
				return false
			var ammo_name := "9×19 MERMİ"
			if pickup_type == &"shells":
				ammo_name = "12 GA FİŞEK"
			elif pickup_type == &"rifle_ammo":
				ammo_name = "7.62×39 MERMİ"
			elif pickup_type == &"mp90_ammo":
				ammo_name = "5.7×28 MERMİ"
			GameState.notify_pickup("%s +%d" % [ammo_name, amount], &"ammo")
		&"shotgun":
			weapon_controller.call("unlock_weapon", &"shotgun", amount)
			GameState.notify_pickup("KIRICI POMPALI AKTİF", &"weapon")
		&"ak47":
			weapon_controller.call("unlock_weapon", &"ak47", amount)
			GameState.notify_pickup("AK-47 AKTİF", &"weapon")
		&"mp90":
			weapon_controller.call("unlock_weapon", &"mp90", amount)
			GameState.notify_pickup("MP90 AKTİF", &"weapon")
		&"night_vision":
			if _has_night_vision:
				return false
			_has_night_vision = true
			_set_night_vision_enabled(false, false)
			GameState.notify_pickup(
				"NIGHT VISION ALINDI — N İLE AÇ/KAPAT",
				&"equipment"
			)
		&"key_blue":
			if has_key(&"blue"):
				return false
			keys.append(&"blue")
			GameState.publish_keys(keys)
			GameState.notify_pickup("MAVİ ERİŞİM ANAHTARI", &"key")
			GameState.set_objective("KIRMIZI ERİŞİM ANAHTARINI DA BUL")
		&"key_red":
			if has_key(&"red"):
				return false
			keys.append(&"red")
			GameState.publish_keys(keys)
			GameState.notify_pickup("KIRMIZI ERİŞİM ANAHTARI", &"key")
			GameState.set_objective("TAHLİYE GEÇİDİNE GERİ DÖN")
		_:
			return false
	broadcast_state()
	return true


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if is_dead or amount <= 0:
		return
	var absorbed := mini(armor, int(round(float(amount) * 0.6)))
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
		_hurt_audio_cooldown_remaining = HURT_AUDIO_COOLDOWN

	broadcast_state()
	if health <= 0:
		_die()


func has_key(key_id: StringName) -> bool:
	return keys.has(key_id)


func get_view_camera() -> Camera3D:
	return camera


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
		_recoil_recovery_degrees_per_second * 0.85 * delta
	)
	_apply_view_rotation()
	_publish_recoil_to_hud()


func _apply_view_rotation() -> void:
	view_pivot.rotation.x = clampf(
		_pitch + deg_to_rad(_recoil_pitch_degrees),
		deg_to_rad(-82.0),
		deg_to_rad(82.0)
	)
	view_pivot.rotation.y = deg_to_rad(_recoil_yaw_degrees)


func _publish_recoil_to_hud() -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("set_weapon_recoil_offset"):
		GameState.hud.call(
			"set_weapon_recoil_offset",
			Vector2(_recoil_yaw_degrees, _recoil_pitch_degrees)
		)


func broadcast_state() -> void:
	GameState.publish_player_stats(health, maximum_health, armor)
	GameState.publish_keys(keys)
	if weapon_controller != null and weapon_controller.has_method("broadcast_state"):
		weapon_controller.call("broadcast_state")


func capture_run_state() -> Dictionary:
	var weapon_state: Dictionary = weapon_controller.call("capture_state")
	return {
		"health": health,
		"armor": armor,
		"keys": keys.duplicate(),
		"position": global_position,
		"rotation_y": rotation.y,
		"weapon_state": weapon_state,
		"night_vision_owned": _has_night_vision,
		"night_vision_enabled": _night_vision_enabled,
	}


func restore_run_state(state: Dictionary) -> void:
	health = clampi(int(state.get("health", maximum_health)), 1, maximum_health)
	armor = clampi(int(state.get("armor", 0)), 0, maximum_armor)
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
	_night_vision_layer.layer = -1
	add_child(_night_vision_layer)

	_night_vision_rect = ColorRect.new()
	_night_vision_rect.name = "NightVisionScreenEffect"
	_night_vision_layer.add_child(_night_vision_rect)
	_night_vision_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_night_vision_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_night_vision_rect.color = Color.WHITE
	_night_vision_rect.visible = false

	var shader := load(NIGHT_VISION_SHADER_PATH) as Shader
	if shader != null:
		var material := ShaderMaterial.new()
		material.shader = shader
		_night_vision_rect.material = material
	else:
		# Shader bulunamazsa tamamen bozulmak yerine basit yeşil filtre kalır.
		_night_vision_rect.color = Color(0.05, 0.32, 0.08, 0.32)


func _set_night_vision_enabled(enabled: bool, show_message := true) -> void:
	if enabled and not _has_night_vision:
		enabled = false

	_night_vision_enabled = enabled

	if _night_vision_rect != null and is_instance_valid(_night_vision_rect):
		_night_vision_rect.visible = enabled

	if show_message:
		GameState.notify(
			"NIGHT VISION AKTİF"
			if enabled
			else "NIGHT VISION PASİF"
		)


func _update_view_bob(delta: float, movement_amount: float, movement_speed: float) -> void:
	_footstep_remaining = maxf(0.0, _footstep_remaining - delta)
	if is_on_floor() and movement_amount > 0.05:
		_bob_time += delta * movement_speed * 1.7
		var bob_offset := Vector3(
			cos(_bob_time * 0.5) * 0.025,
			sin(_bob_time) * 0.035,
			0.0
		)
		camera.position = camera.position.lerp(_camera_rest_position + bob_offset, delta * 12.0)
		if footstep_audio.stream != null and _footstep_remaining <= 0.0:
			footstep_audio.pitch_scale = randf_range(0.94, 1.06)
			footstep_audio.play()
			_footstep_remaining = 0.34 if movement_speed > walk_speed + 0.1 else 0.46
	else:
		camera.position = camera.position.lerp(_camera_rest_position, delta * 10.0)


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
