@tool
class_name VexRedViper
extends CharacterBody3D

const BURN_REMAINS_SCENE := preload("res://scenes/props/burn_remains.tscn")

@export_category("01 - Kimlik, Can ve Zorluk")
@export var enemy_id: StringName = &"redviper"
@export_range(1, 1000, 1) var maximum_health := 90
@export_range(0, 3, 1) var spawn_min_difficulty := 0
@export var apply_difficulty_scaling := true

@export_category("02 - Hareket ve Devriye")
@export_range(0.5, 10.0, 0.1) var move_speed := 2.35
@export_range(0.5, 16.0, 0.1) var chase_speed := 5.8
@export_range(0.5, 40.0, 0.5) var movement_acceleration := 12.0
@export_range(0.5, 40.0, 0.5) var braking_acceleration := 12.0
@export_range(0.0, 4.0, 0.05) var gravity_scale := 1.0
@export_range(-5.0, 0.0, 0.05) var floor_stick_velocity := -0.1
@export var patrol_offset := Vector3(2.0, 0.0, 0.0)
@export_range(0.0, 3.0, 0.05) var patrol_pause_duration := 0.65
@export_range(0.1, 1.5, 0.05) var patrol_reach_distance := 0.35
@export_range(0.1, 2.0, 0.05) var investigation_reach_distance := 0.55
@export_range(0.0, 3.0, 0.05) var detour_duration := 0.55

@export_category("03 - Algılama ve Takip")
@export_range(1.0, 30.0, 0.5) var detection_range := 14.0
@export_range(5.0, 40.0, 0.5) var pursuit_range := 24.0
@export_range(30.0, 360.0, 5.0) var initial_view_angle := 360.0
@export_range(1.0, 30.0, 0.5) var lost_sight_timeout := 20.0
@export_range(1.0, 20.0, 0.5) var search_duration := 10.0
@export_range(2.0, 20.0, 0.5) var ally_alert_radius := 9.0
@export_range(0.0, 3.0, 0.05) var sight_origin_height := 0.65
@export_range(0.0, 3.0, 0.05) var sight_target_height := 0.45

@export_category("04 - Saldırı")
@export_range(0.5, 4.0, 0.05) var attack_range := 1.45
@export_range(1, 100, 1) var attack_damage := 10
@export_range(0.3, 3.0, 0.05) var attack_cooldown := 1.0
@export_range(0.05, 1.0, 0.01) var attack_windup := 0.28
@export_range(0.0, 2.0, 0.05) var attack_range_tolerance := 0.45
@export_range(0.0, 16.0, 0.1) var attack_lunge_speed := 7.5
@export_range(0.0, 80.0, 0.5) var attack_lunge_acceleration := 36.0
@export_range(0.0, 1.0, 0.01) var attack_lunge_duration := 0.28
@export_range(0.2, 2.0, 0.05) var attack_lunge_stop_distance := 1.2

@export_category("05 - Görsel ve Animasyon")
@export_range(-1.0, 1.0, 0.05) var back_view_threshold := -0.15
@export_range(0.0, 2.0, 0.01) var hurt_reaction_duration := 0.12
@export var hurt_stops_movement := false
@export var hurt_flash_color := Color(1.0, 0.3, 0.25, 1.0)
@export_range(0.0, 2.0, 0.01) var hurt_flash_duration := 0.12
@export_range(-2.0, 2.0, 0.01) var corpse_visual_y := 0.4032225
@export_range(0.0, 3.0, 0.05) var death_settle_duration := 0.55
@export_range(0.0, 4.0, 0.05) var corpse_hold_duration := 2.2
@export_range(0.005, 0.1, 0.005) var corpse_floor_clearance := 0.02
@export var idle_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var idle_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var walk_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var walk_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var hurt_frame_y_offsets := PackedFloat32Array([0.0])
@export var death_frame_y_offsets := PackedFloat32Array([0.0, -0.008, -0.016, -0.024])

@export_category("07 - Ölüm Sonrası İz")
@export_range(0.4, 3.0, 0.05) var burn_remains_scale := 1.0
@export_range(0.0, 20.0, 0.1) var burn_smoke_duration := 8.5
@export_range(0.0, 1.0, 0.01) var burn_smoke_alpha := 0.14

