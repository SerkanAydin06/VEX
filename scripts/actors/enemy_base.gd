class_name VexEnemyBase
extends CharacterBody3D

# Yaratık adı taşımayan en alt seviye sözleşme.
# Kimlik/zorluk verileri ile her davranış ailesinin kullandığı saf yardımcılar
# burada tutulur. Hareket state machine'i bu sınıfta bulunmaz.
const EnemyCombatProfiles = preload("res://scripts/actors/enemy_combat_profiles.gd")
const EnemyNavigationRuntime = preload("res://scripts/actors/enemy_navigation_runtime.gd")
const EnemyCombatRuntime = preload("res://scripts/actors/enemy_combat_runtime.gd")
const EnemyPerceptionRuntime = preload("res://scripts/actors/enemy_perception_runtime.gd")

@export_category("01A - Ortak Kimlik ve Zorluk")
## Kayıt ve yenilgi takibinde kullanılan benzersiz yaratık kimliğidir.
@export var enemy_id: StringName = &"enemy"
## Yaratığın doğabileceği en düşük zorluk seviyesidir; 0 tüm seviyelerdir.
@export_range(0, 3, 1) var spawn_min_difficulty := 0
## Açıksa sahnedeki zorluk çarpanları cana, hasara, hıza, algılamaya ve saldırı sürelerine uygulanır.
@export var apply_difficulty_scaling := true

@export_category("01B - Zorluk Çarpanları (Sahne)")
## zorluk can çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_health_multipliers := PackedFloat32Array([0.75, 1.0, 1.20, 1.45])
## zorluk hasar çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_damage_multipliers := PackedFloat32Array([0.65, 1.0, 1.25, 1.55])
## zorluk hız çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_speed_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.15])
## zorluk algılama çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_detection_multipliers := PackedFloat32Array([0.90, 1.0, 1.08, 1.20])
## zorluk bekleme çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_cooldown_multipliers := PackedFloat32Array([1.25, 1.0, 0.85, 0.70])
## zorluk hazırlık çarpanları; dizi sırası Kolay, Normal, Zor ve Kabus seviyeleridir.
@export var difficulty_windup_multipliers := PackedFloat32Array([1.20, 1.0, 0.90, 0.75])

# Sahne bazında override edilmeyen ortak teknik AI geometrisi/maskeleri.
# Bunlar gameplay tuning Inspector alanı değildir; iki davranış ailesi tek kaynağı kullanır.
# zemin çarpışma katmanları kontrolünde dikkate alınacak fizik katmanlarıdır.
var floor_collision_mask := 1
# Yaratığın zemin oturtma en yüksek düzeltme mesafesi ayarını belirler.
var floor_snap_max_correction := 2.0
# zemin oturtma ışın başlangıç yükseklik değeridir (metre).
var floor_snap_ray_start_height := 0.5
# Yaratığın zemin oturtma ışın ek derinlik ayarını belirler.
var floor_snap_ray_extra_depth := 2.0
# ses engeli çarpışma katmanları kontrolünde dikkate alınacak fizik katmanlarıdır.
var acoustic_collision_mask := 1
# ses engeli yoklama yükseklik değeridir (metre).
var acoustic_probe_height := 0.8
# görünürlük dikey örnekleme açıklığı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var visibility_vertical_span_scale := 0.55
# Yaratığın görünürlük dikey örnekleme açıklığı en düşük ayarını belirler.
var visibility_vertical_span_min := 0.20
# Yaratığın görünürlük dikey örnekleme açıklığı en yüksek ayarını belirler.
var visibility_vertical_span_max := 0.68
# görünürlük yan örnekleme açıklığı çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var visibility_lateral_span_scale := 0.82
# Yaratığın görünürlük yan örnekleme açıklığı en düşük ayarını belirler.
var visibility_lateral_span_min := 0.15
# Yaratığın görünürlük yan örnekleme açıklığı en yüksek ayarını belirler.
var visibility_lateral_span_max := 0.38
# görünürlük omuz yükseklik oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var visibility_shoulder_height_ratio := 0.08
# görünürlük alt gövde oran ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var visibility_lower_body_ratio := 0.45
# çömelmiş hedef yükseklik çarpan ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var crouched_target_height_scale := 0.50
# çömelmiş hedef en düşük yükseklik değeridir (metre).
var crouched_target_min_height := -0.20
# arama yoklama çapraz ağırlık ayarıdır; ilgili AI kararındaki etkinin oranını veya ağırlığını belirler.
var search_probe_diagonal_weight := 0.85

