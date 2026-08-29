class_name VexRavager
extends CharacterBody3D

const EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")
const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")

enum State {
	IDLE,
	PATROL,
	CHASE,
	ATTACK,
	SEARCH,
	RETURN,
	DEAD,
}

@export_category("01 - Kimlik, Can ve Zorluk")
@export var enemy_id: StringName = &"ravager"
@export_enum("Yakın", "Orta", "Uzak") var combat_role: int = EnemyCombatProfiles.Role.MID
@export_range(1, 1000, 1) var maximum_health := 75
@export_range(0, 3, 1) var spawn_min_difficulty := 0
@export var apply_difficulty_scaling := true

@export_category("01B - Zorluk Çarpanları (Sahne)")
@export var difficulty_health_multipliers := PackedFloat32Array([0.75, 1.0, 1.20, 1.45])
@export var difficulty_damage_multipliers := PackedFloat32Array([0.65, 1.0, 1.25, 1.55])
@export var difficulty_speed_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.15])
@export var difficulty_detection_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.20])
@export var difficulty_cooldown_multipliers := PackedFloat32Array([1.25, 1.0, 0.85, 0.70])
@export var difficulty_windup_multipliers := PackedFloat32Array([1.20, 1.0, 0.90, 0.75])

@export_category("02 - Hareket ve Boşta Gezinme")
@export_range(0.5, 10.0, 0.1) var move_speed := 2.7
@export_range(0.0, 16.0, 0.1) var chase_speed := 0.0
@export_range(0.5, 40.0, 0.5) var movement_acceleration := 12.0
@export_range(0.5, 40.0, 0.5) var braking_acceleration := 21.0
@export_range(0.0, 4.0, 0.05) var gravity_scale := 1.0
@export_range(-5.0, 0.0, 0.05) var floor_stick_velocity := -0.1
@export_flags_3d_physics var floor_collision_mask := 1
@export_range(0.1, 5.0, 0.1) var floor_snap_max_correction := 2.0
@export_range(0.0, 2.0, 0.05) var floor_snap_ray_start_height := 0.5
@export_range(0.0, 4.0, 0.1) var floor_snap_ray_extra_depth := 2.0
@export var patrol_offset := Vector3(0, 0, 3.0)

@export_category("03 - Algılama ve Takip")
@export_range(1.0, 50.0, 0.5) var detection_range := 30.0
@export_range(1.0, 60.0, 0.5) var pursuit_range := 38.0
@export_range(30.0, 360.0, 5.0) var initial_view_angle := 240.0
@export_range(1.0, 60.0, 0.5) var lost_sight_timeout := 20.0
@export_range(1.0, 30.0, 0.5) var search_duration := 10.0
@export_range(0.5, 5.0, 0.1) var search_probe_radius := 2.2
@export_range(15.0, 180.0, 5.0) var search_turn_speed := 45.0
@export_range(1.0, 30.0, 0.5) var ally_alert_radius := 10.5
@export_range(0.0, 3.0, 0.05) var sight_origin_height := 0.55
@export_range(0.0, 3.0, 0.05) var sight_target_height := 0.45
@export_range(0.0, 1.0, 0.05) var crouch_detection_chance := 0.45
@export_range(0.5, 5.0, 0.25) var crouch_guaranteed_detection_distance := 3.0
@export_flags_3d_physics var sight_collision_mask := 1 | 2
@export var aggro_on_damage := true
@export var alert_allies_on_damage := true
@export var alert_allies_on_detection := true
@export var receive_ally_alerts := true
@export_range(1.0, 120.0, 1.0) var damage_reaction_range := 80.0
@export_range(1.0, 30.0, 0.5) var damage_reaction_duration := 12.0
@export_range(0.1, 1.0, 0.05) var ranged_cover_visibility_threshold := 0.60
@export_range(0.8, 6.0, 0.1) var ranged_cover_reposition_distance := 2.6
@export_range(0.15, 2.0, 0.05) var ranged_cover_reposition_refresh := 0.55
@export_range(0.2, 3.0, 0.1) var damage_approach_offset := 1.4
@export_category("03B - İşitme / Stealth")
@export_range(2.0, 40.0, 0.5) var hearing_radius := 14.0
@export_range(0.1, 2.0, 0.05) var hearing_loudness_scale := 1.0
@export_range(0.1, 1.0, 0.05) var headshot_height_ratio := 0.62
@export var hurt_reaction_enabled := true

@export_category("04 - Saldırı")
@export_range(1, 100, 1) var attack_damage := 12
@export_range(0.5, 20.0, 0.1) var attack_range := 9.0
@export_range(0.2, 5.0, 0.05) var attack_cooldown := 0.80
@export_range(0.05, 2.0, 0.05) var attack_windup := 0.25
@export_range(0.0, 8.0, 0.05) var attack_range_tolerance := 0.65
@export var projectile_scene: PackedScene
@export_range(-2.0, 3.0, 0.01) var projectile_spawn_height := 0.55
@export_range(-2.0, 2.0, 0.01) var projectile_spawn_side_offset := 0.0
@export_range(0.0, 2.0, 0.01) var projectile_spawn_forward_offset := 0.0
@export_range(0.0, 3.0, 0.05) var projectile_target_height := 0.40
@export_range(0.0, 1.0, 0.05) var projectile_lead_factor := 0.0
@export_range(0.0, 2.0, 0.05) var projectile_max_lead_time := 0.0
@export_range(0.0, 10.0, 0.1) var attack_approach_speed := 0.0
@export_range(0.0, 10.0, 0.1) var attack_strafe_speed := 0.0
@export_range(0.5, 20.0, 0.1) var attack_preferred_distance := 6.0

@export_category("05 - Yol Bulma")
@export_range(0.1, 1.0, 0.05) var path_refresh_interval := 0.35
@export_range(4.0, 15.0, 0.5) var waypoint_link_distance := 9.0
@export_range(0.3, 1.2, 0.05) var navigation_clearance := 0.7
@export_range(0.3, 1.5, 0.05) var waypoint_reach_distance := 0.65
@export_range(0.1, 5.0, 0.1) var path_target_change_distance := 1.0
@export_range(0.1, 2.0, 0.05) var patrol_path_refresh_interval := 0.5
@export_range(1.0, 4.0, 0.1) var endpoint_link_distance_multiplier := 1.5
@export_range(1, 32, 1) var endpoint_candidate_count := 10
@export_range(1, 16, 1) var endpoint_connection_limit := 5
@export_range(1, 64, 1) var investigation_candidate_count := 18
@export_range(0.6, 2.0, 0.05) var runtime_grid_step := 1.0
@export_range(200, 6000, 100) var runtime_grid_max_nodes := 1800
@export_range(4.0, 30.0, 0.5) var runtime_grid_search_margin := 12.0
@export_flags_3d_physics var navigation_collision_mask := 1 | 8

@export_category("06 - Performans")
@export_range(0.0, 30.0, 0.5) var idle_detection_margin := 6.0
@export_range(0.02, 1.0, 0.01) var near_sight_interval := 0.12
@export_range(0.02, 1.0, 0.01) var medium_sight_interval := 0.18
@export_range(12.0, 80.0, 1.0) var distant_think_distance := 24.0
@export_range(0.1, 1.0, 0.05) var distant_sight_interval := 0.2
@export_range(0.1, 1.0, 0.05) var idle_far_sight_interval := 0.32
@export_range(0.3, 2.0, 0.05) var distant_path_refresh_interval := 0.6
@export_range(12.0, 80.0, 1.0) var dormant_distance := 44.0

@export_category("07 - Görsel ve Animasyon")
@export_range(-1.0, 1.0, 0.05) var back_view_threshold := -0.15
@export_range(0.0, 2.0, 0.01) var hurt_reaction_duration := 0.16
@export_range(-1.0, 2.0, 0.01) var corpse_visual_y := -0.0999775
@export_range(-1.0, 2.0, 0.01) var back_corpse_visual_y := -0.0999775
@export_range(0.05, 1.0, 0.05) var death_fall_time := 0.3
@export_range(0.0, 4.0, 0.05) var corpse_hold_duration := 2.4
@export_range(0.005, 0.1, 0.005) var corpse_floor_clearance := 0.02
@export var idle_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var idle_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var walk_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var walk_back_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])
@export var hurt_frame_y_offsets := PackedFloat32Array([0.0])
@export var death_frame_y_offsets := PackedFloat32Array([0.0, -0.008, -0.016, -0.025])

