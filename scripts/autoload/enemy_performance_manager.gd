extends Node

# Görsel çözünürlüğü veya ekrandaki animasyon hızını düşürmeden kalabalık savaş
# yükünü dağıtır. Yakın ve ekranda görünen yaratıklar tam kalite/tick davranışını
# korur; orta/uzak yaratıkların yalnız pahalı algı ve rota yenilemeleri seyrekleşir.
const UPDATE_INTERVAL := 0.10
const NEAR_DISTANCE := 14.0
const MID_DISTANCE := 28.0
const OFFSCREEN_ANIMATION_DISTANCE := 18.0
const SCREEN_MARGIN_PIXELS := 160.0
const CROWD_START := 16.0
const CROWD_FULL := 48.0
const MAX_DORMANT_REDUCTION := 8.0
const DORMANT_DETECTION_MARGIN := 6.0

var _update_remaining := 0.0
var _profiles: Dictionary = {}


func _process(delta: float) -> void:
	_update_remaining = maxf(0.0, _update_remaining - delta)
	if _update_remaining > 0.0:
		return
	_update_remaining = UPDATE_INTERVAL
	_update_enemy_lod()


func _update_enemy_lod() -> void:
	var player := GameState.player as Node3D
	if player == null or not is_instance_valid(player):
		return
	var enemies := get_tree().get_nodes_in_group("enemy")
	if enemies.is_empty():
		return

	var living_count := 0
	for node: Node in enemies:
		if node is Node3D and not _is_enemy_dead(node as Node3D):
			living_count += 1
	var crowd_factor := clampf(
		(float(living_count) - CROWD_START) / maxf(CROWD_FULL - CROWD_START, 1.0),
		0.0,
		1.0
	)
	var camera := get_viewport().get_camera_3d()
	var viewport_rect := get_viewport().get_visible_rect()

	for node: Node in enemies:
		if not (node is Node3D):
			continue
		var enemy := node as Node3D
		if not is_instance_valid(enemy):
			continue
		var family := _enemy_family(enemy)
		if family.is_empty():
			continue
		var profile := _ensure_profile(enemy, family)
		if _is_enemy_dead(enemy):
			_restore_enemy(enemy, profile)
			continue

		var distance := _horizontal_distance(enemy.global_position, player.global_position)
		_apply_runtime_tuning(enemy, family, profile, distance, crowd_factor)
		_apply_physics_sleep(enemy, profile, distance)
		_apply_visual_lod(enemy, profile, distance, camera, viewport_rect)


func _enemy_family(enemy: Node3D) -> StringName:
	if not enemy.has_method("get_behavior_family"):
		return &""
	return StringName(enemy.call("get_behavior_family"))


func _ensure_profile(enemy: Node3D, family: StringName) -> Dictionary:
	var key := enemy.get_instance_id()
	if _profiles.has(key):
		return _profiles[key] as Dictionary
	var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	var profile := {
		"family": family,
		"near_sight_interval": float(enemy.get("near_sight_interval")),
		"path_refresh_interval": float(enemy.get("path_refresh_interval")),
		"dormant_distance": float(enemy.get("dormant_distance")),
		"visual_speed_scale": sprite.speed_scale if sprite != null else 1.0,
	}
	if family == &"lunge":
		profile["far_sight_interval"] = float(enemy.get("far_sight_interval"))
	else:
		profile["medium_sight_interval"] = float(enemy.get("medium_sight_interval"))
		profile["distant_sight_interval"] = float(enemy.get("distant_sight_interval"))
		profile["idle_far_sight_interval"] = float(enemy.get("idle_far_sight_interval"))
		profile["chase_path_refresh_interval"] = float(enemy.get("chase_path_refresh_interval"))
		profile["distant_path_refresh_interval"] = float(enemy.get("distant_path_refresh_interval"))
		profile["ranged_cover_reposition_refresh"] = float(enemy.get("ranged_cover_reposition_refresh"))
		profile["cover_failed_retry_interval"] = float(enemy.get("cover_failed_retry_interval"))
	_profiles[key] = profile
	return profile