# Combatant ve Lunge sahne köklerinin ortak zorunlu node sözleşmesi.
# Node adları iki davranış ailesinde de aynıdır; tek kaynaktan çözülür.
@onready var animated_sprite: AnimatedSprite3D = $AnimatedSprite3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var attack_audio: AudioStreamPlayer3D = $AttackAudio
@onready var hurt_audio: AudioStreamPlayer3D = $HurtAudio
@onready var death_audio: AudioStreamPlayer3D = $DeathAudio
@onready var ground_shadow: Sprite3D = get_node_or_null("GroundShadow") as Sprite3D

# Combatant ve Lunge ailelerinin birebir ortak runtime state'i burada tek kez tanımlanır.
# Aileye özgü state-machine alanları alt sınıflarda kalır.
# Bu private alanların bir bölümü yalnız alt sınıflar tarafından tüketilir. GDScript'in
# UNUSED_PRIVATE_CLASS_VARIABLE analizi inherited kullanımı saymadığı için uyarıyı yalnız
# bu bilinçli ortak state bölgesinde bastırıyoruz.
@warning_ignore_start("unused_private_class_variable")
var health := 0
var _spawn_position := Vector3.ZERO
var _facing_direction := Vector3.FORWARD
var _attack_locked := false
var _gravity := 20.0
var _player: Node3D = null
var _sight_check_remaining := 0.0
var _last_seen_position := Vector3.ZERO
var _search_remaining := 0.0
var _search_probe_index := 0
var _search_probe_target := Vector3.ZERO
var _has_search_probe := false
var _damage_reaction_remaining := 0.0
var _forced_damage_target := Vector3.ZERO
var _has_forced_damage_target := false
var _forced_damage_best_distance := INF
var _forced_damage_stall_remaining := 0.0
var _forced_damage_commit_remaining := 0.0
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
@warning_ignore_restore("unused_private_class_variable")

var _damage_shake_remaining := 0.0
var _damage_shake_duration := 0.0
var _damage_shake_amount_pixels := 0.0
var _damage_shake_phase := 0.0
var _damage_shake_origin_offset := Vector2.ZERO
var _damage_shake_active := false


func get_behavior_family() -> StringName:
	return &"base"


func _scene_difficulty_multiplier(values: PackedFloat32Array) -> float:
	return VexEnemyRuntimeUtils.difficulty_multiplier(values, GameState.active_difficulty)