@export_category("08 - Ölüm Sonrası İz")
@export var burn_remains_scene: PackedScene
@export_range(0.4, 3.5, 0.05) var burn_remains_scale := 1.0
@export_range(0.1, 2.0, 0.01) var burn_remains_scale_multiplier := 1.0
@export var burn_scorch_tint := Color(0.18, 0.03, 0.06, 0.96)
@export var burn_ember_tint := Color(0.44, 0.08, 0.14, 0.22)
@export_range(0.0, 2.0, 0.01) var burn_ember_emission_energy := 0.10
@export var burn_smoke_enabled := false
@export_range(0.0, 20.0, 0.1) var burn_smoke_duration := 9.0
@export_range(0.0, 1.0, 0.01) var burn_smoke_alpha := 0.14

@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

var health := 0
var state := State.IDLE

var _spawn_position := Vector3.ZERO
var _idle_anchor_position := Vector3.ZERO
var _idle_wander_target := Vector3.ZERO
var _has_idle_wander_target := false
var _idle_wander_pause_remaining := 0.0
var _facing_direction := Vector3.FORWARD
var _alerted := false
var _attack_locked := false
var _attack_windup_active := false
var _attack_strafe_direction := -1.0
var _hurt_reaction_locked := false
var _gravity := 20.0
var _player: Node3D = null

var _sight_check_remaining := 0.0
var _player_visible := false
var _seconds_without_sight := 0.0
var _last_seen_position := Vector3.ZERO
var _has_last_seen_position := false
var _search_remaining := 0.0
var _search_probe_index := 0
var _search_probe_target := Vector3.ZERO
var _has_search_probe := false
var _damage_reaction_remaining := 0.0
var _forced_damage_target := Vector3.ZERO
var _has_forced_damage_target := false
var _forced_damage_best_distance := INF
var _forced_damage_stall_remaining := 0.0
var _combat_interrupt_generation := 0
var _last_visibility_ratio := 0.0
var _ranged_reposition_target := Vector3.ZERO
var _has_ranged_reposition_target := false
var _ranged_reposition_remaining := 0.0
var _local_detour_side := 0.0
var _local_detour_remaining := 0.0

static var _shared_navigation_scene_id := -1
static var _shared_navigation_caches: Dictionary = {}

var _navigation_points: Array[Vector3] = []
var _valid_edges: Array[Vector2i] = []
var _navigation_graph: AStar3D = null
var _current_path := PackedVector3Array()
var _path_index := 0
var _path_refresh_remaining := 0.0
var _path_target := Vector3.ZERO
var _has_path_target := false
var _runtime_maximum_health := 1
var _runtime_attack_damage := 1
var _runtime_move_speed := 0.5
var _runtime_chase_speed := 0.5
var _runtime_detection_range := 1.0
var _runtime_pursuit_range := 1.0
var _runtime_attack_cooldown := 1.0
var _runtime_attack_windup := 0.1
var _dormant_active := false
var _burn_remains: Node3D = null
var _visual_base_y := 0.0


func _ready() -> void:
	_visual_base_y = animated_sprite.position.y
	if not animated_sprite.frame_changed.is_connected(_on_visual_frame_changed):
		animated_sprite.frame_changed.connect(_on_visual_frame_changed)
	_apply_frame_ground_offset()
	if GameState.active_difficulty < spawn_min_difficulty:
		queue_free()
		return
	add_to_group("enemy")
	add_to_group("damageable")
	if not GameState.noise_emitted.is_connected(_on_noise_emitted):
		GameState.noise_emitted.connect(_on_noise_emitted)
	_configure_runtime_stats()
	health = _runtime_maximum_health
	_spawn_position = global_position
	_idle_anchor_position = global_position
	_gravity = (
		float(ProjectSettings.get_setting("physics/3d/default_gravity", 20.0))
		* gravity_scale
	)

	if GameState.was_enemy_defeated(enemy_id):
		_restore_defeated_state()
		return

	# Aynı karede onlarca düşmanın raycast/path yenilemesini engelle.
	_sight_check_remaining = randf_range(0.0, near_sight_interval)
	_path_refresh_remaining = randf_range(0.0, path_refresh_interval)
	_play_directional_animation(&"idle", &"idle_back")
	call_deferred("_cache_navigation_waypoints")


func _configure_runtime_stats() -> void:
	_runtime_maximum_health = maximum_health
	_runtime_attack_damage = attack_damage
	_runtime_move_speed = move_speed
	_runtime_chase_speed = chase_speed if chase_speed > 0.0 else move_speed
	_runtime_detection_range = detection_range
	_runtime_pursuit_range = pursuit_range
	_runtime_attack_cooldown = attack_cooldown
	_runtime_attack_windup = attack_windup
	if not apply_difficulty_scaling:
		return

	var health_scale := _scene_difficulty_multiplier(difficulty_health_multipliers)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	var speed_scale := _scene_difficulty_multiplier(difficulty_speed_multipliers)
	var detection_scale := _scene_difficulty_multiplier(difficulty_detection_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	_runtime_maximum_health = maxi(1, int(round(float(maximum_health) * health_scale)))
	_runtime_attack_damage = maxi(1, int(round(float(attack_damage) * damage_scale)))
	_runtime_move_speed = maxf(0.0, move_speed * speed_scale)
	_runtime_chase_speed = maxf(0.0, (chase_speed if chase_speed > 0.0 else move_speed) * speed_scale)
	_runtime_detection_range = maxf(0.0, detection_range * detection_scale)
	_runtime_pursuit_range = maxf(0.0, pursuit_range * detection_scale)
	_runtime_attack_cooldown = maxf(0.01, attack_cooldown * cooldown_scale)
	_runtime_attack_windup = maxf(0.0, attack_windup * windup_scale)


func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
	return VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _physics_process(delta: float) -> void:
	if state == State.DEAD:
		return

	if _player == null or not is_instance_valid(_player):
		_player = GameState.player as Node3D
	_damage_reaction_remaining = maxf(0.0, _damage_reaction_remaining - delta)
	_ranged_reposition_remaining = maxf(0.0, _ranged_reposition_remaining - delta)
	_local_detour_remaining = maxf(0.0, _local_detour_remaining - delta)

	if _should_use_dormant_mode():
		_enter_dormant_mode()
		_apply_dormant_physics(delta)
		return
	_exit_dormant_mode()

	_path_refresh_remaining -= delta
	_update_perception(delta)
	_update_behavior(delta)
	_apply_gravity(delta)
	move_and_slide()

	if get_slide_collision_count() > 0:
		# Bir kapı kapanırsa veya rota fiziksel olarak değişirse yolu erken yenile.
		_path_refresh_remaining = 0.0


func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
	if state == State.DEAD or amount <= 0:
		return

	health -= amount
	_exit_dormant_mode()
	# Damage pursuit is mandatory and has higher priority than sight/range/attack state.
	_alerted = true
	_combat_interrupt_generation += 1
	_attack_locked = false
	_attack_windup_active = false
	state = State.CHASE
	_damage_reaction_remaining = damage_reaction_duration
	_seconds_without_sight = 0.0
	_search_remaining = 0.0
	_sight_check_remaining = 0.0
	var retaliation_target := Vector3.ZERO
	var has_retaliation_target := false
	if _source is Node3D:
		retaliation_target = (_source as Node3D).global_position
		has_retaliation_target = true
	elif _player != null and is_instance_valid(_player):
		retaliation_target = _player.global_position
		has_retaliation_target = true
	if has_retaliation_target:
		retaliation_target.y = global_position.y
		_forced_damage_target = retaliation_target
		_has_forced_damage_target = true
		_forced_damage_best_distance = _horizontal_distance(global_position, retaliation_target)
		_forced_damage_stall_remaining = 3.0
		_last_seen_position = retaliation_target
		_has_last_seen_position = true
	_path_refresh_remaining = 0.0
	_ranged_reposition_remaining = 0.0
	_has_ranged_reposition_target = false
	_local_detour_remaining = 0.0
	_local_detour_side = 0.0
	_clear_path()
	if _has_last_seen_position:
		_face_toward_position(_last_seen_position)
	if alert_allies_on_damage:
		_alert_nearby_allies(_last_seen_position if _has_last_seen_position else global_position)

	if health <= 0:
		_die()
	else:
		if hurt_audio.stream != null and not hurt_audio.playing:
			hurt_audio.play()
		# Saldırı başlamışsa vurulma animasyonu saldırı animasyonunu ezmesin.
		# Diğer durumlarda da kısa bir reaksiyon kilidi, pompalı gibi çok saçmalı
		# silahların aynı karede art arda flinch başlatmasını engeller.
		if (
			hurt_reaction_enabled
			and not _attack_locked
			and not _hurt_reaction_locked
			and _has_animation(&"hurt")
		):
			_hurt_reaction_locked = true
			animated_sprite.play(&"hurt")
			_apply_frame_ground_offset()
			_resume_animation_after_hurt()


func _on_noise_emitted(noise_position: Vector3, loudness: float, source: Node) -> void:
	if state == State.DEAD or source == self:
		return
	var distance := _horizontal_distance(global_position, noise_position)
	var effective_range := hearing_radius * maxf(loudness * hearing_loudness_scale, 0.1)
	if distance > effective_range:
		return
	var hearing_origin := global_position + Vector3.UP * 0.8
	var hearing_target := noise_position + Vector3.UP * 0.8
	if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
		get_world_3d(), hearing_origin, hearing_target
	):
		return
	_exit_dormant_mode()
	_alerted = true
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = search_duration
	_last_seen_position = noise_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true
	state = State.CHASE
	_clear_path()
	_path_refresh_remaining = 0.0
	if loudness >= 0.9:
		_alert_nearby_allies(noise_position)