@export_category("06 - Performans")
@export_range(0.02, 1.0, 0.01) var near_sight_interval := 0.08
@export_range(0.05, 1.0, 0.01) var far_sight_interval := 0.20
@export_range(12.0, 80.0, 1.0) var dormant_distance := 28.0

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

var health := 90
var _spawn_position := Vector3.ZERO
var _patrol_forward := true
var _wait_remaining := 0.0
var _gravity := 20.0
var _dead := false
var _hurt_tween: Tween = null
var _player: Node3D = null
var _attack_locked := false
var _hurt_anim_locked := false
var _aggro := false
var _lost_sight_remaining := 0.0
var _search_remaining := 0.0
var _last_seen_position := Vector3.ZERO
var _facing_direction := Vector3.FORWARD
var _detour_direction := Vector3.ZERO
var _detour_remaining := 0.0
var _movement_target := Vector3.ZERO
var _attack_generation := 0
var _attack_lunge_remaining := 0.0
var _base_sprite_modulate := Color.WHITE
var _runtime_maximum_health := 1
var _runtime_move_speed := 0.5
var _runtime_chase_speed := 0.5
var _runtime_detection_range := 1.0
var _runtime_pursuit_range := 1.0
var _runtime_attack_damage := 1
var _runtime_attack_cooldown := 1.0
var _runtime_attack_windup := 0.1
var _runtime_attack_lunge_speed := 0.0
var _sight_check_remaining := 0.0
var _cached_player_visible := false
var _dormant_active := false
var _burn_remains: Node3D = null
var _visual_base_y := 0.0


