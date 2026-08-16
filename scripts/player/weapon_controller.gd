class_name VexWeaponController
extends Node

@export_category("Başlangıç")
@export var weapon_definitions: Array[WeaponDefinition] = []
@export var initial_unlocked_weapons: Array[StringName] = [&"pistol"]
@export var initial_weapon_id: StringName = &"pistol"
@export var fill_initial_magazines := true
@export var initial_bullets := 48
@export var initial_shells := 0
@export var initial_rifle_ammo := 0
@export var initial_mp90_ammo := 0

@export_category("Ateş ve Geçiş")
@export_range(0.0, 2.0, 0.01) var equip_cooldown := 0.15
@export_range(0.0, 2.0, 0.01) var empty_trigger_cooldown := 0.25
@export_flags_3d_physics var hitscan_collision_mask := 1 | 4 | 8

@export_category("Otomatik Silah Sekme Birikimi")
@export_range(0.0, 2.0, 0.01) var burst_reset_min_time := 0.22
@export_range(0.0, 8.0, 0.1) var burst_reset_fire_interval_multiplier := 2.5
@export_range(0.0, 3.0, 0.01) var automatic_vertical_base_multiplier := 0.78
@export_range(0.0, 1.0, 0.01) var automatic_vertical_per_shot := 0.07
@export_range(0.0, 3.0, 0.01) var automatic_vertical_max_multiplier := 1.35
@export_range(0.0, 3.0, 0.01) var automatic_horizontal_base_multiplier := 0.68
@export_range(0.0, 1.0, 0.01) var automatic_horizontal_per_shot := 0.09
@export_range(0.0, 3.0, 0.01) var automatic_horizontal_max_multiplier := 1.45

var unlocked_weapons: Array[StringName] = []
var magazines: Dictionary = {}
var reserve_ammo: Dictionary = {}
var current_weapon_id: StringName = &""
var is_reloading := false
var _cooldown_remaining := 0.0
var _definitions_by_id: Dictionary = {}
var _player: VexPlayer
var _burst_shots := 0
var _burst_reset_remaining := 0.0


func _ready() -> void:
	_player = get_parent() as VexPlayer
	for definition: WeaponDefinition in weapon_definitions:
		if definition == null:
			continue
		_definitions_by_id[definition.weapon_id] = definition
		magazines[definition.weapon_id] = 0
		if not reserve_ammo.has(definition.ammo_type):
			reserve_ammo[definition.ammo_type] = 0

	unlocked_weapons.clear()
	for weapon_id in initial_unlocked_weapons:
		if _definitions_by_id.has(weapon_id) and not unlocked_weapons.has(weapon_id):
			unlocked_weapons.append(weapon_id)
	if unlocked_weapons.is_empty() and not weapon_definitions.is_empty():
		var fallback_definition := weapon_definitions[0]
		if fallback_definition != null:
			unlocked_weapons.append(fallback_definition.weapon_id)

	if fill_initial_magazines:
		for weapon_id in unlocked_weapons:
			var definition := _definitions_by_id.get(weapon_id) as WeaponDefinition
			if definition != null:
				magazines[weapon_id] = definition.magazine_size

	reserve_ammo[&"bullets"] = initial_bullets
	reserve_ammo[&"shells"] = initial_shells
	reserve_ammo[&"rifle_ammo"] = initial_rifle_ammo
	reserve_ammo[&"mp90_ammo"] = initial_mp90_ammo
	current_weapon_id = initial_weapon_id
	if not unlocked_weapons.has(current_weapon_id):
		current_weapon_id = unlocked_weapons[0] if not unlocked_weapons.is_empty() else &""
	call_deferred("broadcast_state")


