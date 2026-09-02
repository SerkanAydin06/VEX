class_name VexVenomMarshall
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

@export_category("10 - Venom Marshall Alan Desteği")
## Zeminde güçlendirme alanı kuran ikinci skill mermisidir.
@export var buff_projectile_scene: PackedScene
## İkinci skill için değerlendirilecek en uzak müttefik mesafesidir.
@export_range(2.0, 30.0, 0.5) var buff_cast_range := 15.0
## Müttefik kümelerini puanlarken kullanılan alan yarıçapıdır.
@export_range(1.0, 10.0, 0.1) var buff_cluster_radius := 5.6
## İki alan skill'i arasındaki temel bekleme süresidir.
@export_range(2.0, 30.0, 0.5) var buff_cooldown := 11.5
## Alan mermisi çıkmadan önceki 2nd_attack hazırlık süresidir.
@export_range(0.05, 3.0, 0.05) var buff_windup := 0.65
## Alan atışından sonra normal state machine'e dönüş süresidir.
@export_range(0.0, 4.0, 0.05) var buff_recovery := 0.80
## Buff mermisinin Venom Marshall gövdesinden çıkış yüksekliğidir.
@export_range(0.0, 3.0, 0.05) var buff_spawn_height := 1.05
## Buff mermisinin gövdeden ileri çıkış mesafesidir.
@export_range(0.0, 2.0, 0.05) var buff_spawn_forward_offset := 0.30
## Mevcut buff'ın bitmesine bu kadar süre kaldığında alan yenilenebilir.
@export_range(0.0, 3.0, 0.1) var buff_refresh_window := 1.2
## 2nd_attack karelerinin zemin hizalama düzeltmeleridir.
@export var second_attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

var _buff_cooldown_remaining := 0.0


func get_behavior_family() -> StringName:
	return &"support_ranged"


func _physics_process(delta: float) -> void:
	_buff_cooldown_remaining = maxf(0.0, _buff_cooldown_remaining - delta)
	super._physics_process(delta)


func _attempt_attack() -> void:
	if _attack_locked:
		return
	if _buff_cooldown_remaining <= 0.0 and buff_projectile_scene != null:
		var buff_target := _select_buff_target()
		if buff_target != null:
			_begin_buff_attack(buff_target.global_position)
			return
	super._attempt_attack()


func _select_buff_target() -> Node3D:
	var candidates: Array[Node3D] = []
	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not (node is Node3D):
			continue
		var ally := node as Node3D
		if not _is_buff_candidate(ally):
			continue
		if _horizontal_distance(global_position, ally.global_position) > buff_cast_range:
			continue
		candidates.append(ally)
	var best_target: Node3D = null
	var best_score := -INF
	for candidate in candidates:
		var score := _buff_cluster_score(candidate.global_position, candidates)
		if score > best_score:
			best_score = score
			best_target = candidate
	return best_target


func _is_buff_candidate(ally: Node3D) -> bool:
	if not ally.has_method("take_damage"):
		return false
	var current_health := int(ally.get("health"))
	var maximum := int(ally.get("_runtime_maximum_health"))
	if current_health <= 0 or maximum <= 0:
		return false
	if current_health < maximum:
		return true
	var status := ally.get_node_or_null("VenomMarshallBuffStatus")
	if status == null:
		return true
	return float(status.call("get_remaining_time")) <= buff_refresh_window


func _buff_cluster_score(origin: Vector3, candidates: Array[Node3D]) -> float:
	var score := 0.0
	for ally in candidates:
		if _horizontal_distance(origin, ally.global_position) > buff_cluster_radius:
			continue
		var maximum := maxi(1, int(ally.get("_runtime_maximum_health")))
		var current := clampi(int(ally.get("health")), 0, maximum)
		var missing_ratio := 1.0 - float(current) / float(maximum)
		score += 1.0 + missing_ratio * 2.0
		if ally.get_node_or_null("VenomMarshallBuffStatus") == null:
			score += 0.65
	return score


func _begin_buff_attack(target_position: Vector3) -> void:
	var combat_generation := _combat_interrupt_generation
	_attack_locked = true
	_attack_windup_active = true
	_stop_horizontal_motion()
	_face_toward_position(target_position)
	animated_sprite.flip_h = false
	if _has_animation(&"2nd_attack"):
		animated_sprite.play(&"2nd_attack")
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.stop()
		attack_audio.play()
	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var runtime_windup := maxf(0.05, buff_windup * windup_scale)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_fire_buff_projectile(target_position)
	_buff_cooldown_remaining = maxf(runtime_windup, buff_cooldown * cooldown_scale)
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")
	if buff_recovery > 0.0:
		await get_tree().create_timer(buff_recovery).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _fire_buff_projectile(target_position: Vector3) -> void:
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		return
	var projectile := EnemyProjectilePool.acquire(buff_projectile_scene, projectile_parent) as Node3D
	if projectile == null:
		return
	var spawn_forward := _facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * buff_spawn_height
		+ spawn_forward * buff_spawn_forward_offset
	)
	projectile.call("launch_to", target_position, self)


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"2nd_attack":
		return second_attack_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