func _ready() -> void:
	_base_sprite_modulate = animated_sprite.modulate
	_visual_base_y = animated_sprite.position.y
	if not animated_sprite.frame_changed.is_connected(_on_visual_frame_changed):
		animated_sprite.frame_changed.connect(_on_visual_frame_changed)
	_apply_frame_ground_offset()
	# Editörde de RedViper görünsün ve idle animasyonu oynasın.
	# AI, GameState ve devriye kodları editör modunda çalıştırılmaz.
	if Engine.is_editor_hint():
		_play_animation(&"idle")
		return

	if GameState.active_difficulty < spawn_min_difficulty:
		queue_free()
		return

	add_to_group("enemy")
	add_to_group("damageable")
	_configure_runtime_stats()
	health = _runtime_maximum_health
	_spawn_position = global_position
	_player = GameState.player as Node3D
	_gravity = (
		float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
		* gravity_scale
	)
	_snap_body_to_floor(2.0)

	if GameState.was_enemy_defeated(enemy_id):
		_restore_defeated_state()
		return

	# Çok sayıdaki Viper aynı fizik karesinde görüş ışını atmasın.
	_sight_check_remaining = randf_range(0.0, near_sight_interval)
	_play_animation(&"idle")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if _dead:
		return

	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D

	if _should_use_dormant_mode():
		_enter_dormant_mode()
		_apply_dormant_physics(delta)
		return
	_exit_dormant_mode()

	_apply_gravity(delta)
	_detour_remaining = maxf(0.0, _detour_remaining - delta)
	# Saldırı hazırlığında oyuncuyu kısa bir ileri hamleyle takip et. Böylece
	# normal geri yürüyüş, başlamış her yakın dövüş saldırısını otomatik olarak
	# boşa çıkarmaz. Hızlı koşan oyuncu hâlâ menzilden kaçabilir.
	if _attack_locked:
		_update_attack_lunge(delta)
		move_and_slide()
		return

	if _hurt_anim_locked and hurt_stops_movement:
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if _player != null and is_instance_valid(_player):
		var player_distance: float = _horizontal_distance(
			global_position,
			_player.global_position
		)
		var active_sight_range: float = (
			_runtime_pursuit_range
			if _aggro
			else _runtime_detection_range
		)
		var can_see_player := _get_cached_player_visibility(
			delta,
			player_distance,
			active_sight_range
		)

		# İlk algılama ve alarm sonrası takip menzilleri sahne kökünden bağımsız
		# olarak ayarlanır.
		if can_see_player and player_distance <= active_sight_range:
			var was_aggro := _aggro
			_aggro = true
			_last_seen_position = _player.global_position
			_lost_sight_remaining = lost_sight_timeout
			_search_remaining = search_duration
			if not was_aggro:
				_alert_nearby_allies(_last_seen_position)

			if player_distance <= attack_range:
				_face_player()
				_attempt_attack()
				move_and_slide()
				return

			_chase_position(delta, _player.global_position)
			move_and_slide()
			_update_chase_detour()
			return

		# Görüş kesilince anında devriyeye dönmez; sahnedeki takip hafızası
		# süresince son görülen noktaya gitmeye devam eder.
		if _aggro and _lost_sight_remaining > 0.0:
			_lost_sight_remaining = maxf(
				0.0,
				_lost_sight_remaining - delta
			)
			if _horizontal_distance(
				global_position,
				_last_seen_position
			) > investigation_reach_distance:
				_chase_position(delta, _last_seen_position)
			else:
				velocity.x = move_toward(
					velocity.x,
					0.0,
					delta * braking_acceleration
				)
				velocity.z = move_toward(
					velocity.z,
					0.0,
					delta * braking_acceleration
				)
				_play_animation(&"idle")
			move_and_slide()
			_update_chase_detour()
			return

		# Son görülen yere ulaştıktan / takip süresi bittikten sonra sahnede
		# belirlenen süre boyunca bölgede bekler.
		if _aggro and _search_remaining > 0.0:
			_search_remaining = maxf(0.0, _search_remaining - delta)
			velocity.x = move_toward(
				velocity.x,
				0.0,
				delta * braking_acceleration
			)
			velocity.z = move_toward(
				velocity.z,
				0.0,
				delta * braking_acceleration
			)
			_face_position(_last_seen_position)
			_play_animation(&"idle")
			move_and_slide()
			return

		if _aggro:
			_aggro = false
			_cached_player_visible = false
			_sight_check_remaining = 0.0
			_lost_sight_remaining = 0.0
			_search_remaining = 0.0

	if _wait_remaining > 0.0:
		_wait_remaining = maxf(_wait_remaining - delta, 0.0)
		velocity.x = move_toward(
			velocity.x,
			0.0,
			delta * braking_acceleration
		)
		velocity.z = move_toward(
			velocity.z,
			0.0,
			delta * braking_acceleration
		)
		_play_animation(&"idle")
		move_and_slide()
		return

	var target: Vector3 = _spawn_position + (
		patrol_offset if _patrol_forward else -patrol_offset
	)
	target.y = global_position.y
	var direction: Vector3 = target - global_position
	direction.y = 0.0

	if direction.length() <= patrol_reach_distance:
		_patrol_forward = not _patrol_forward
		_wait_remaining = patrol_pause_duration
		velocity.x = 0.0
		velocity.z = 0.0
		_play_animation(&"idle")
		move_and_slide()
		return

	direction = direction.normalized()
	_facing_direction = direction
	velocity.x = move_toward(
		velocity.x,
		direction.x * _runtime_move_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * _runtime_move_speed,
		delta * movement_acceleration
	)
	rotation.y = atan2(-direction.x, -direction.z)
	_play_animation(&"walk")
	move_and_slide()

	# Sadece duvar / yatay engel çarpışmalarında yön değiştir.
	for collision_index: int in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(
			collision_index
		)
		if collision == null:
			continue
		var normal: Vector3 = collision.get_normal()
		if absf(normal.y) < 0.55:
			_patrol_forward = not _patrol_forward
			_wait_remaining = patrol_pause_duration
			velocity.x = 0.0
			velocity.z = 0.0
			break


func _chase_position(delta: float, target_position: Vector3) -> void:
	_movement_target = target_position
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		_play_animation(&"idle")
		return

	direction = direction.normalized()
	if _detour_remaining > 0.0 and _detour_direction.length_squared() > 0.001:
		direction = _detour_direction
	_facing_direction = direction
	velocity.x = move_toward(
		velocity.x,
		direction.x * _runtime_chase_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * _runtime_chase_speed,
		delta * movement_acceleration
	)
	rotation.y = atan2(-direction.x, -direction.z)
	_play_animation(&"walk")


func _update_chase_detour() -> void:
	for collision_index: int in range(get_slide_collision_count()):
		var collision := get_slide_collision(collision_index)
		if collision == null:
			continue
		var normal := collision.get_normal()
		if absf(normal.y) >= 0.55:
			continue
		normal.y = 0.0
		if normal.length_squared() <= 0.001:
			continue
		normal = normal.normalized()
		var tangent_a := Vector3(-normal.z, 0.0, normal.x)
		var tangent_b: Vector3 = -tangent_a
		var target_direction := _movement_target - global_position
		target_direction.y = 0.0
		if target_direction.length_squared() > 0.001:
			target_direction = target_direction.normalized()
		_detour_direction = (
			tangent_a
			if tangent_a.dot(target_direction) >= tangent_b.dot(target_direction)
			else tangent_b
		)
		_detour_remaining = detour_duration
		return