func get_weapon_hit_multiplier(hit_position: Vector3, base_headshot_multiplier: float) -> float:
	var local_y := hit_position.y - global_position.y
	var head_threshold := 0.95 * headshot_height_ratio
	return base_headshot_multiplier if local_y >= head_threshold else 1.0


func receive_ally_alert(suspected_position: Vector3) -> void:
	if state == State.DEAD or _player_visible or not receive_ally_alerts:
		return

	_exit_dormant_mode()
	_alerted = true
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = 0.0
	_last_seen_position = suspected_position
	_last_seen_position.y = global_position.y
	_has_last_seen_position = true
	state = State.CHASE
	_clear_path()
	_path_refresh_remaining = 0.0

	var alert_direction := _last_seen_position - global_position
	alert_direction.y = 0.0
	if alert_direction.length_squared() > 0.001:
		_facing_direction = alert_direction.normalized()


func _alert_nearby_allies(suspected_position: Vector3) -> void:
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not (node is Node3D):
			continue
		if not node.has_method("receive_ally_alert"):
			continue

		var ally := node as Node3D
		if _horizontal_distance(global_position, ally.global_position) > ally_alert_radius:
			continue
		if not VexEnemyRuntimeUtils.has_clear_acoustic_path(
			get_world_3d(),
			global_position + Vector3.UP * 0.8,
			ally.global_position + Vector3.UP * 0.8
		):
			continue
		ally.call("receive_ally_alert", suspected_position)


func _update_perception(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player_visible = false
		if _alerted:
			_seconds_without_sight += delta
		return

	var player_distance := _horizontal_distance(global_position, _player.global_position)
	# Oyuncu çok uzaktaysa ve düşman zaten alarm durumunda değilse her kare
	# görüş ışını atmaya gerek yok. Bu erken çıkış özellikle geniş haritada
	# 20+ düşman varken fizik raycast yükünü hissedilir biçimde düşürür.
	if (
		not _alerted
		and player_distance > _runtime_detection_range + idle_detection_margin
	):
		_player_visible = false
		_sight_check_remaining = maxf(_sight_check_remaining - delta, 0.0)
		if _sight_check_remaining <= 0.0:
			_sight_check_remaining = idle_far_sight_interval
		return

	var sight_interval := near_sight_interval
	if player_distance > distant_think_distance:
		sight_interval = distant_sight_interval if _alerted else idle_far_sight_interval
	elif player_distance > _runtime_detection_range:
		sight_interval = medium_sight_interval

	_sight_check_remaining -= delta
	if _sight_check_remaining <= 0.0:
		_sight_check_remaining = sight_interval
		_player_visible = _can_see_player()
		# Son görülen konumu yalnızca yeni bir görüş ışını gerçekten oyuncuya
		# ulaştığında güncelle. Önceki görüş sonucunu ara karelerde kullanmak,
		# koşan oyuncunun duvar arkasındaki konumunu yanlışlıkla kaydediyordu.
		if _player_visible:
			_last_seen_position = _player.global_position
			_has_last_seen_position = true

	if _player_visible:
		var was_alerted := _alerted
		_alerted = true
		_seconds_without_sight = 0.0
		if not was_alerted and alert_allies_on_detection and _has_last_seen_position:
			_alert_nearby_allies(_last_seen_position)
	elif _alerted:
		_seconds_without_sight += delta


func _update_behavior(delta: float) -> void:
	# A hit immediately overrides normal combat. Reach the exact source position,
	# or the closest reachable point, before resuming normal role tactics.
	if _has_forced_damage_target:
		var forced_distance := _horizontal_distance(global_position, _forced_damage_target)
		if forced_distance < _forced_damage_best_distance - 0.20:
			_forced_damage_best_distance = forced_distance
			_forced_damage_stall_remaining = 3.0
		else:
			_forced_damage_stall_remaining = maxf(0.0, _forced_damage_stall_remaining - delta)
		if _has_reached_walkable_target(_forced_damage_target, waypoint_reach_distance):
			_has_forced_damage_target = false
			_damage_reaction_remaining = 0.0
			_last_seen_position = _forced_damage_target
			_has_last_seen_position = true
			_begin_search()
			return
		state = State.CHASE
		_navigate_to(_forced_damage_target, delta)
		if (
			_forced_damage_stall_remaining <= 0.0
			and (_current_path.is_empty() or _path_index >= _current_path.size())
		):
			_has_forced_damage_target = false
			_damage_reaction_remaining = 0.0
			_last_seen_position = _forced_damage_target
			_has_last_seen_position = true
			_begin_search()
		return
	# Atış başladıktan sonra kısa hazırlık penceresi tamamlanır. Oyuncunun
	# yalnız geri yürümesi atışı iptal etmez; duvar arkasına geçmek hâlâ
	# görüş kontrolü sayesinde mermiyi engeller.
	if _attack_locked:
		state = State.ATTACK
		var attack_target := global_position
		var has_attack_target := false
		if _player_visible and _player != null and is_instance_valid(_player):
			attack_target = _player.global_position
			has_attack_target = true
		elif _has_last_seen_position:
			attack_target = _last_seen_position
			has_attack_target = true

		if not has_attack_target:
			_stop_horizontal_motion()
		elif _attack_windup_active:
			# Hazırlık karesi zeminde kaymasın; mermi çıkar çıkmaz yürüyüş
			# animasyonuyla yeniden konumlanmaya başlanır.
			_face_toward_position(attack_target)
			_stop_horizontal_motion()
		elif _uses_cover_reposition_tactics() and _last_visibility_ratio < _cover_visibility_threshold():
			# Yalnız gerçek projectile shooter'lar kısmi görüşte yan/çapraz atış açısı arar.
			# Warden gibi geniş attack_range kullanan yakın baskı elitleri burada strafe etmez.
			_reposition_for_clear_shot(delta)
		else:
			_move_during_attack_recovery(attack_target, delta)
		return

	if (
		_player_visible
		and _has_last_seen_position
		and _player != null
		and is_instance_valid(_player)
	):
		# Görüş örnekleri arasındaki karelerde oyuncunun duvar arkasındaki canlı
		# konumunu değil, doğrulanmış son görünür konumu kullan.
		# Menzilli düşman oyuncunun yalnız küçük bir parçasını görüyorsa mevcut
		# noktadan atış spamlamak yerine gerçek bir yeni görüş açısı arar.
		if _uses_cover_reposition_tactics() and _last_visibility_ratio < _cover_visibility_threshold():
			state = State.CHASE
			_reposition_for_clear_shot(delta)
			return
		var distance_to_player := _horizontal_distance(global_position, _last_seen_position)
		if distance_to_player <= attack_range:
			state = State.ATTACK
			_face_toward_position(_last_seen_position)
			_stop_horizontal_motion()
			_attempt_attack()
		else:
			state = State.CHASE
			_navigate_to(_last_seen_position, delta)
		return

	if state == State.SEARCH:
		_search_last_seen_area(delta)
		return

	if _alerted:
		if _seconds_without_sight >= lost_sight_timeout:
			_begin_search()
			return
		if _has_last_seen_position:
			state = State.CHASE
			# İnce duvarın öbür tarafındaki hedef yakın görünse bile fiziksel olarak
			# ulaşılmış sayılmaz. Duvar varsa chase devam eder.
			if _has_reached_walkable_target(_last_seen_position, waypoint_reach_distance):
				_begin_search()
			else:
				_navigate_to(_last_seen_position, delta)
			return

	if state == State.RETURN:
		_return_to_patrol(delta)
	else:
		_patrol(delta)


func is_pursuing_player() -> bool:
	return state != State.DEAD and _alerted


func _resolve_enemy_door_step(target_position: Vector3) -> Vector3:
	var best_point := target_position
	var best_score := INF
	var found := false
	for node: Node in get_tree().get_nodes_in_group("enemy_navigation_door"):
		if not node.has_method("get_enemy_navigation_step"):
			continue
		var route: Variant = node.call(
			"get_enemy_navigation_step",
			global_position,
			target_position,
			navigation_clearance
		)
		if not (route is Dictionary):
			continue
		var data := route as Dictionary
		if not bool(data.get("valid", false)):
			continue
		var point: Variant = data.get("point", target_position)
		if typeof(point) != TYPE_VECTOR3:
			continue
		var score := float(data.get("score", INF))
		if score < best_score:
			best_score = score
			best_point = point
			found = true
	return best_point if found else target_position


func _patrol(delta: float) -> void:
	state = State.PATROL
	if _idle_wander_pause_remaining > 0.0:
		_idle_wander_pause_remaining = maxf(0.0, _idle_wander_pause_remaining - delta)
		_stop_horizontal_motion()
		_facing_direction = _facing_direction.rotated(Vector3.UP, delta * 0.28).normalized()
		rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
		return

	if (
		not _has_idle_wander_target
		or _has_reached_walkable_target(_idle_wander_target, waypoint_reach_distance)
	):
		var radius := EnemyCombatProfiles.idle_wander_radius(combat_role)
		_idle_wander_target = EnemyNavigationRuntime.choose_idle_wander_target(
			self,
			_idle_anchor_position,
			radius,
			navigation_collision_mask,
			floor_collision_mask,
			navigation_clearance,
			floor_snap_ray_start_height,
			floor_snap_ray_extra_depth
		)
		_has_idle_wander_target = _horizontal_distance(global_position, _idle_wander_target) > 0.25
		if not _has_idle_wander_target:
			_idle_wander_pause_remaining = randf_range(
				EnemyCombatProfiles.idle_pause_min(combat_role),
				EnemyCombatProfiles.idle_pause_max(combat_role)
			)
			_stop_horizontal_motion()
			return
		_clear_path()
		_path_refresh_remaining = 0.0

	_navigate_to(_idle_wander_target, delta)
	if _has_reached_walkable_target(_idle_wander_target, waypoint_reach_distance):
		_has_idle_wander_target = false
		_idle_wander_pause_remaining = randf_range(
			EnemyCombatProfiles.idle_pause_min(combat_role),
			EnemyCombatProfiles.idle_pause_max(combat_role)
		)


func _return_to_patrol(_delta: float) -> void:
	# No fixed patrol route: after combat the current position becomes the new
	# local idle anchor and the creature resumes contextual wandering there.
	_idle_anchor_position = global_position
	_has_idle_wander_target = false
	_idle_wander_pause_remaining = randf_range(
		EnemyCombatProfiles.idle_pause_min(combat_role),
		EnemyCombatProfiles.idle_pause_max(combat_role)
	)
	state = State.PATROL
	_clear_path()
	_stop_horizontal_motion()


func _begin_search() -> void:
	state = State.SEARCH
	_search_remaining = search_duration
	_reset_search_probe()
	_advance_search_probe()


func _reset_search_probe() -> void:
	_search_probe_index = 0
	_search_probe_target = Vector3.ZERO
	_has_search_probe = false


func _advance_search_probe() -> void:
	if not _has_last_seen_position:
		_reset_search_probe()
		return
	_search_probe_target = VexEnemyRuntimeUtils.investigation_probe(
		_last_seen_position,
		_facing_direction,
		_search_probe_index,
		search_probe_radius
	)
	_search_probe_target.y = global_position.y
	_search_probe_index += 1
	_has_search_probe = true
	_clear_path()
	_path_refresh_remaining = 0.0


func _search_last_seen_area(delta: float) -> void:
	_search_remaining -= delta
	if _search_remaining <= 0.0 or not _has_last_seen_position:
		_give_up_chase()
		return

	if (
		not _has_search_probe
		or _has_reached_walkable_target(_search_probe_target, waypoint_reach_distance)
	):
		_advance_search_probe()

	# Ulaşılamayan tek bir probe bütün aramayı kilitlemesin. AStar rota bulamazsa
	# aynı karede birkaç alternatif köşe/yan probe dene.
	for _attempt: int in range(4):
		_navigate_to(_search_probe_target, delta)
		if not _current_path.is_empty() and _path_index < _current_path.size():
			return
		_advance_search_probe()

	_stop_horizontal_motion()
	_facing_direction = _facing_direction.rotated(
		Vector3.UP,
		deg_to_rad(search_turn_speed) * delta
	).normalized()
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)