func _configure_common_runtime_stats(
	maximum_health_value: int,
	attack_damage_value: int,
	move_speed_value: float,
	chase_speed_value: float,
	detection_range_value: float,
	pursuit_range_value: float,
	attack_cooldown_value: float,
	attack_windup_value: float
) -> float:
	_runtime_maximum_health = maximum_health_value
	_runtime_attack_damage = attack_damage_value
	_runtime_move_speed = move_speed_value
	_runtime_chase_speed = chase_speed_value
	_runtime_detection_range = detection_range_value
	_runtime_pursuit_range = pursuit_range_value
	_runtime_attack_cooldown = attack_cooldown_value
	_runtime_attack_windup = attack_windup_value
	if not apply_difficulty_scaling:
		return 1.0

	var health_scale := _scene_difficulty_multiplier(difficulty_health_multipliers)
	var damage_scale := _scene_difficulty_multiplier(difficulty_damage_multipliers)
	var speed_scale := _scene_difficulty_multiplier(difficulty_speed_multipliers)
	var detection_scale := _scene_difficulty_multiplier(difficulty_detection_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	_runtime_maximum_health = maxi(1, int(round(float(maximum_health_value) * health_scale)))
	_runtime_attack_damage = maxi(1, int(round(float(attack_damage_value) * damage_scale)))
	_runtime_move_speed = maxf(0.0, move_speed_value * speed_scale)
	_runtime_chase_speed = maxf(0.0, chase_speed_value * speed_scale)
	_runtime_detection_range = maxf(0.0, detection_range_value * detection_scale)
	_runtime_pursuit_range = maxf(0.0, pursuit_range_value * detection_scale)
	_runtime_attack_cooldown = maxf(0.01, attack_cooldown_value * cooldown_scale)
	_runtime_attack_windup = maxf(0.0, attack_windup_value * windup_scale)
	return speed_scale


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	return VexEnemyRuntimeUtils.horizontal_distance(first, second)


func _reset_search_probe() -> void:
	_search_probe_index = 0
	_search_probe_target = Vector3.ZERO
	_has_search_probe = false


func _apply_gravity(delta: float, floor_stick_velocity_value: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta
	else:
		velocity.y = floor_stick_velocity_value


func _apply_dormant_physics(
	delta: float,
	floor_stick_velocity_value: float
) -> void:
	# Uzak ve alarma geçmemiş düşman zemindeyken CharacterBody çözümü, rota ve
	# algı çalıştırmaz. Havada doğmuşsa güvenli biçimde zemine oturmaya devam eder.
	if is_on_floor():
		velocity.y = floor_stick_velocity_value
		return
	_apply_gravity(delta, floor_stick_velocity_value)
	move_and_slide()


func _collision_floor_local_y() -> float:
	return VexEnemyRuntimeUtils.collision_floor_local_y(collision_shape)


func _snap_body_to_floor(
	max_correction: float,
	floor_stick_velocity_value: float
) -> void:
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
	velocity.y = floor_stick_velocity_value


func _is_player_inside_initial_view(initial_view_angle_value: float) -> bool:
	if _player == null or not is_instance_valid(_player):
		return false
	return EnemyPerceptionRuntime.is_player_inside_initial_view(
		global_position,
		_facing_direction,
		_player.global_position,
		initial_view_angle_value
	)


func _is_observer_behind_enemy(back_view_threshold_value: float) -> bool:
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
		< back_view_threshold_value
	)


func _trigger_damage_shake(
	visual: SpriteBase3D,
	duration: float,
	amount_pixels: float
) -> void:
	if visual == null or not is_instance_valid(visual):
		return
	if duration <= 0.0 or amount_pixels <= 0.0:
		_clear_damage_shake(visual)
		return
	if not _damage_shake_active:
		_damage_shake_origin_offset = visual.offset
	_damage_shake_active = true
	_damage_shake_duration = duration
	_damage_shake_remaining = duration
	_damage_shake_amount_pixels = amount_pixels


func _update_damage_shake(
	visual: SpriteBase3D,
	delta: float,
	frequency: float
) -> void:
	if not _damage_shake_active:
		return
	if visual == null or not is_instance_valid(visual):
		_damage_shake_active = false
		return
	_damage_shake_remaining = maxf(0.0, _damage_shake_remaining - delta)
	if _damage_shake_remaining <= 0.0:
		_clear_damage_shake(visual)
		return
	_damage_shake_phase += delta * maxf(frequency, 1.0) * TAU
	var envelope := _damage_shake_remaining / maxf(_damage_shake_duration, 0.001)
	var shake := Vector2(
		sin(_damage_shake_phase),
		sin(_damage_shake_phase * 1.73 + 0.65) * 0.28
	)
	visual.offset = (
		_damage_shake_origin_offset
		+ shake * _damage_shake_amount_pixels * envelope
	)


func _clear_damage_shake(visual: SpriteBase3D) -> void:
	if _damage_shake_active and visual != null and is_instance_valid(visual):
		visual.offset = _damage_shake_origin_offset
	_damage_shake_remaining = 0.0
	_damage_shake_duration = 0.0
	_damage_shake_amount_pixels = 0.0
	_damage_shake_phase = 0.0
	_damage_shake_active = false