func _face_position(target_position: Vector3) -> void:
	var direction: Vector3 = target_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		_facing_direction = direction
		rotation.y = atan2(-direction.x, -direction.z)


func _face_player() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_face_position(_player.global_position)


func _is_player_inside_initial_view() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if initial_view_angle >= 359.9:
		return true
	var player_direction := _player.global_position - global_position
	player_direction.y = 0.0
	if player_direction.length_squared() <= 0.001:
		return true
	player_direction = player_direction.normalized()
	var view_threshold := cos(deg_to_rad(initial_view_angle * 0.5))
	return _facing_direction.dot(player_direction) >= view_threshold


func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false

	var origin: Vector3 = global_position + Vector3.UP * sight_origin_height
	var target: Vector3 = _player.global_position + Vector3.UP * sight_target_height
	var query := PhysicsRayQueryParameters3D.create(
		origin,
		target,
		collision_mask,
		[get_rid()]
	)
	var result: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	return not result.is_empty() and result.get("collider") == _player


func _get_cached_player_visibility(
	delta: float,
	player_distance: float,
	active_sight_range: float
) -> bool:
	_sight_check_remaining = maxf(_sight_check_remaining - delta, 0.0)
	if player_distance > active_sight_range:
		_cached_player_visible = false
		return false
	if _sight_check_remaining > 0.0:
		return _cached_player_visible

	_sight_check_remaining = (
		far_sight_interval
		if _aggro and player_distance > _runtime_detection_range
		else near_sight_interval
	)
	_cached_player_visible = (
		_check_line_of_sight()
		and (_aggro or _is_player_inside_initial_view())
	)
	return _cached_player_visible


func _update_attack_lunge(delta: float) -> void:
	if (
		_attack_lunge_remaining <= 0.0
		or _runtime_attack_lunge_speed <= 0.0
		or _player == null
		or not is_instance_valid(_player)
	):
		_attack_lunge_remaining = 0.0
		velocity.x = move_toward(velocity.x, 0.0, delta * braking_acceleration)
		velocity.z = move_toward(velocity.z, 0.0, delta * braking_acceleration)
		return

	_attack_lunge_remaining = maxf(0.0, _attack_lunge_remaining - delta)
	var direction := _player.global_position - global_position
	direction.y = 0.0
	var distance := direction.length()
	if distance <= attack_lunge_stop_distance or distance <= 0.001:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	_face_position(_player.global_position)
	direction /= distance
	velocity.x = move_toward(
		velocity.x,
		direction.x * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * _runtime_attack_lunge_speed,
		delta * attack_lunge_acceleration
	)