func _give_up_chase() -> void:
	_alerted = false
	_player_visible = false
	_seconds_without_sight = 0.0
	_search_remaining = 0.0
	_has_last_seen_position = false
	_has_forced_damage_target = false
	_reset_search_probe()
	_idle_anchor_position = global_position
	_has_idle_wander_target = false
	_idle_wander_pause_remaining = randf_range(
		EnemyCombatProfiles.idle_pause_min(combat_role),
		EnemyCombatProfiles.idle_pause_max(combat_role)
	)
	state = State.PATROL
	_clear_path()
	_stop_horizontal_motion()


func _navigate_to(target: Vector3, delta: float) -> void:
	var destination := _resolve_enemy_door_step(target)
	destination.y = global_position.y

	var role_target_change := EnemyCombatProfiles.path_target_change_distance(combat_role)
	var target_changed := (
		not _has_path_target
		or _horizontal_distance(_path_target, destination) > role_target_change
	)
	var refresh_interval := (
		EnemyCombatProfiles.path_refresh_interval(combat_role)
		if state == State.CHASE
		else path_refresh_interval
	)
	if _player != null and is_instance_valid(_player):
		var player_distance := _horizontal_distance(global_position, _player.global_position)
		if player_distance > distant_think_distance:
			refresh_interval = maxf(refresh_interval, distant_path_refresh_interval)
		elif state == State.PATROL and player_distance > attack_range * 2.0:
			refresh_interval = maxf(refresh_interval, patrol_path_refresh_interval)
	# Pahalı fizik raylarını her fizik karesinde çalıştırma. Doğrudan yol ve
	# rota yalnızca hedef anlamlı biçimde değiştiğinde veya yenileme süresi
	# dolduğunda tekrar doğrulanır. move_and_slide() gerçek bir engelle
	# karşılaşırsa _physics_process() yolu bir sonraki karede zorla yeniler.
	if _path_refresh_remaining <= 0.0 or target_changed or not _has_path_target:
		if _is_walk_segment_clear(global_position, destination):
			_current_path = PackedVector3Array([global_position, destination])
			_path_index = 1
			_path_target = destination
			_has_path_target = true
		else:
			_rebuild_path(destination)
		_path_refresh_remaining = refresh_interval

	while (
		_path_index < _current_path.size()
		and _has_reached_walkable_target(
			_current_path[_path_index],
			waypoint_reach_distance
		)
	):
		_path_index += 1

	if _path_index >= _current_path.size():
		_stop_horizontal_motion()
		return

	_move_toward_point(_current_path[_path_index], delta)


func _rebuild_path(destination: Vector3) -> void:
	_current_path = PackedVector3Array()
	_path_index = 0
	_path_target = destination
	_has_path_target = true

	# Aktif takipte elle yerleştirilmiş waypoint'lere bağlı kalma. Fizik dünyasını
	# grid olarak arayıp hedefe giden en kısa yürünebilir rotayı çıkar. Böylece
	# düşman, ateşin geldiği nokta duvar arkasındaysa haritanın hangi tarafından
	# dolaşması gerektiğini yerel sağ/sol tahmin yerine A* ile seçer.
	if state == State.CHASE:
		_current_path = _build_runtime_shortest_path(destination)
		if _current_path.size() > 1:
			_path_index = 1
			return

	# Ortak AStar ağı da harita başına bir kez oluşturulur. Rota ararken yalnızca
	# geçici başlangıç/hedef noktaları eklenir; yüzlerce sabit bağlantı tekrar
	# oluşturulmaz. GDScript fizik işlemleri ana iş parçacığında sıralı olduğu
	# için bu geçici noktalar aynı fonksiyon içinde güvenle eklenip kaldırılır.
	var graph := _navigation_graph
	if graph == null:
		graph = _build_astar_graph()
		_navigation_graph = graph

	var start_id := _navigation_points.size()
	var target_id := start_id + 1
	graph.add_point(start_id, global_position)
	graph.add_point(target_id, destination)

	if _is_walk_segment_clear(global_position, destination):
		graph.connect_points(start_id, target_id, true)
	else:
		_connect_endpoint_to_graph(graph, start_id, global_position)
		_connect_endpoint_to_graph(graph, target_id, destination)

	_current_path = graph.get_point_path(start_id, target_id)
	if _current_path.is_empty():
		# Önce sahne waypoint ağını dene.
		_current_path = _find_investigation_path(graph, start_id, destination)
	if _current_path.is_empty():
		# Waypoint bulunmayan test/level sahnelerinde boş rota ile donmak yerine
		# yerel sağ/sol detour üret ve köşeyi adım adım ara.
		_current_path = _build_local_detour_path(destination)
	if _current_path.size() > 1:
		_path_index = 1

	# Ortak grafiği bir sonraki düşman için temiz bırak.
	graph.remove_point(target_id)
	graph.remove_point(start_id)


