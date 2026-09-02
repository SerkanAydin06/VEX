class_name VexVenomMarshall
extends "res://scripts/actors/enemy_combatant_performance_base.gd"

const EnemyProjectilePool = preload("res://scripts/actors/enemy_projectile_pool.gd")

@export_category("Venom Marshall - Destek Yeteneği")
## Zemine gidip çevredeki canlı düşmanları güçlendiren ikinci mermi sahnesidir.
@export var buff_projectile_scene: PackedScene
## Marshall'ın destek hedefi aradığı yatay yarıçaptır.
@export_range(4.0, 30.0, 0.5) var support_search_radius := 16.0
## Normal şartlarda buff atışı için gereken en az canlı müttefik sayısıdır.
@export_range(1, 8, 1) var support_minimum_allies := 2
## Tek bir müttefik bu can oranının altındaysa Marshall acil destek atışı yapabilir.
@export_range(0.1, 1.0, 0.05) var emergency_heal_ratio := 0.65
## İkinci yeteneğin tekrar kullanılabilmesi için temel bekleme süresidir.
@export_range(2.0, 30.0, 0.1) var buff_skill_cooldown := 11.0
## İkinci saldırı animasyonunun mermi çıkmadan önceki hazırlık süresidir.
@export_range(0.05, 3.0, 0.05) var buff_skill_windup := 0.70
## Buff atışından sonra normal saldırıya dönmeden önceki toplam kilit süresidir.
@export_range(0.2, 5.0, 0.05) var buff_skill_recovery := 1.60
## İkinci merminin gövdeden çıkış yüksekliğidir.
@export_range(0.0, 3.0, 0.05) var buff_projectile_spawn_height := 1.05
## İkinci merminin yaratığın baktığı yöndeki çıkış ofsetidir.
@export_range(-1.0, 2.0, 0.05) var buff_projectile_spawn_forward_offset := 0.25
## İkinci saldırı karelerinin zemin hizası düzeltmeleridir.
@export var second_attack_frame_y_offsets := PackedFloat32Array([0.0, 0.0, 0.0, 0.0])

var _buff_ready_at_msec := 0


func _attempt_attack() -> void:
	if _attack_locked:
		return
	var combat_generation := _combat_interrupt_generation
	var support_plan := _build_support_plan()
	var use_buff := (
		buff_projectile_scene != null
		and Time.get_ticks_msec() >= _buff_ready_at_msec
		and bool(support_plan.get("valid", false))
	)

	_attack_locked = true
	_attack_windup_active = true
	_attack_strafe_direction *= -1.0
	var attack_animation: StringName = &"2nd_attack" if use_buff else &"attack"
	if _has_animation(attack_animation):
		animated_sprite.play(attack_animation)
		_apply_frame_ground_offset()
	if attack_audio.stream != null:
		attack_audio.play()

	var windup_scale := _scene_difficulty_multiplier(difficulty_windup_multipliers)
	var cooldown_scale := _scene_difficulty_multiplier(difficulty_cooldown_multipliers)
	var runtime_windup := (
		maxf(0.01, buff_skill_windup * windup_scale)
		if use_buff
		else _runtime_attack_windup
	)
	await get_tree().create_timer(runtime_windup).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return

	if use_buff:
		_fire_buff_projectile(support_plan.get("position", global_position) as Vector3)
		var runtime_buff_cooldown := maxf(0.1, buff_skill_cooldown * cooldown_scale)
		_buff_ready_at_msec = Time.get_ticks_msec() + int(round(runtime_buff_cooldown * 1000.0))
	elif _player != null and is_instance_valid(_player):
		var still_in_range := (
			_horizontal_distance(global_position, _player.global_position)
			<= attack_range + attack_range_tolerance
		)
		if still_in_range and _check_line_of_sight():
			super._fire_projectile()

	_attack_windup_active = false
	if attack_approach_speed > 0.0 or attack_strafe_speed > 0.0:
		_play_directional_animation(&"walk", &"walk_back")
	else:
		_play_directional_animation(&"idle", &"idle_back")

	var total_lock_time := (
		maxf(runtime_windup, buff_skill_recovery * cooldown_scale)
		if use_buff
		else _runtime_attack_cooldown
	)
	var remaining := maxf(0.0, total_lock_time - runtime_windup)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if not is_inside_tree() or state == State.DEAD or combat_generation != _combat_interrupt_generation:
		return
	_attack_locked = false
	_attack_windup_active = false
	_play_directional_animation(&"idle", &"idle_back")