func _attempt_attack() -> void:
	if _attack_locked or _dead:
		return
	if _player == null or not is_instance_valid(_player):
		return
	if _horizontal_distance(global_position, _player.global_position) > attack_range:
		return
	if not _check_line_of_sight():
		return

	_attack_generation += 1
	var attack_generation := _attack_generation
	_attack_locked = true
	_attack_lunge_remaining = minf(
		attack_lunge_duration,
		_runtime_attack_windup
	)
	_play_animation(&"attack")
	if attack_audio.stream != null:
		attack_audio.play()

	# 8 FPS'lik 4 kare saldırının 3. karesine yaklaşırken darbe uygulanır.
	await get_tree().create_timer(_runtime_attack_windup).timeout
	if not is_inside_tree() or _dead or attack_generation != _attack_generation:
		return
	_attack_lunge_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0

	if _player != null and is_instance_valid(_player):
		var still_in_range: bool = (
			_horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight() and _player.has_method("take_damage"):
			_player.call("take_damage", _runtime_attack_damage, global_position, self)

	var remaining: float = maxf(
		0.0,
		_runtime_attack_cooldown - _runtime_attack_windup
	)
	await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or _dead or attack_generation != _attack_generation:
		return
	_attack_locked = false

	if _player != null and is_instance_valid(_player):
		if _horizontal_distance(global_position, _player.global_position) <= attack_range:
			_face_player()
			_play_animation(&"idle")
			return
	_play_animation(&"walk")


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	var difference: Vector3 = first - second
	difference.y = 0.0
	return difference.length()


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if _dead or amount <= 0:
		return

	health -= amount
	_exit_dormant_mode()
	if health <= 0:
		_die()
		return

	# Hasar almak RedViper'ı doğrudan oyuncuya karşı aggro yapar.
	# Görüş bir an kesilse bile takip hafızası hemen sıfırlanmaz.
	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D
	if _player != null and is_instance_valid(_player):
		_aggro = true
		_last_seen_position = _player.global_position
		_lost_sight_remaining = lost_sight_timeout
		_search_remaining = search_duration
		_alert_nearby_allies(_last_seen_position)

	if hurt_audio.stream != null and not hurt_audio.playing:
		hurt_audio.play()
	_flash_hurt()
	_play_hurt_feedback()


func _collision_floor_local_y() -> float:
	var capsule := collision_shape.shape as CapsuleShape3D
	if capsule == null:
		return collision_shape.position.y
	return collision_shape.position.y - capsule.height * 0.5


func _snap_body_to_floor(max_correction: float = 2.0) -> void:
	if not is_inside_tree() or collision_shape == null or collision_shape.shape == null:
		return
	var ray_origin := global_position + Vector3.UP * 0.5
	var ray_end := global_position + Vector3.DOWN * (max_correction + 2.0)
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		1,
		[get_rid()]
	)
	query.collide_with_areas = false
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return
	var target_root_y := float(hit["position"].y) - _collision_floor_local_y()
	if absf(target_root_y - global_position.y) > max_correction:
		return
	global_position.y = target_root_y
	velocity.y = floor_stick_velocity




func _on_visual_frame_changed() -> void:
	_apply_frame_ground_offset()


func _apply_frame_ground_offset() -> void:
	if animated_sprite == null:
		return
	var offsets := _frame_offsets_for_animation(animated_sprite.animation)
	var frame_offset := 0.0
	if not offsets.is_empty():
		frame_offset = offsets[mini(animated_sprite.frame, offsets.size() - 1)]
	animated_sprite.position.y = _visual_base_y + frame_offset


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	match animation_name:
		&"idle":
			return idle_frame_y_offsets
		&"idle_back":
			return idle_back_frame_y_offsets
		&"walk":
			return walk_frame_y_offsets
		&"walk_back":
			return walk_back_frame_y_offsets
		&"attack":
			return attack_frame_y_offsets
		&"hurt":
			return hurt_frame_y_offsets
		&"death":
			return death_frame_y_offsets
	return PackedFloat32Array()


func _get_animation_duration(animation_name: StringName) -> float:
	if animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if frame_count <= 0 or speed <= 0.001:
		return 0.0
	return float(frame_count) / speed



func _restore_defeated_state() -> void:
	_dead = true
	_attack_generation += 1
	_attack_locked = false
	_attack_lunge_remaining = 0.0
	_hurt_anim_locked = false
	_aggro = false
	_lost_sight_remaining = 0.0
	_search_remaining = 0.0
	velocity = Vector3.ZERO
	_snap_body_to_floor(2.0)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	_finalize_death_visual()


func _finalize_death_visual() -> void:
	animated_sprite.visible = false
	animated_sprite.pause()
	if ground_shadow != null:
		ground_shadow.visible = false
	_show_burn_remains()


func _show_burn_remains() -> void:
	if _burn_remains != null and is_instance_valid(_burn_remains):
		return
	var remains := BURN_REMAINS_SCENE.instantiate()
	remains.position = Vector3(0.0, _collision_floor_local_y(), 0.0)
	remains.set("scorch_size", burn_remains_scale)
	remains.set("smoke_enabled", false)
	remains.set("smoke_duration", burn_smoke_duration)
	remains.set("smoke_alpha", 0.0)
	remains.set("scorch_tint", Color(0.44, 0.04, 0.04, 0.95))
	remains.set("ember_tint", Color(0.70, 0.08, 0.08, 0.38))
	remains.set("ember_emission_energy", 0.14)
	if enemy_id == &"badredviper":
		remains.set("scorch_size", burn_remains_scale * 1.26)
		remains.set("scorch_tint", Color(0.40, 0.03, 0.03, 0.97))
		remains.set("ember_tint", Color(0.72, 0.08, 0.08, 0.42))
		remains.set("ember_emission_energy", 0.18)
	elif enemy_id == &"redviper":
		remains.set("ember_tint", Color(0.78, 0.10, 0.10, 0.34))
	add_child(remains)
	_burn_remains = remains