func _build_runtime_shortest_path(destination: Vector3) -> PackedVector3Array:
	return EnemyNavigationRuntime.build_shortest_path(
		self,
		destination,
		navigation_collision_mask,
		floor_collision_mask,
		navigation_clearance,
		floor_snap_ray_start_height,
		floor_snap_ray_extra_depth,
		EnemyCombatProfiles.grid_step(combat_role),
		EnemyCombatProfiles.grid_max_nodes(combat_role),
		EnemyCombatProfiles.grid_search_margin(combat_role)
	)


func _build_local_detour_path(destination: Vector3) -> PackedVector3Array:
	var toward_target := destination - global_position
	toward_target.y = 0.0
	if toward_target.length_squared() <= 0.001:
		return PackedVector3Array()

	var forward := toward_target.normalized()
	var side := Vector3(-forward.z, 0.0, forward.x)
	var base_step := maxf(navigation_clearance * 1.45, 0.90)
	var lateral_steps := PackedFloat32Array([
		base_step,
		base_step * 1.8,
		base_step * 2.8,
		base_step * 4.0,
	])
	var forward_steps := PackedFloat32Array([0.0, base_step * 0.75, base_step * 1.5])
	var side_signs := PackedFloat32Array([-1.0, 1.0])
	if _local_detour_remaining > 0.0 and absf(_local_detour_side) > 0.5:
		side_signs = PackedFloat32Array([_local_detour_side, -_local_detour_side])

	var best_path := PackedVector3Array()
	var best_score := -INF
	var best_side := 0.0
	var current_remaining := _horizontal_distance(global_position, destination)

	for side_sign: float in side_signs:
		for lateral_distance: float in lateral_steps:
			for forward_distance: float in forward_steps:
				var candidate := (
					global_position
					+ side * side_sign * lateral_distance
					+ forward * forward_distance
				)
				candidate.y = global_position.y
				if not _has_navigation_floor(candidate):
					continue
				if not _is_walk_segment_clear(global_position, candidate):
					continue

				var approach_point := _furthest_walkable_point_toward(candidate, destination)
				var remaining := _horizontal_distance(approach_point, destination)
				var progress := current_remaining - remaining
				var direct_open := _is_walk_segment_clear(candidate, destination)
				var score := -remaining + progress * 1.5 - lateral_distance * 0.08
				if direct_open:
					score += 8.0
				if _local_detour_remaining > 0.0 and side_sign == _local_detour_side:
					score += 0.45

				if score <= best_score:
					continue
				best_score = score
				best_side = side_sign
				best_path = PackedVector3Array([global_position, candidate])
				if (
					_horizontal_distance(candidate, approach_point)
					> waypoint_reach_distance * 0.35
				):
					best_path.append(approach_point)

	if not best_path.is_empty():
		_local_detour_side = best_side
		_local_detour_remaining = 0.90
	return best_path


func _has_navigation_floor(probe_position: Vector3) -> bool:
	var ray_start := probe_position + Vector3.UP * maxf(floor_snap_ray_start_height, 0.65)
	var ray_end := probe_position + Vector3.DOWN * maxf(floor_snap_ray_extra_depth, 2.0)
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		floor_collision_mask,
		[get_rid()]
	)
	query.collide_with_areas = false
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _has_reached_walkable_target(target: Vector3, reach_distance: float) -> bool:
	if _horizontal_distance(global_position, target) > reach_distance:
		return false

	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.000001:
		return true
	var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
	perpendicular *= navigation_clearance
	var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
	var space_state := get_world_3d().direct_space_state
	for offset: Vector3 in offsets:
		var ray_start := global_position + offset
		var ray_end := target + offset
		ray_start.y = global_position.y
		ray_end.y = global_position.y
		var query := PhysicsRayQueryParameters3D.create(
			ray_start,
			ray_end,
			navigation_collision_mask,
			[get_rid()]
		)
		query.collide_with_areas = false
		if not space_state.intersect_ray(query).is_empty():
			return false
	return true


func _build_astar_graph() -> AStar3D:
	var graph := AStar3D.new()
	for point_index: int in range(_navigation_points.size()):
		graph.add_point(point_index, _navigation_points[point_index])
	for edge: Vector2i in _valid_edges:
		graph.connect_points(edge.x, edge.y, true)
	return graph


func _find_investigation_path(
	graph: AStar3D,
	start_id: int,
	destination: Vector3
) -> PackedVector3Array:
	# Hedef (özellikle oyuncunun duvar kenarındaki merkezi) doğrudan erişilemez
	# olabilir. Hedefe düz görüş şartı aramak boş rota üretip AI'ı donduruyordu.
	# Erişilebilir waypoint'lerden hedefe fiziksel olarak en çok yaklaşılabilen
	# noktayı seç; dolaşma yolu varsa hedefe tamamen ulaşan aday doğal olarak kazanır.
	var nearby_indices := _nearest_waypoint_indices(
		destination,
		INF,
		_navigation_points.size()
	)
	var best_path := PackedVector3Array()
	var best_remaining_distance := INF
	var reachable_candidates := 0

	for point_index: int in nearby_indices:
		var candidate_path := graph.get_point_path(start_id, point_index)
		if candidate_path.is_empty():
			continue
		reachable_candidates += 1
		var waypoint := _navigation_points[point_index]
		var approach_point := _furthest_walkable_point_toward(waypoint, destination)
		var remaining_distance := _horizontal_distance(approach_point, destination)

		if remaining_distance < best_remaining_distance:
			best_remaining_distance = remaining_distance
			best_path = candidate_path.duplicate()
			if (
				best_path.is_empty()
				or _horizontal_distance(best_path[best_path.size() - 1], approach_point)
				> waypoint_reach_distance * 0.25
			):
				best_path.append(approach_point)

		if best_remaining_distance <= waypoint_reach_distance * 0.25:
			break
		if reachable_candidates >= 16 and best_remaining_distance <= search_probe_radius * 1.5:
			break

	return best_path


func _furthest_walkable_point_toward(from_position: Vector3, destination: Vector3) -> Vector3:
	var start := from_position
	start.y = global_position.y
	var target := destination
	target.y = global_position.y
	if _is_walk_segment_clear(start, target):
		return target

	# Gövde açıklığını hesaba katarak hedef yönünde yürünebilen son noktayı bul.
	var low := 0.0
	var high := 1.0
	for _step: int in range(8):
		var middle := (low + high) * 0.5
		var probe := start.lerp(target, middle)
		probe.y = global_position.y
		if _is_walk_segment_clear(start, probe):
			low = middle
		else:
			high = middle

	var result := start.lerp(target, low)
	result.y = global_position.y
	return result


func _connect_endpoint_to_graph(graph: AStar3D, endpoint_id: int, endpoint: Vector3) -> void:
	var maximum_distance := waypoint_link_distance * endpoint_link_distance_multiplier
	var nearby_indices := _nearest_waypoint_indices(
		endpoint,
		maximum_distance,
		endpoint_candidate_count
	)
	var connected_count := 0
	for point_index: int in nearby_indices:
		if _is_walk_segment_clear(endpoint, _navigation_points[point_index]):
			graph.connect_points(endpoint_id, point_index, true)
			connected_count += 1
			if connected_count >= endpoint_connection_limit:
				break


