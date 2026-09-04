class_name VexWeaponHitscanRuntime
extends RefCounted

const HIT_IMPACT_V1 := preload("res://scripts/effects/hit_impact_v1.gd")
const MAX_WORLD_IMPACTS_PER_TRIGGER := 4


static func shoot(
	weapon: WeaponDefinition,
	player: VexPlayer,
	hitscan_collision_mask: int,
	modifiers: Dictionary,
	flashlight_active: bool
) -> void:
	if weapon == null or player == null or not is_instance_valid(player):
		return
	var camera: Camera3D = player.get_view_camera()
	if camera == null:
		return
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state

	# ADS sırasında optik/arpacık ekran merkezini temsil eder; hitscan da tam
	# bu merkezden hesaplanır. Hip-fire sırasında ise hareketli HUD crosshair'i
	# atış otoritesi olmaya devam eder.
	var aim_screen_position: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	var uses_ads_optical_center := player.is_aiming and weapon.supports_ads_pose
	if (
		not uses_ads_optical_center
		and GameState.hud != null
		and is_instance_valid(GameState.hud)
		and GameState.hud.has_method("get_crosshair_screen_position")
	):
		var hud_aim_position: Variant = GameState.hud.call("get_crosshair_screen_position")
		if typeof(hud_aim_position) == TYPE_VECTOR2:
			aim_screen_position = hud_aim_position

	var origin: Vector3 = camera.project_ray_origin(aim_screen_position)
	var forward: Vector3 = camera.project_ray_normal(aim_screen_position).normalized()
	var right: Vector3 = camera.global_transform.basis.x
	var up: Vector3 = camera.global_transform.basis.y
	var spread_multiplier := player.get_weapon_spread_multiplier()
	if player.is_aiming and weapon.supports_ads_pose:
		spread_multiplier = weapon.ads_spread_multiplier
	var spread_tangent: float = tan(
		deg_to_rad(weapon.spread_degrees * float(modifiers.spread) * spread_multiplier)
	)
	var hit_something := false
	var damage_multiplier := float(modifiers.damage)
	if flashlight_active:
		damage_multiplier *= float(modifiers.flashlight_damage)

	# Aynı tetik çekişinde bir hedefe isabet eden saçmaları tek hasar çağrısında
	# birleştir. Böylece pompalı 6-8 ayrı take_damage() çağrısıyla düşmanın
	# vurulma tepkisini spamlamaz; toplam hasar değişmez.
	var pending_damage: Dictionary = {}
	var pending_hit_positions: Dictionary = {}
	var pending_hit_normals: Dictionary = {}
	var world_impacts_spawned := 0
	var penetration_power := maxf(
		0.0,
		weapon.penetration_power + float(modifiers.penetration)
	)
	var extra_target_count := floori(penetration_power)
	var penetration_chance := penetration_power - float(extra_target_count)
	if penetration_chance > 0.0 and randf() < penetration_chance:
		extra_target_count += 1
	var target_limit := 1 + extra_target_count
	var current_scene := player.get_tree().current_scene

	for _pellet: int in weapon.pellet_count:
		var direction: Vector3 = (
			forward
			+ right * randf_range(-spread_tangent, spread_tangent)
			+ up * randf_range(-spread_tangent, spread_tangent)
		).normalized()
		var exclusions: Array[RID] = [player.get_rid()]
		var ray_origin := origin
		var target_hits := 0
		var ray_casts := 0
		var hit_targets: Array[Node] = []
		while target_hits < target_limit and ray_casts < target_limit + 4:
			ray_casts += 1
			var query := PhysicsRayQueryParameters3D.create(
				ray_origin,
				origin + direction * weapon.maximum_range,
				hitscan_collision_mask,
				exclusions
			)
			query.collide_with_areas = true
			var result := space_state.intersect_ray(query)
			if result.is_empty():
				break
			var collider := result.get("collider") as Object
			var damage_target := _resolve_damage_target(collider)
			var hit_position: Vector3 = result.get("position", Vector3.ZERO)
			var hit_normal: Vector3 = result.get("normal", -direction)

			# Bazı düşmanlar hareket/oyuncu çarpışma gövdesini hitscan hasarından
			# ayırır. Hedef bu isteğe bağlı sözleşmeyi uyguluyorsa yalnız kabul ettiği
			# collider üzerinden hasar ver; reddedilen fizik gövdesini ışından çıkarıp
			# aynı mermi yolunda aramaya devam et.
			if (
				damage_target != null
				and damage_target.has_method("accepts_weapon_hit")
				and not bool(damage_target.call("accepts_weapon_hit", collider, hit_position))
			):
				if collider is CollisionObject3D:
					exclusions.append((collider as CollisionObject3D).get_rid())
				ray_origin = hit_position + direction * 0.05
				continue

			# Delme yalnızca canı/hedef nesneler arasında devam eder. Duvar ve
			# kapılar mermiyi durdurur; böylece arka odalardaki hedefler vurulmaz.
			if damage_target == null:
				if world_impacts_spawned < MAX_WORLD_IMPACTS_PER_TRIGGER:
					HIT_IMPACT_V1.spawn_world(
						current_scene,
						hit_position,
						hit_normal,
						direction,
						collider
					)
					world_impacts_spawned += 1
				break	
			if not damage_target.is_in_group("enemy") and world_impacts_spawned < MAX_WORLD_IMPACTS_PER_TRIGGER:
				HIT_IMPACT_V1.spawn_world(
					current_scene,
					hit_position,
					hit_normal,
					direction,
					collider
				)
				world_impacts_spawned += 1
			if collider is CollisionObject3D:
				exclusions.append((collider as CollisionObject3D).get_rid())
			ray_origin = hit_position + direction * 0.05
			if hit_targets.has(damage_target):
				continue
			hit_targets.append(damage_target)
			target_hits += 1

			var distance_damage_multiplier := _get_distance_damage_multiplier(
				weapon,
				origin.distance_to(hit_position)
			)
			var pellet_damage := maxi(
				1,
				roundi(float(weapon.damage_per_pellet) * damage_multiplier * distance_damage_multiplier)
			)
			var was_headshot := false
			if damage_target.has_method("get_weapon_hit_multiplier"):
				var upgraded_headshot := weapon.headshot_multiplier * float(modifiers.headshot)
				var hit_multiplier := float(damage_target.call(
					"get_weapon_hit_multiplier",
					hit_position,
					upgraded_headshot
				))
				pellet_damage = maxi(1, int(round(float(pellet_damage) * hit_multiplier)))
				was_headshot = hit_multiplier > 1.01
			if was_headshot:
				GameState.confirm_headshot()
			pending_damage[damage_target] = int(pending_damage.get(damage_target, 0)) + pellet_damage
			pending_hit_positions[damage_target] = hit_position
			pending_hit_normals[damage_target] = hit_normal
			hit_something = true

	for damage_target_variant: Variant in pending_damage:
		var damage_target := damage_target_variant as Node
		if damage_target == null or not is_instance_valid(damage_target):
			continue
		var aggregated_hit_position: Vector3 = pending_hit_positions.get(
			damage_target,
			Vector3.ZERO
		)
		damage_target.call(
			"take_damage",
			int(pending_damage.get(damage_target, 0)),
			aggregated_hit_position,
			player
		)
		if damage_target.is_in_group("enemy"):
			HIT_IMPACT_V1.spawn_flesh(
				current_scene,
				aggregated_hit_position,
				pending_hit_normals.get(damage_target, Vector3.UP),
				Vector3.ZERO
			)

	if hit_something:
		GameState.confirm_hit()


static func _get_distance_damage_multiplier(weapon: WeaponDefinition, distance: float) -> float:
	var start := maxf(0.0, weapon.damage_falloff_start_distance)
	var finish := maxf(0.0, weapon.damage_falloff_end_distance)
	if finish <= start or distance <= start:
		return 1.0
	var ratio := clampf((distance - start) / (finish - start), 0.0, 1.0)
	return lerpf(1.0, weapon.damage_falloff_min_multiplier, ratio)


static func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null