func _die() -> void:
	if _dead:
		return
	_dead = true
	_attack_generation += 1
	_attack_locked = false
	_attack_lunge_remaining = 0.0
	_hurt_anim_locked = false
	_aggro = false
	_lost_sight_remaining = 0.0
	_search_remaining = 0.0
	velocity = Vector3.ZERO
	_snap_body_to_floor(2.0)
	collision_shape.set_deferred("disabled", true)
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(2, false)
	set_collision_mask_value(4, false)
	if attack_audio.stream != null and attack_audio.playing:
		attack_audio.stop()
	if hurt_audio.stream != null and hurt_audio.playing:
		hurt_audio.stop()
	if death_audio.stream != null:
		death_audio.stop()
		death_audio.play()
	GameState.register_enemy_defeated(enemy_id)

	animated_sprite.modulate = _base_sprite_modulate
	if animated_sprite.sprite_frames != null \
	and animated_sprite.sprite_frames.has_animation(&"death") \
	and animated_sprite.sprite_frames.get_frame_count(&"death") > 0:
		_play_animation(&"death")
		var death_duration := maxf(death_settle_duration, _get_animation_duration(&"death"))
		await get_tree().create_timer(death_duration).timeout
		if not is_inside_tree():
			return
		animated_sprite.pause()
		animated_sprite.frame = animated_sprite.sprite_frames.get_frame_count(&"death") - 1
		animated_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		animated_sprite.rotation_degrees = Vector3.ZERO
		_apply_frame_ground_offset()
		await get_tree().create_timer(corpse_hold_duration).timeout
		if not is_inside_tree():
			return
	else:
		_play_animation(&"idle")
		animated_sprite.pause()
		animated_sprite.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		animated_sprite.rotation_degrees = Vector3.ZERO
		_apply_frame_ground_offset()
		await get_tree().create_timer(corpse_hold_duration).timeout
		if not is_inside_tree():
			return
	_finalize_death_visual()


func _play_hurt_feedback() -> void:
	# Başlamış saldırı hasarla kesilmez. Böylece seri atış Viper'ı saldırı
	# animasyonundan ve hamlesinden çıkararak tamamen etkisiz bırakamaz.
	if _dead or _attack_locked:
		return
	if animated_sprite.sprite_frames == null:
		return
	if not animated_sprite.sprite_frames.has_animation(&"hurt"):
		return
	if animated_sprite.sprite_frames.get_frame_count(&"hurt") <= 0:
		return
	if _hurt_anim_locked:
		return

	_hurt_anim_locked = true
	_play_animation(&"hurt")
	await get_tree().create_timer(hurt_reaction_duration).timeout
	if not is_inside_tree() or _dead:
		return
	_hurt_anim_locked = false
	if _attack_locked:
		_play_animation(&"attack")
	elif velocity.length_squared() > 0.04:
		_play_animation(&"walk")
	else:
		_play_animation(&"idle")


func _flash_hurt() -> void:
	if _hurt_tween != null and _hurt_tween.is_valid():
		_hurt_tween.kill()
	animated_sprite.modulate = hurt_flash_color
	_hurt_tween = create_tween()
	_hurt_tween.tween_property(
		animated_sprite,
		"modulate",
		_base_sprite_modulate,
		hurt_flash_duration
	)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity


func _should_use_dormant_mode() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _aggro or _attack_locked or _hurt_anim_locked:
		return false
	return (
		_horizontal_distance(global_position, _player.global_position)
		> dormant_distance
	)


func _enter_dormant_mode() -> void:
	if _dormant_active:
		return
	_dormant_active = true
	_cached_player_visible = false
	_detour_remaining = 0.0
	velocity.x = 0.0
	velocity.z = 0.0
	_play_animation(&"idle")


func _exit_dormant_mode() -> void:
	if not _dormant_active:
		return
	_dormant_active = false
	_cached_player_visible = false
	_sight_check_remaining = 0.0


func _apply_dormant_physics(delta: float) -> void:
	if is_on_floor():
		velocity.y = floor_stick_velocity
		return
	_apply_gravity(delta)
	move_and_slide()