func _nearest_waypoint_indices(
	endpoint: Vector3,
	maximum_distance: float,
	maximum_count: int
) -> Array[int]:
	var indices: Array[int] = []
	var distances: Array[float] = []

	for point_index: int in range(_navigation_points.size()):
		var distance := _horizontal_distance(endpoint, _navigation_points[point_index])
		if distance > maximum_distance:
			continue

		var insert_at := distances.size()
		while insert_at > 0 and distance < distances[insert_at - 1]:
			insert_at -= 1
		distances.insert(insert_at, distance)
		indices.insert(insert_at, point_index)

		if indices.size() > maximum_count:
			indices.pop_back()
			distances.pop_back()

	return indices


func _cache_navigation_waypoints() -> void:
	var current_scene := get_tree().current_scene
	var scene_id := current_scene.get_instance_id() if current_scene != null else 0
	if _shared_navigation_scene_id != scene_id:
		_shared_navigation_scene_id = scene_id
		_shared_navigation_caches.clear()

	var cache_key := "%.3f|%.3f|%d" % [
		waypoint_link_distance,
		navigation_clearance,
		navigation_collision_mask,
	]
	var cached_data: Dictionary = _shared_navigation_caches.get(cache_key, {})
	if not cached_data.is_empty():
		_navigation_points.clear()
		_valid_edges.clear()
		for cached_point: Vector3 in cached_data.get("points", []):
			_navigation_points.append(cached_point)
		for cached_edge: Vector2i in cached_data.get("edges", []):
			_valid_edges.append(cached_edge)
		_navigation_graph = cached_data.get("graph") as AStar3D
		_path_refresh_remaining = 0.0
		return

	_navigation_points.clear()
	_valid_edges.clear()

	for node: Node in get_tree().get_nodes_in_group("enemy_navigation_waypoint"):
		if node is Node3D:
			var waypoint := node as Node3D
			_navigation_points.append(waypoint.global_position)

	# Bu pahalı doğrulama her harita ve gövde açıklığı bileşimi için yalnızca bir
	# kez yapılır. Aynı ayarlardaki düşmanlar noktaları, bağlantıları ve AStar
	# grafiğini doğrudan ortak önbellekten alır.
	for first_index: int in range(_navigation_points.size()):
		for second_index: int in range(first_index + 1, _navigation_points.size()):
			if (
				_horizontal_distance(
					_navigation_points[first_index],
					_navigation_points[second_index]
				) > waypoint_link_distance
			):
				continue
			if _is_walk_segment_clear(
				_navigation_points[first_index],
				_navigation_points[second_index]
			):
				_valid_edges.append(Vector2i(first_index, second_index))

	_navigation_graph = _build_astar_graph()
	_shared_navigation_caches[cache_key] = {
		"points": _navigation_points.duplicate(),
		"edges": _valid_edges.duplicate(),
		"graph": _navigation_graph,
	}
	_path_refresh_remaining = 0.0


func _is_walk_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return true

	var perpendicular := Vector3(-direction.z, 0.0, direction.x).normalized()
	perpendicular *= navigation_clearance
	var offsets: Array[Vector3] = [Vector3.ZERO, perpendicular, -perpendicular]
	var space_state := get_world_3d().direct_space_state

	for offset: Vector3 in offsets:
		var ray_start := from_position + offset
		var ray_end := to_position + offset
		var query := PhysicsRayQueryParameters3D.create(
			ray_start,
			ray_end,
			navigation_collision_mask,
			[get_rid()]
		)
		if not space_state.intersect_ray(query).is_empty():
			return false
	return true


func _is_center_segment_clear(from_position: Vector3, to_position: Vector3) -> bool:
	var direction := to_position - from_position
	direction.y = 0.0
	if direction.length_squared() <= 0.01:
		return true

	var ray_start := from_position
	var ray_end := to_position
	ray_start.y = global_position.y
	ray_end.y = global_position.y
	var query := PhysicsRayQueryParameters3D.create(
		ray_start,
		ray_end,
		navigation_collision_mask,
		[get_rid()]
	)
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()


func _move_toward_point(target: Vector3, delta: float) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if (
		direction.length_squared() < 0.05
		and _has_reached_walkable_target(target, sqrt(0.05))
	):
		_stop_horizontal_motion()
		return

	direction = direction.normalized()
	_facing_direction = direction
	var travel_speed := (
		_runtime_chase_speed
		if state == State.CHASE or state == State.SEARCH
		else _runtime_move_speed
	)
	velocity.x = move_toward(
		velocity.x,
		direction.x * travel_speed,
		delta * movement_acceleration
	)
	velocity.z = move_toward(
		velocity.z,
		direction.z * travel_speed,
		delta * movement_acceleration
	)
	if animated_sprite.animation != &"hurt" and animated_sprite.animation != &"attack":
		_play_directional_animation(&"walk", &"walk_back")


func _face_toward_position(target: Vector3) -> void:
	var direction := target - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.001:
		return
	_facing_direction = direction.normalized()
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)


func _move_during_attack_recovery(target: Vector3, delta: float) -> void:
	var direction_to_target := target - global_position
	direction_to_target.y = 0.0
	var distance_to_target := direction_to_target.length()
	if distance_to_target <= 0.001:
		_stop_horizontal_motion()
		return

	var forward_direction := direction_to_target / distance_to_target
	var right_direction := forward_direction.cross(Vector3.UP).normalized()
	var preferred_distance := EnemyCombatProfiles.preferred_distance(combat_role, attack_range)
	var minimum_distance := EnemyCombatProfiles.minimum_distance(combat_role, attack_range)
	var speed_scale := _runtime_move_speed / maxf(move_speed, 0.001)
	var desired_velocity := Vector3.ZERO

	var strafe_scale := EnemyCombatProfiles.recovery_strafe_scale(combat_role)
	if strafe_scale > 0.0 and attack_strafe_speed > 0.0:
		desired_velocity += (
			right_direction
			* attack_strafe_speed
			* _attack_strafe_direction
			* speed_scale
			* strafe_scale
		)

	if combat_role == EnemyCombatProfiles.Role.CLOSE:
		if distance_to_target > preferred_distance:
			desired_velocity = forward_direction * _runtime_chase_speed
	elif distance_to_target > preferred_distance + 0.35:
		var approach_speed := maxf(attack_approach_speed * speed_scale, _runtime_move_speed * 0.45)
		desired_velocity += forward_direction * approach_speed
	elif distance_to_target < minimum_distance:
		desired_velocity -= (
			forward_direction
			* _runtime_move_speed
			* EnemyCombatProfiles.retreat_scale(combat_role)
		)

	var maximum_speed := _runtime_chase_speed if combat_role == EnemyCombatProfiles.Role.CLOSE else _runtime_move_speed
	if desired_velocity.length() > maximum_speed:
		desired_velocity = desired_velocity.normalized() * maximum_speed

	_facing_direction = forward_direction
	rotation.y = atan2(-_facing_direction.x, -_facing_direction.z)
	if desired_velocity.length_squared() <= 0.001:
		_stop_horizontal_motion()
		return

	velocity.x = move_toward(velocity.x, desired_velocity.x, delta * movement_acceleration)
	velocity.z = move_toward(velocity.z, desired_velocity.z, delta * movement_acceleration)
	if animated_sprite.animation != &"hurt":
		_play_directional_animation(&"walk", &"walk_back")


func _stop_horizontal_motion() -> void:
	var braking_step := braking_acceleration * get_physics_process_delta_time()
	velocity.x = move_toward(velocity.x, 0.0, braking_step)
	velocity.z = move_toward(velocity.z, 0.0, braking_step)
	if not _attack_locked and animated_sprite.animation != &"hurt":
		_play_directional_animation(&"idle", &"idle_back")


func _play_directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> void:
	var target_animation := _directional_animation(front_animation, back_animation)
	if not _has_animation(target_animation):
		return
	if animated_sprite.animation == target_animation and animated_sprite.is_playing():
		return

	var previous_frame := animated_sprite.frame
	animated_sprite.play(target_animation)
	var frame_count := animated_sprite.sprite_frames.get_frame_count(target_animation)
	if frame_count > 0:
		animated_sprite.frame = mini(previous_frame, frame_count - 1)
	_apply_frame_ground_offset()


func _directional_animation(
	front_animation: StringName,
	back_animation: StringName
) -> StringName:
	if (
		_is_observer_behind_enemy()
		and _has_animation(back_animation)
	):
		return back_animation
	return front_animation


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

	# Oyuncu yaratığın baktığı yönün ters tarafındaysa arka kareleri göster.
	# Küçük eşik, tam yandan geçerken ön/arka görselinin titremesini engeller.
	return (
		_facing_direction.dot(direction_to_observer.normalized())
		< back_view_threshold
	)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity


