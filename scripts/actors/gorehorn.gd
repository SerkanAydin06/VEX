class_name VexGorehorn
extends "res://scripts/actors/enemy_lunge_base.gd"

# Gorehorn standart yakın dövüş hareket/algılama omurgasını kullanır; saldırı
# sırasında oyuncunun o anki konumuna kilitlenen düz hatlı özel bir şarj uygular.
# Tüm karakter ayarları gorehorn.tscn Inspector verisidir.

@onready var charge_impact_audio: AudioStreamPlayer3D = (
	get_node_or_null("ChargeImpactAudio") as AudioStreamPlayer3D
)

var _charge_active := false
var _charge_direction := Vector3.ZERO
var _charge_hit_player := false
var _charge_blocked := false


func get_behavior_family() -> StringName:
	return &"charge"


func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	if Engine.is_editor_hint() or _dead or not _charge_active:
		return
	_resolve_charge_contact()


func _attempt_attack() -> void:
	if _attack_locked or _dead:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _horizontal_distance(global_position, _player.global_position) > attack_range:
		return
	if not _check_line_of_sight():
		return
	var settings := _get_charge_settings()
	if settings == null:
		push_warning("Gorehorn charge settings eksik; saldırı başlatılmadı.")
		return

	_attack_generation += 1
	var attack_generation := _attack_generation
	_attack_locked = true
	_charge_active = false
	_charge_hit_player = false
	_charge_blocked = false
	_attack_lunge_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_face_player()
	_play_animation(&"attack")
	if attack_audio.stream != null:
		attack_audio.play()

	# Hazırlık oyuncuya şarjı okuyabileceği kısa bir pencere verir. Şarj yönü
	# bu pencerenin sonunda bir kez kilitlenir; Gorehorn koşu sırasında dönmez.
	await get_tree().create_timer(_runtime_attack_windup).timeout
	if not _is_current_charge_attack(attack_generation):
		return
	_charge_direction = _player.global_position - global_position
	_charge_direction.y = 0.0
	if _charge_direction.length_squared() <= 0.001:
		_charge_direction = _facing_direction
	if _charge_direction.length_squared() <= 0.001:
		_charge_direction = Vector3.FORWARD
	_charge_direction = _charge_direction.normalized()
	_facing_direction = _charge_direction
	rotation.y = atan2(-_charge_direction.x, -_charge_direction.z)
	_attack_lunge_remaining = attack_lunge_duration
	_charge_active = true

	var charge_started_msec := Time.get_ticks_msec()
	while _is_current_charge_attack(attack_generation) and _charge_active:
		var elapsed := float(Time.get_ticks_msec() - charge_started_msec) / 1000.0
		if elapsed >= attack_lunge_duration:
			break
		await get_tree().physics_frame
	_stop_charge_motion(false)
	if not _is_current_charge_attack(attack_generation):
		return
	# Şarj koşusu biter bitmez nötr poza dön; sersemleme ve cooldown saldırının
	# son karesini ekranda dondurmamalıdır.
	_play_animation(&"idle")

	var recovery := (
		settings.blocked_recovery_duration
		if _charge_blocked
		else settings.recovery_duration
	)
	await get_tree().create_timer(recovery).timeout
	if not _is_current_charge_attack(attack_generation):
		return
	var remaining_cooldown := maxf(
		0.0,
		_runtime_attack_cooldown
		- _runtime_attack_windup
		- attack_lunge_duration
		- recovery
	)
	if remaining_cooldown > 0.0:
		await get_tree().create_timer(remaining_cooldown).timeout
	if not _is_current_charge_attack(attack_generation):
		return
	_attack_locked = false
	_play_animation(&"idle")


func _update_attack_lunge(delta: float) -> void:
	if not _charge_active or _attack_lunge_remaining <= 0.0:
		velocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)
		velocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)
		return
	_attack_lunge_remaining = maxf(0.0, _attack_lunge_remaining - delta)
	velocity.x = move_toward(
		velocity.x,
		_charge_direction.x * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		_charge_direction.z * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)
	if _attack_lunge_remaining <= 0.0:
		_stop_charge_motion(false)


func _resolve_charge_contact() -> void:
	var settings := _get_charge_settings()
	if settings == null:
		_stop_charge_motion(true)
		return
	if (
		_player != null
		and is_instance_valid(_player)
		and _horizontal_distance(global_position, _player.global_position)
		<= settings.hit_distance
	):
		_apply_charge_hit(settings)
		return

	for collision_index: int in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider := collision.get_collider() as Node
		if _is_player_collider(collider):
			_apply_charge_hit(settings)
			return
		var normal := collision.get_normal()
		if absf(normal.y) < wall_normal_y_threshold:
			_stop_charge_motion(true)
			return


func _apply_charge_hit(settings: VexGorehornChargeSettings) -> void:
	if _charge_hit_player or _player == null or not is_instance_valid(_player):
		return
	_charge_hit_player = true
	if _player.has_method("take_damage"):
		_player.call("take_damage", _runtime_attack_damage, _player.global_position, self)
	var push_direction := _player.global_position - global_position
	push_direction.y = 0.0
	if push_direction.length_squared() <= 0.001:
		push_direction = _charge_direction
	push_direction = push_direction.normalized()
	if _player.has_method("apply_external_impulse"):
		_player.call(
			"apply_external_impulse",
			push_direction,
			settings.knockback_horizontal_speed,
			settings.knockback_upward_speed,
			settings.knockback_duration
		)
	if settings.impact_shake_enabled and _player.has_method("request_camera_shake"):
		_player.call(
			"request_camera_shake",
			settings.impact_shake_strength,
			settings.impact_shake_duration
		)
	if settings.impact_shock_enabled and _player.has_method("request_impact_shock"):
		_player.call(
			"request_impact_shock",
			settings.impact_shock_color,
			settings.impact_shock_peak_alpha,
			settings.impact_shock_duration
		)
	if charge_impact_audio != null and charge_impact_audio.stream != null:
		charge_impact_audio.play()
	_stop_charge_motion(false)


func _stop_charge_motion(blocked: bool) -> void:
	if blocked and _charge_active:
		_charge_blocked = true
	_charge_active = false
	_attack_lunge_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0


func _is_current_charge_attack(generation: int) -> bool:
	return (
		is_inside_tree()
		and not _dead
		and generation == _attack_generation
		and _player != null
		and is_instance_valid(_player)
	)


func _get_charge_settings() -> VexGorehornChargeSettings:
	return special_ability_settings as VexGorehornChargeSettings


func _die() -> void:
	_stop_charge_motion(false)
	super._die()


func _restore_defeated_state() -> void:
	_stop_charge_motion(false)
	super._restore_defeated_state()