func _build_support_plan() -> Dictionary:
	var allies: Array[Node3D] = []
	var emergency_count := 0
	var weighted_position := Vector3.ZERO
	var total_weight := 0.0

	for node: Node in get_tree().get_nodes_in_group("enemy"):
		if node == self or not (node is Node3D):
			continue
		var ally := node as Node3D
		if not _is_living_enemy(ally):
			continue
		if _horizontal_distance(global_position, ally.global_position) > support_search_radius:
			continue
		var health_ratio := _enemy_health_ratio(ally)
		var is_emergency := health_ratio <= emergency_heal_ratio
		var already_buffed := ally.has_meta("vex_venom_marshall_buffed")
		if already_buffed and not is_emergency:
			continue
		allies.append(ally)
		if is_emergency:
			emergency_count += 1
		var weight := 2.0 if is_emergency else 1.0
		weighted_position += ally.global_position * weight
		total_weight += weight

	var valid := (
		allies.size() >= support_minimum_allies
		or emergency_count > 0
	)
	if not valid or total_weight <= 0.0:
		return {"valid": false}
	var target_position := weighted_position / total_weight
	target_position.y = global_position.y
	return {
		"valid": true,
		"position": target_position,
		"ally_count": allies.size(),
		"emergency_count": emergency_count,
	}


func _fire_buff_projectile(target_position: Vector3) -> void:
	if buff_projectile_scene == null:
		return
	var projectile_parent := get_tree().current_scene
	if projectile_parent == null:
		return
	var projectile := EnemyProjectilePool.acquire(
		buff_projectile_scene,
		projectile_parent
	) as Node3D
	if projectile == null:
		return

	var spawn_forward := _facing_direction
	if spawn_forward.length_squared() <= 0.001:
		spawn_forward = -global_transform.basis.z
	else:
		spawn_forward = spawn_forward.normalized()
	projectile.global_position = (
		global_position
		+ Vector3.UP * buff_projectile_spawn_height
		+ spawn_forward * buff_projectile_spawn_forward_offset
	)
	if projectile.has_method("launch_toward"):
		projectile.call("launch_toward", target_position, self)


func _is_living_enemy(enemy: Node3D) -> bool:
	if enemy == null or not is_instance_valid(enemy) or enemy.is_queued_for_deletion():
		return false
	if not enemy.is_in_group("enemy"):
		return false
	if _has_property(enemy, &"_dead") and bool(enemy.get("_dead")):
		return false
	if _has_property(enemy, &"state") and int(enemy.get("state")) == 6:
		return false
	if _has_property(enemy, &"health") and int(enemy.get("health")) <= 0:
		return false
	return true


func _enemy_health_ratio(enemy: Node) -> float:
	if not _has_property(enemy, &"health"):
		return 1.0
	var maximum := 1
	if _has_property(enemy, &"_runtime_maximum_health"):
		maximum = maxi(1, int(enemy.get("_runtime_maximum_health")))
	elif _has_property(enemy, &"maximum_health"):
		maximum = maxi(1, int(enemy.get("maximum_health")))
	return clampf(float(enemy.get("health")) / float(maximum), 0.0, 1.0)


func _has_property(target: Object, property_name: StringName) -> bool:
	for property: Dictionary in target.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return true
	return false


func _frame_offsets_for_animation(animation_name: StringName) -> PackedFloat32Array:
	if animation_name == &"2nd_attack":
		return second_attack_frame_y_offsets
	return super._frame_offsets_for_animation(animation_name)