func _should_use_dormant_mode() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	if _alerted or _attack_locked or _hurt_reaction_locked:
		return false
	if state != State.IDLE and state != State.PATROL:
		return false
	return (
		_horizontal_distance(global_position, _player.global_position)
		> dormant_distance
	)


func _enter_dormant_mode() -> void:
	if _dormant_active:
		return
	_dormant_active = true
	_player_visible = false
	_clear_path()
	velocity.x = 0.0
	velocity.z = 0.0
	_play_directional_animation(&"idle", &"idle_back")


func _exit_dormant_mode() -> void:
	if not _dormant_active:
		return
	_dormant_active = false
	_sight_check_remaining = 0.0
	_path_refresh_remaining = 0.0


func _apply_dormant_physics(delta: float) -> void:
	# Uzak ve alarma geçmemiş düşman zemindeyken CharacterBody çözümü, rota ve
	# algı çalıştırmaz. Havada doğmuşsa güvenli biçimde zemine oturmaya devam eder.
	if is_on_floor():
		velocity.y = floor_stick_velocity
		return
	_apply_gravity(delta)
	move_and_slide()


func _can_see_player() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var active_range := (
		_runtime_pursuit_range
		if _alerted
		else _runtime_detection_range
	)
	if _damage_reaction_remaining > 0.0:
		active_range = maxf(active_range, damage_reaction_range)
	var player_distance := _horizontal_distance(global_position, _player.global_position)
	if player_distance > active_range:
		return false
	if (not _alerted or state == State.SEARCH) and not _is_player_inside_initial_view():
		return false
	if not _check_line_of_sight():
		return false

	# Crouch only makes an unaware enemy less likely to notice the player.
	# Once the enemy is already alerted, crouching must not cancel its target
	# or cause an attack windup to play without actually firing.
	if not _alerted and _player.get("is_crouching") == true:
		if player_distance > crouch_guaranteed_detection_distance:
			return randf() <= crouch_detection_chance
	return true


func _is_player_inside_initial_view() -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	var player_direction := _player.global_position - global_position
	player_direction.y = 0.0
	if player_direction.length_squared() <= 0.001:
		return true
	player_direction = player_direction.normalized()
	var view_threshold := cos(deg_to_rad(initial_view_angle * 0.5))
	return _facing_direction.dot(player_direction) >= view_threshold


func _check_line_of_sight() -> bool:
	if _player == null or not is_instance_valid(_player):
		_last_visibility_ratio = 0.0
		return false
	var origin := global_position + Vector3.UP * sight_origin_height
	if _uses_ranged_tactics():
		_last_visibility_ratio = _ranged_visibility_ratio_from(origin)
		return _last_visibility_ratio > 0.0
	var has_contact := VexEnemyRuntimeUtils.has_visual_contact(
		get_world_3d(),
		origin,
		_player,
		sight_collision_mask,
		get_rid(),
		sight_target_height
	)
	_last_visibility_ratio = 1.0 if has_contact else 0.0
	return has_contact


func _get_crouched_sight_target_height() -> float:
	var shape_node := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null:
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			var top_height := shape_node.position.y + (capsule.height * 0.5)
			return clampf(top_height * 0.5, -0.2, sight_target_height)
	return 0.0


func _is_player_collider(collider: Node) -> bool:
	var current := collider
	var depth := 0
	while current != null and depth < 6:
		if current == _player:
			return true
		current = current.get_parent()
		depth += 1
	return false


func _uses_ranged_tactics() -> bool:
	return EnemyCombatProfiles.uses_multi_sample_visibility(combat_role)


func _uses_cover_reposition_tactics() -> bool:
	return EnemyCombatProfiles.uses_cover_reposition(
		combat_role,
		projectile_scene != null
	)


func _cover_visibility_threshold() -> float:
	return EnemyCombatProfiles.cover_visibility_threshold(combat_role)


func _damage_source_approach_position(source_position: Vector3) -> Vector3:
	# Oyuncu duvar kenarından ateş ettiğinde karakter merkezi fiziksel olarak
	# düşmanın sığamayacağı kadar duvara yakın olabilir. Tam merkeze rota vermek
	# yerine merminin geldiği açık koridora doğru küçük bir adım öne hedefle.
	var result := source_position
	result.y = global_position.y
	var toward_enemy := global_position - result
	toward_enemy.y = 0.0
	var distance := toward_enemy.length()
	if distance > 0.001:
		var offset := minf(damage_approach_offset, distance * 0.30)
		result += (toward_enemy / distance) * offset
	return result


func _ranged_visibility_ratio_from(observer_position: Vector3) -> float:
	if _player == null or not is_instance_valid(_player):
		return 0.0

	var target_center := _player.global_position + Vector3.UP * sight_target_height
	var half_height := maxf(sight_target_height, 0.45)
	var lateral_radius := 0.28
	var shape_node := _player.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape != null and not shape_node.disabled:
		target_center = shape_node.global_position
		var capsule := shape_node.shape as CapsuleShape3D
		if capsule != null:
			half_height = maxf(capsule.height * 0.5, capsule.radius)
			lateral_radius = capsule.radius
		else:
			var box := shape_node.shape as BoxShape3D
			if box != null:
				half_height = box.size.y * 0.5
				lateral_radius = minf(box.size.x, box.size.z) * 0.5

	var toward_target := _player.global_position - observer_position
	toward_target.y = 0.0
	if toward_target.length_squared() <= 0.0001:
		toward_target = Vector3.FORWARD
	else:
		toward_target = toward_target.normalized()
	var side := Vector3.UP.cross(toward_target).normalized()
	var vertical_span := clampf(half_height * 0.55, 0.20, 0.68)
	var lateral_span := clampf(lateral_radius * 0.82, 0.15, 0.38)
	var samples: Array[Vector3] = [
		target_center,
		target_center + Vector3.UP * vertical_span,
		target_center + side * lateral_span + Vector3.UP * (vertical_span * 0.08),
		target_center - side * lateral_span + Vector3.UP * (vertical_span * 0.08),
		target_center - Vector3.UP * (vertical_span * 0.45),
	]
	var visible_samples := 0
	var space_state := get_world_3d().direct_space_state
	for sample: Vector3 in samples:
		var query := PhysicsRayQueryParameters3D.create(
			observer_position,
			sample,
			sight_collision_mask,
			[get_rid()]
		)
		query.collide_with_areas = true
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var collider := result.get("collider") as Node
		if _is_player_collider(collider):
			visible_samples += 1
	return float(visible_samples) / float(samples.size())