func _process(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	_burst_reset_remaining = maxf(0.0, _burst_reset_remaining - delta)
	if _burst_reset_remaining <= 0.0:
		_burst_shots = 0
	if get_tree().paused or _player == null or _player.is_dead:
		return
	var weapon := get_current_weapon()
	if weapon == null or is_reloading or Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	var wants_to_fire := Input.is_action_pressed("fire") if weapon.automatic else Input.is_action_just_pressed("fire")
	if wants_to_fire:
		_try_fire()


func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused or _player == null or _player.is_dead:
		return
	if event.is_action_pressed("reload"):
		reload()
	elif event.is_action_pressed("weapon_1"):
		switch_to(&"pistol")
	elif event.is_action_pressed("weapon_2"):
		switch_to(&"shotgun")
	elif event.is_action_pressed("weapon_3"):
		switch_to(&"ak47")
	elif event.is_action_pressed("weapon_4"):
		switch_to(&"mp90")
	elif event.is_action_pressed("weapon_next"):
		cycle_weapon(1)
	elif event.is_action_pressed("weapon_previous"):
		cycle_weapon(-1)


func get_current_weapon() -> WeaponDefinition:
	return _definitions_by_id.get(current_weapon_id) as WeaponDefinition


func switch_to(weapon_id: StringName) -> void:
	if is_reloading or not unlocked_weapons.has(weapon_id) or not _definitions_by_id.has(weapon_id):
		return
	current_weapon_id = weapon_id
	_cooldown_remaining = equip_cooldown
	_burst_shots = 0
	_burst_reset_remaining = 0.0
	broadcast_state()
	_play_hud_action(&"equip")


func cycle_weapon(direction: int) -> void:
	if unlocked_weapons.size() < 2:
		return
	var current_index := unlocked_weapons.find(current_weapon_id)
	var next_index := wrapi(current_index + direction, 0, unlocked_weapons.size())
	switch_to(unlocked_weapons[next_index])


func reload() -> void:
	var weapon := get_current_weapon()
	if weapon == null or is_reloading:
		return
	var magazine := int(magazines.get(current_weapon_id, 0))
	var reserve := int(reserve_ammo.get(weapon.ammo_type, 0))
	if magazine >= weapon.magazine_size or reserve <= 0:
		return
	is_reloading = true
	_play_hud_action(&"reload")
	await get_tree().create_timer(weapon.reload_duration).timeout
	if not is_inside_tree() or _player.is_dead:
		return
	var required: int = weapon.magazine_size - magazine
	var loaded: int = mini(required, reserve)
	magazines[current_weapon_id] = magazine + loaded
	reserve_ammo[weapon.ammo_type] = reserve - loaded
	is_reloading = false
	broadcast_state()


func add_ammo(ammo_type: StringName, amount: int) -> int:
	var maximum := _get_reserve_ammo_capacity(ammo_type)
	if maximum <= 0:
		return 0
	var current := int(reserve_ammo.get(ammo_type, 0))
	if current >= maximum or amount <= 0:
		return 0
	var accepted := mini(amount, maximum - current)
	reserve_ammo[ammo_type] = current + accepted
	broadcast_state()
	return accepted


func _get_reserve_ammo_capacity(ammo_type: StringName) -> int:
	var maximum := 0
	for definition: WeaponDefinition in weapon_definitions:
		if definition != null and definition.ammo_type == ammo_type:
			maximum = maxi(maximum, definition.reserve_ammo_capacity)
	return maximum


func unlock_weapon(weapon_id: StringName, bonus_ammo: int) -> void:
	if not unlocked_weapons.has(weapon_id):
		unlocked_weapons.append(weapon_id)
	var definition := _definitions_by_id.get(weapon_id) as WeaponDefinition
	if definition != null:
		if int(magazines.get(weapon_id, 0)) <= 0:
			magazines[weapon_id] = definition.magazine_size
		add_ammo(definition.ammo_type, bonus_ammo)
	switch_to(weapon_id)


func broadcast_state() -> void:
	var weapon := get_current_weapon()
	if weapon == null:
		return
	GameState.publish_weapon(weapon.weapon_id, weapon.display_name)
	GameState.publish_ammo(
		int(magazines.get(current_weapon_id, 0)),
		int(reserve_ammo.get(weapon.ammo_type, 0))
	)


func capture_state() -> Dictionary:
	return {
		"unlocked_weapons": unlocked_weapons.duplicate(),
		"magazines": magazines.duplicate(true),
		"reserve_ammo": reserve_ammo.duplicate(true),
		"current_weapon_id": current_weapon_id,
	}


func restore_state(state: Dictionary) -> void:
	if state.is_empty():
		broadcast_state()
		return
	unlocked_weapons.clear()
	var stored_weapons: Array = state.get("unlocked_weapons", initial_unlocked_weapons) as Array
	for stored_weapon: Variant in stored_weapons:
		unlocked_weapons.append(StringName(str(stored_weapon)))
	if unlocked_weapons.is_empty():
		for weapon_id in initial_unlocked_weapons:
			if _definitions_by_id.has(weapon_id):
				unlocked_weapons.append(weapon_id)
				break
	magazines = (state.get("magazines", magazines) as Dictionary).duplicate(true)
	reserve_ammo = (state.get("reserve_ammo", reserve_ammo) as Dictionary).duplicate(true)
	current_weapon_id = StringName(str(state.get("current_weapon_id", initial_weapon_id)))
	if not unlocked_weapons.has(current_weapon_id):
		current_weapon_id = (
			unlocked_weapons[0]
			if not unlocked_weapons.is_empty()
			else &""
		)
	broadcast_state()


func _try_fire() -> void:
	var weapon := get_current_weapon()
	if weapon == null or _cooldown_remaining > 0.0 or is_reloading:
		return
	var magazine := int(magazines.get(current_weapon_id, 0))
	if magazine <= 0:
		_play_hud_action(&"empty")
		GameState.notify("ŞARJÖR BOŞ — R İLE DOLDUR")
		_cooldown_remaining = empty_trigger_cooldown
		return
	magazines[current_weapon_id] = magazine - 1
	_cooldown_remaining = weapon.fire_interval
	_play_hud_action(&"fire")
	_shoot_hitscan(weapon)
	_apply_recoil(weapon)
	broadcast_state()


func _apply_recoil(weapon: WeaponDefinition) -> void:
	if _player == null or not is_instance_valid(_player):
		return

	_burst_shots += 1
	_burst_reset_remaining = maxf(
		burst_reset_min_time,
		weapon.fire_interval * burst_reset_fire_interval_multiplier
	)

	var vertical_multiplier := 1.0
	var horizontal_multiplier := 1.0
	if weapon.automatic:
		vertical_multiplier = minf(
			automatic_vertical_max_multiplier,
			automatic_vertical_base_multiplier
			+ float(_burst_shots) * automatic_vertical_per_shot
		)
		horizontal_multiplier = minf(
			automatic_horizontal_max_multiplier,
			automatic_horizontal_base_multiplier
			+ float(_burst_shots) * automatic_horizontal_per_shot
		)

	var vertical_kick: float = (
		float(weapon.recoil_vertical_degrees)
		* vertical_multiplier
		* _player.get_weapon_recoil_multiplier()
	)
	var horizontal_kick: float = randf_range(
		-float(weapon.recoil_horizontal_degrees)
		* horizontal_multiplier
		* _player.get_weapon_recoil_multiplier(),
		float(weapon.recoil_horizontal_degrees)
		* horizontal_multiplier
		* _player.get_weapon_recoil_multiplier()
	)

	_player.apply_weapon_recoil(
		vertical_kick,
		horizontal_kick,
		weapon.recoil_max_vertical_degrees,
		weapon.recoil_max_horizontal_degrees,
		weapon.recoil_recovery_degrees_per_second
	)


func _shoot_hitscan(weapon: WeaponDefinition) -> void:
	var camera: Camera3D = _player.get_view_camera()
	var space_state: PhysicsDirectSpaceState3D = camera.get_world_3d().direct_space_state

	# Atış yönünü artık ekran merkezinden değil, HUD'daki gerçek nişangah
	# konumundan hesapla. Nişangah sahnede sola/yukarı taşınsa bile mermi
	# tam onun gösterdiği noktaya gider.
	var aim_screen_position: Vector2 = camera.get_viewport().get_visible_rect().size * 0.5
	if (
		GameState.hud != null
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
	var spread_tangent: float = tan(
		deg_to_rad(weapon.spread_degrees * _player.get_weapon_spread_multiplier())
	)
	var hit_something := false
	# Aynı tetik çekişinde bir hedefe isabet eden saçmaları tek hasar çağrısında
	# birleştir. Böylece pompalı 6-8 ayrı take_damage() çağrısıyla düşmanın
	# vurulma tepkisini spamlamaz; toplam hasar değişmez.
	var pending_damage: Dictionary = {}
	var pending_hit_positions: Dictionary = {}
	for _pellet: int in weapon.pellet_count:
		var direction: Vector3 = (
			forward
			+ right * randf_range(-spread_tangent, spread_tangent)
			+ up * randf_range(-spread_tangent, spread_tangent)
		).normalized()
		var query := PhysicsRayQueryParameters3D.create(
			origin,
			origin + direction * weapon.maximum_range,
			hitscan_collision_mask,
			[_player.get_rid()]
		)
		query.collide_with_areas = true
		var result := space_state.intersect_ray(query)
		if result.is_empty():
			continue
		var collider := result.get("collider") as Object
		var damage_target := _resolve_damage_target(collider)
		if damage_target != null:
			pending_damage[damage_target] = (
				int(pending_damage.get(damage_target, 0)) + weapon.damage_per_pellet
			)
			pending_hit_positions[damage_target] = result.get("position", Vector3.ZERO)
			hit_something = true

	for damage_target_variant: Variant in pending_damage:
		var damage_target := damage_target_variant as Node
		if damage_target == null or not is_instance_valid(damage_target):
			continue
		damage_target.call(
			"take_damage",
			int(pending_damage.get(damage_target, 0)),
			pending_hit_positions.get(damage_target, Vector3.ZERO),
			_player
		)

	if hit_something:
		GameState.confirm_hit()


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _play_hud_action(action: StringName) -> void:
	if GameState.hud != null and is_instance_valid(GameState.hud) and GameState.hud.has_method("play_weapon_action"):
		GameState.hud.call("play_weapon_action", current_weapon_id, action)