func _apply_runtime_tuning(
	enemy: Node3D,
	family: StringName,
	profile: Dictionary,
	distance: float,
	crowd_factor: float
) -> void:
	var sight_multiplier := lerpf(1.0, 1.20, crowd_factor)
	var path_multiplier := lerpf(1.0, 1.35, crowd_factor)
	var cover_multiplier := lerpf(1.0, 1.30, crowd_factor)
	if distance > MID_DISTANCE:
		sight_multiplier = lerpf(2.0, 3.20, crowd_factor)
		path_multiplier = lerpf(1.80, 3.20, crowd_factor)
		cover_multiplier = lerpf(1.50, 2.80, crowd_factor)
	elif distance > NEAR_DISTANCE:
		sight_multiplier = lerpf(1.35, 2.0, crowd_factor)
		path_multiplier = lerpf(1.35, 2.20, crowd_factor)
		cover_multiplier = lerpf(1.25, 2.0, crowd_factor)

	enemy.set(
		"near_sight_interval",
		clampf(float(profile["near_sight_interval"]) * sight_multiplier, 0.02, 1.0)
	)
	enemy.set(
		"path_refresh_interval",
		clampf(float(profile["path_refresh_interval"]) * path_multiplier, 0.10, 2.0)
	)

	if family == &"lunge":
		enemy.set(
			"far_sight_interval",
			clampf(float(profile["far_sight_interval"]) * sight_multiplier, 0.05, 1.0)
		)
	else:
		enemy.set(
			"medium_sight_interval",
			clampf(float(profile["medium_sight_interval"]) * sight_multiplier, 0.02, 1.0)
		)
		enemy.set(
			"distant_sight_interval",
			clampf(float(profile["distant_sight_interval"]) * sight_multiplier, 0.10, 1.0)
		)
		enemy.set(
			"idle_far_sight_interval",
			clampf(float(profile["idle_far_sight_interval"]) * sight_multiplier, 0.10, 1.0)
		)
		enemy.set(
			"chase_path_refresh_interval",
			clampf(float(profile["chase_path_refresh_interval"]) * path_multiplier, 0.10, 2.0)
		)
		enemy.set(
			"distant_path_refresh_interval",
			clampf(float(profile["distant_path_refresh_interval"]) * path_multiplier, 0.30, 2.0)
		)
		enemy.set(
			"ranged_cover_reposition_refresh",
			clampf(float(profile["ranged_cover_reposition_refresh"]) * cover_multiplier, 0.15, 2.0)
		)
		enemy.set(
			"cover_failed_retry_interval",
			clampf(float(profile["cover_failed_retry_interval"]) * cover_multiplier, 0.05, 2.0)
		)

	var authored_dormant := float(profile["dormant_distance"])
	var runtime_detection := float(enemy.get("_runtime_detection_range"))
	if runtime_detection <= 0.0:
		runtime_detection = float(enemy.get("detection_range"))
	var effective_dormant := maxf(
		authored_dormant - MAX_DORMANT_REDUCTION * crowd_factor,
		runtime_detection + DORMANT_DETECTION_MARGIN
	)
	enemy.set("dormant_distance", effective_dormant)


func _apply_physics_sleep(enemy: Node3D, _profile: Dictionary, distance: float) -> void:
	var pursuing := false
	if enemy.has_method("is_pursuing_player"):
		pursuing = bool(enemy.call("is_pursuing_player"))
	var effective_dormant := float(enemy.get("dormant_distance"))
	var should_sleep := not pursuing and distance > effective_dormant
	var slept_by_manager := bool(enemy.get_meta("vex_perf_physics_slept", false))
	if should_sleep and not slept_by_manager:
		enemy.set_physics_process(false)
		enemy.set_meta("vex_perf_physics_slept", true)
	elif not should_sleep and slept_by_manager:
		enemy.set_physics_process(true)
		enemy.set_meta("vex_perf_physics_slept", false)


func _apply_visual_lod(
	enemy: Node3D,
	profile: Dictionary,
	distance: float,
	camera: Camera3D,
	viewport_rect: Rect2
) -> void:
	var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite == null:
		return
	var screen_relevant := (
		distance <= OFFSCREEN_ANIMATION_DISTANCE
		or _is_enemy_near_screen(enemy, camera, viewport_rect)
	)
	var paused_by_manager := bool(enemy.get_meta("vex_perf_visual_paused", false))
	if not screen_relevant:
		if not paused_by_manager:
			enemy.set_meta("vex_perf_visual_paused", true)
		sprite.speed_scale = 0.0
	elif paused_by_manager:
		sprite.speed_scale = float(profile["visual_speed_scale"])
		enemy.set_meta("vex_perf_visual_paused", false)


func _is_enemy_near_screen(enemy: Node3D, camera: Camera3D, viewport_rect: Rect2) -> bool:
	if camera == null or not is_instance_valid(camera):
		return true
	var sample_position := enemy.global_position + Vector3.UP * 0.8
	if camera.is_position_behind(sample_position):
		return false
	var screen_position := camera.unproject_position(sample_position)
	return viewport_rect.grow(SCREEN_MARGIN_PIXELS).has_point(screen_position)


func _restore_enemy(enemy: Node3D, profile: Dictionary) -> void:
	if bool(enemy.get_meta("vex_perf_physics_slept", false)):
		enemy.set_physics_process(true)
		enemy.set_meta("vex_perf_physics_slept", false)
	var sprite := enemy.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite != null and bool(enemy.get_meta("vex_perf_visual_paused", false)):
		sprite.speed_scale = float(profile["visual_speed_scale"])
		enemy.set_meta("vex_perf_visual_paused", false)

	enemy.set("near_sight_interval", float(profile["near_sight_interval"]))
	enemy.set("path_refresh_interval", float(profile["path_refresh_interval"]))
	enemy.set("dormant_distance", float(profile["dormant_distance"]))
	var family := StringName(profile["family"])
	if family == &"lunge":
		enemy.set("far_sight_interval", float(profile["far_sight_interval"]))
	else:
		enemy.set("medium_sight_interval", float(profile["medium_sight_interval"]))
		enemy.set("distant_sight_interval", float(profile["distant_sight_interval"]))
		enemy.set("idle_far_sight_interval", float(profile["idle_far_sight_interval"]))
		enemy.set("chase_path_refresh_interval", float(profile["chase_path_refresh_interval"]))
		enemy.set("distant_path_refresh_interval", float(profile["distant_path_refresh_interval"]))
		enemy.set("ranged_cover_reposition_refresh", float(profile["ranged_cover_reposition_refresh"]))
		enemy.set("cover_failed_retry_interval", float(profile["cover_failed_retry_interval"]))


func _is_enemy_dead(enemy: Node3D) -> bool:
	var family := _enemy_family(enemy)
	if family == &"lunge":
		return bool(enemy.get("_dead"))
	if family == &"combatant" or family == &"hybrid":
		return int(enemy.get("state")) == 6
	return false


func _horizontal_distance(first: Vector3, second: Vector3) -> float:
	var difference := second - first
	difference.y = 0.0
	return difference.length()