func _reposition_for_clear_shot(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_stop_horizontal_motion()
		return

	if (
		not _has_ranged_reposition_target
		or _ranged_reposition_remaining <= 0.0
		or _has_reached_walkable_target(_ranged_reposition_target, waypoint_reach_distance)
	):
		_has_ranged_reposition_target = false
		var forward := _player.global_position - global_position
		forward.y = 0.0
		if forward.length_squared() <= 0.001:
			forward = _facing_direction
		else:
			forward = forward.normalized()
		var right := Vector3(-forward.z, 0.0, forward.x).normalized()
		var radius := EnemyCombatProfiles.cover_reposition_distance(combat_role)
		var offsets: Array[Vector3] = [
			right * radius,
			-right * radius,
			right * (radius * 1.35) + forward * (radius * 0.35),
			-right * (radius * 1.35) + forward * (radius * 0.35),
		]
		var best_score := -INF
		for offset: Vector3 in offsets:
			var candidate := global_position + offset
			candidate.y = global_position.y
			if not _is_walk_segment_clear(global_position, candidate):
				continue
			var ratio := _ranged_visibility_ratio_from(
				candidate + Vector3.UP * sight_origin_height
			)
			var score := ratio * 4.0 - offset.length() * 0.08
			if ratio >= _cover_visibility_threshold():
				score += 2.0
			if score > best_score:
				best_score = score
				_ranged_reposition_target = candidate
				_has_ranged_reposition_target = true
		_ranged_reposition_remaining = (
			ranged_cover_reposition_refresh
			if _has_ranged_reposition_target
			else 0.20
		)
		if _has_ranged_reposition_target:
			_clear_path()
			_path_refresh_remaining = 0.0

	if _has_ranged_reposition_target:
		_navigate_to(_ranged_reposition_target, delta)
	elif _has_last_seen_position:
		_navigate_to(_last_seen_position, delta)
	else:
		_stop_horizontal_motion()


func _attempt_attack() -> void:
	if _attack_locked:
		return
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	if _has_animation(&"attack"):
		animated_sprite.play(&"attack")
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.play()

	await get_tree().create_timer(_runtime_attack_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	if _player != null and is_instance_valid(_player):
		var still_in_range := (
			_horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight():
			_fire_projectile()
	_attack_windup_active = false
	if attack_approach_speed > 0.0 or attack_strafe_speed > 0.0:
		_play_directional_animation(&"walk", &"walk_back")
	else:
		_play_directional_animation(&"idle", &"idle_back")

	var remaining := maxf(
		0.0,
		_runtime_attack_cooldown - _runtime_attack_windup
	)
	await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _fire_projectile() -> void:
	if projectile_scene == null or _player == null or not is_instance_valid(_player):
		return
	var projectile := projectile_scene.instantiate() as Node3D
	if projectile == null:
		return
	get_tree().current_scene.add_child(projectile)
	var spawn_right := _facing_direction.cross(Vector3.UP)
	if spawn_right.length_squared() <= 0.001:
		spawn_right = Vector3.RIGHT
	else:
		spawn_right = spawn_right.normalized()
	var spawn_forward := _facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * projectile_spawn_height
		+ spawn_right * projectile_spawn_side_offset
		+ spawn_forward * projectile_spawn_forward_offset
	)
	var target_position := (
		_player.global_position
		+ Vector3.UP * projectile_target_height
	)
	var projectile_speed := maxf(float(projectile.get("speed")), 0.1)
	var target_velocity := Vector3.ZERO
	if _player is CharacterBody3D and projectile_lead_factor > 0.0:
		target_velocity = (_player as CharacterBody3D).velocity
		target_velocity.y = 0.0
	var travel_time := minf(
		_calculate_intercept_time(
			projectile.global_position,
			target_position,
			target_velocity,
			projectile_speed
		),
		projectile_max_lead_time
	)
	if projectile_lead_factor > 0.0:
		target_position += target_velocity * travel_time * projectile_lead_factor
	var shot_direction := (target_position - projectile.global_position).normalized()
	projectile.call("launch", shot_direction, self, _runtime_attack_damage)


func _calculate_intercept_time(
	projectile_position: Vector3,
	target_position: Vector3,
	target_velocity: Vector3,
	projectile_speed: float
) -> float:
	var displacement := target_position - projectile_position
	var fallback_time := displacement.length() / maxf(projectile_speed, 0.1)
	var quadratic_a := target_velocity.length_squared() - projectile_speed * projectile_speed
	var quadratic_b := 2.0 * displacement.dot(target_velocity)
	var quadratic_c := displacement.length_squared()
	if quadratic_c <= 0.0001:
		return 0.0
	if absf(quadratic_a) <= 0.0001:
		if absf(quadratic_b) <= 0.0001:
			return fallback_time
		var linear_time := -quadratic_c / quadratic_b
		return linear_time if linear_time > 0.0 else fallback_time

	var discriminant := (
		quadratic_b * quadratic_b
		- 4.0 * quadratic_a * quadratic_c
	)
	if discriminant < 0.0:
		return fallback_time
	var discriminant_root := sqrt(discriminant)
	var denominator := 2.0 * quadratic_a
	var first_time := (-quadratic_b - discriminant_root) / denominator
	var second_time := (-quadratic_b + discriminant_root) / denominator
	var intercept_time := -1.0
	if first_time > 0.0:
		intercept_time = first_time
	if second_time > 0.0 and (intercept_time < 0.0 or second_time < intercept_time):
		intercept_time = second_time
	return intercept_time if intercept_time > 0.0 else fallback_time


func _resume_animation_after_hurt() -> void:
	await get_tree().create_timer(hurt_reaction_duration).timeout
	_hurt_reaction_locked = false
	if not is_inside_tree() or state == State.DEAD:
		return
	# Bu arada saldırı başlamışsa attack animasyonunu ve saldırı zamanlayıcısını
	# kesinlikle bozma.
	if _attack_locked:
		return
	if _alerted:
		_play_directional_animation(&"walk", &"walk_back")
	else:
		_play_directional_animation(&"idle", &"idle_back")


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return VexEnemyRuntimeUtils.horizontal_distance(first, second)


func _clear_path() -> void:
	_current_path = PackedVector3Array()
	_path_index = 0
	_has_path_target = false


func _collision_floor_local_y() -> float:
	return VexEnemyRuntimeUtils.collision_floor_local_y(collision_shape)


func _snap_body_to_floor(max_correction: float) -> void:
	if not is_inside_tree() or collision_shape == null or collision_shape.shape == null:
		return
	var ray_origin := global_position + Vector3.UP * floor_snap_ray_start_height
	var ray_end := global_position + Vector3.DOWN * (max_correction + floor_snap_ray_extra_depth)
	var query := PhysicsRayQueryParameters3D.create(
		ray_origin,
		ray_end,
		floor_collision_mask,
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



func _finalize_death_visual() -> void:
	animated_sprite.visible = false
	animated_sprite.pause()
	if ground_shadow != null:
		ground_shadow.visible = false
	_show_burn_remains()


func _show_burn_remains() -> void:
	if _burn_remains != null and is_instance_valid(_burn_remains):
		return
	if burn_remains_scene == null:
		return
	var remains := burn_remains_scene.instantiate()
	if not (remains is Node3D):
		remains.queue_free()
		return
	(remains as Node3D).position = Vector3(0.0, _collision_floor_local_y(), 0.0)
	remains.set("scorch_size", burn_remains_scale * burn_remains_scale_multiplier)
	remains.set("smoke_enabled", burn_smoke_enabled)
	remains.set("smoke_duration", burn_smoke_duration)
	remains.set("smoke_alpha", burn_smoke_alpha)
	remains.set("scorch_tint", burn_scorch_tint)
	remains.set("ember_tint", burn_ember_tint)
	remains.set("ember_emission_energy", burn_ember_emission_energy)
	add_child(remains)
	_burn_remains = remains as Node3D


func _die() -> void:
	var death_animation := _directional_animation(&"death", &"death_back")
	state = State.DEAD
	velocity = Vector3.ZERO
	_snap_body_to_floor(floor_snap_max_correction)
	_attack_locked = true
	_attack_windup_active = false
	_clear_path()
	collision_shape.set_deferred("disabled", true)
	if death_audio.stream != null:
		death_audio.play()
	var death_duration := maxf(_get_animation_duration(death_animation), death_fall_time)
	if _has_animation(death_animation):
		animated_sprite.play(death_animation)
		_apply_frame_ground_offset()
	else:
		animated_sprite.pause()
	_place_corpse_on_floor(true)
	GameState.register_enemy_defeated(enemy_id)
	await get_tree().create_timer(death_duration).timeout
	if not is_inside_tree():
		return
	if _has_animation(death_animation):
		animated_sprite.pause()
		animated_sprite.frame = maxi(0, animated_sprite.sprite_frames.get_frame_count(death_animation) - 1)
	_apply_frame_ground_offset()
	await get_tree().create_timer(corpse_hold_duration).timeout
	if not is_inside_tree():
		return
	_finalize_death_visual()


func _restore_defeated_state() -> void:
	state = State.DEAD
	velocity = Vector3.ZERO
	_attack_locked = true
	_attack_windup_active = false
	_clear_path()
	collision_shape.set_deferred("disabled", true)
	var death_animation := _directional_animation(&"death", &"death_back")
	if not _has_animation(death_animation):
		animated_sprite.pause()
		_finalize_death_visual()
		return
	animated_sprite.animation = death_animation
	animated_sprite.frame = maxi(
		0,
		animated_sprite.sprite_frames.get_frame_count(death_animation) - 1
	)
	animated_sprite.pause()
	_finalize_death_visual()


func _get_animation_duration(animation_name: StringName) -> float:
	if animated_sprite.sprite_frames == null:
		return 0.0
	if not animated_sprite.sprite_frames.has_animation(animation_name):
		return 0.0
	var frame_count := animated_sprite.sprite_frames.get_frame_count(animation_name)
	if frame_count <= 0:
		return 0.0
	var speed := animated_sprite.sprite_frames.get_animation_speed(animation_name)
	if speed <= 0.001:
		return 0.0
	return float(frame_count) / speed


func _place_corpse_on_floor(animated: bool) -> void:
	var target_y := (
		back_corpse_visual_y
		if animated_sprite.animation == &"death_back"
		else corpse_visual_y
	)
	if not animated:
		animated_sprite.position.y = target_y
		return

	var fall_tween := create_tween()
	fall_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fall_tween.tween_property(
		animated_sprite,
		"position:y",
		target_y,
		death_fall_time
	)