func _configure_runtime_stats() -> void:
	_runtime_maximum_health = maximum_health
	_runtime_move_speed = move_speed
	_runtime_chase_speed = chase_speed
	_runtime_detection_range = detection_range
	_runtime_pursuit_range = pursuit_range
	_runtime_attack_damage = attack_damage
	_runtime_attack_cooldown = attack_cooldown
	_runtime_attack_windup = attack_windup
	_runtime_attack_lunge_speed = attack_lunge_speed
	if not apply_difficulty_scaling:
		return

	var profile := GameState.get_active_difficulty_profile()
	_runtime_maximum_health = maxi(
		1,
		int(round(
			float(maximum_health)
			* float(profile.get("health_multiplier", 1.0))
		))
	)
	_runtime_move_speed = clampf(
		move_speed * float(profile.get("speed_multiplier", 1.0)),
		0.5,
		10.0
	)
	_runtime_chase_speed = clampf(
		chase_speed * float(profile.get("speed_multiplier", 1.0)),
		0.5,
		16.0
	)
	_runtime_attack_lunge_speed = clampf(
		attack_lunge_speed * float(profile.get("speed_multiplier", 1.0)),
		0.0,
		16.0
	)
	var detection_multiplier := float(profile.get("detection_multiplier", 1.0))
	_runtime_detection_range = clampf(
		detection_range * detection_multiplier,
		1.0,
		50.0
	)
	_runtime_pursuit_range = clampf(
		pursuit_range * detection_multiplier,
		1.0,
		50.0
	)
	_runtime_attack_damage = maxi(
		1,
		int(round(
			float(attack_damage)
			* float(profile.get("damage_multiplier", 1.0))
		))
	)
	_runtime_attack_cooldown = clampf(
		attack_cooldown * float(profile.get("cooldown_multiplier", 1.0)),
		0.35,
		3.0
	)
	_runtime_attack_windup = clampf(
		attack_windup * float(profile.get("windup_multiplier", 1.0)),
		0.05,
		2.0
	)


func _play_animation(animation_name: StringName) -> void:
	if not _has_animation(animation_name):
		return
	# Hurt görseli oynarken yapay zekâ hareket etmeye devam eder; normal
	# yürüyüş/idle çağrıları yalnız kısa görsel reaksiyonu ezmez. Saldırı
	# başladığında ise attack animasyonu öncelik alır.
	if (
		_hurt_anim_locked
		and not _attack_locked
		and animation_name != &"hurt"
	):
		return
	var target_animation := animation_name
	var observer_is_behind := _is_observer_behind_enemy()
	if observer_is_behind:
		if animation_name == &"idle" and _has_animation(&"idle_back"):
			target_animation = &"idle_back"
		elif animation_name == &"walk" and _has_animation(&"walk_back"):
			target_animation = &"walk_back"
	if animated_sprite.animation == target_animation and animated_sprite.is_playing():
		return
	animated_sprite.play(target_animation)
	_apply_frame_ground_offset()


func _has_animation(animation_name: StringName) -> bool:
	return (
		animated_sprite.sprite_frames != null
		and animated_sprite.sprite_frames.has_animation(animation_name)
		and animated_sprite.sprite_frames.get_frame_count(animation_name) > 0
	)


func _is_observer_behind_enemy() -> bool:
	var observer_position := Vector3.ZERO
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		observer_position = camera.global_position
	elif _player != null and is_instance_valid(_player):
		observer_position = _player.global_position
	else:
		return false
	var direction_to_observer := observer_position - global_position
	direction_to_observer.y = 0.0
	if direction_to_observer.length_squared() <= 0.001:
		return false
	return (
		_facing_direction.dot(direction_to_observer.normalized())
		< back_view_threshold
	)


func receive_ally_alert(suspected_position: Vector3) -> void:
	if _dead:
		return
	_exit_dormant_mode()
	_aggro = true
	_last_seen_position = suspected_position
	_lost_sight_remaining = lost_sight_timeout
	_search_remaining = search_duration
	_detour_remaining = 0.0


func _alert_nearby_allies(suspected_position: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not is_instance_valid(node):
			continue
		if not (node is Node3D) or not node.has_method("receive_ally_alert"):
			continue
		var ally := node as Node3D
		if global_position.distance_to(ally.global_position) <= ally_alert_radius:
			ally.call("receive_ally_alert", suspected_position)
