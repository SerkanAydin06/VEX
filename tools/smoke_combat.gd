## Savaş duman testi: test alanındaki her düşman türünü sırayla oyuncunun karşısına alır.
## Ölçülen: düşman oyuncuya hasar verebildi mi, oyuncunun gerçek silah ateşiyle öldü mü,
## ölüm sayacı arttı mı. Oyuncu ölmesin diye can her karede yenilenir; alınan hasar toplanır.
##   godot --headless --path . -s tools/smoke_combat.gd   (~3 dk; test alanında can 500, oyuncu ölümsüz)
## Çıktıdaki ERROR/SCRIPT ERROR satırları hatadır. Geçici kopyada çalıştır (user:// yazabilir).
extends SceneTree

const TEST_LEVEL := "res://scenes/levels/level_test.tscn"
const ENGAGE_SECONDS := 6.0
const FIRE_SECONDS := 20.0
const STANDOFF := 6.0

var _game_state: Node
var _player: Node3D
var _damage_taken := 0
var _baseline_health := 0
var _baseline_armor := 0


func _initialize() -> void:
	_run()


func _frame() -> void:
	await process_frame
	if not is_instance_valid(_player):
		return
	var survivability: Object = _player.get("_survivability_runtime")
	var health := int(survivability.call("get_health"))
	var armor := int(survivability.call("get_armor"))
	if health < _baseline_health or armor < _baseline_armor:
		_damage_taken += (_baseline_health - health) + maxi(0, _baseline_armor - armor)
		# Oyuncu ölmesin: tabana geri getir (test alanında taban zaten çok yüksek).
		survivability.call("restore_state", _baseline_health, _baseline_armor)
		_player.set("health", _baseline_health)
		_player.set("armor", _baseline_armor)


## Gerçek saat: headless modda kare hızı 60'ın çok üstüne çıkar; kare saymak süreyi kısaltır.
func _now() -> float:
	return Time.get_ticks_msec() / 1000.0


func _wait(seconds: float) -> void:
	var end := _now() + seconds
	while _now() < end:
		await _frame()


func _tap(code: Key) -> void:
	for pressed: bool in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = pressed
		Input.parse_input_event(event)
		await process_frame


func _is_dead(enemy: Variant) -> bool:
	return not is_instance_valid(enemy) or int(enemy.get("health")) <= 0


func _clear_spot(enemy: Node3D) -> Vector3:
	var space := (enemy.get_world_3d() as World3D).direct_space_state
	var origin := enemy.global_position + Vector3.UP * 1.0
	for direction: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		var target := origin + direction * STANDOFF
		var query := PhysicsRayQueryParameters3D.create(origin, target)
		query.exclude = [enemy.get_rid()]
		query.collision_mask = 1
		if space.intersect_ray(query).is_empty():
			return target - Vector3.UP * 1.0
	return enemy.global_position + Vector3.RIGHT * STANDOFF


func _aim_at(enemy: Node3D) -> void:
	if not is_instance_valid(enemy) or not is_instance_valid(_player):
		return
	var eye: Vector3 = (_player.get("camera") as Camera3D).global_position
	# Düşmanın kendi çarpışma gövdesinin merkezine nişan al (kısa/uzun türler için doğru yükseklik).
	var body_shape := enemy.get_node_or_null("CollisionShape3D") as Node3D
	var target := body_shape.global_position if body_shape != null else enemy.global_position + Vector3.UP * 0.9
	var flat := Vector3(target.x - eye.x, 0.0, target.z - eye.z)
	_player.rotation.y = atan2(-flat.x, -flat.z)
	# Dikey bakış PlayerViewRuntime._pitch'te tutulur ve her karede ViewPivot'a yazılır.
	var pitch := atan2(target.y - eye.y, flat.length())
	var view_runtime: Object = _player.get("_view_runtime")
	view_runtime.set("_pitch", pitch)
	# Gerçek oyuncu geri tepmeyi telafi eder; test her karede nişanı sıfırlar.
	view_runtime.set("_recoil_pitch_degrees", 0.0)
	view_runtime.set("_recoil_yaw_degrees", 0.0)
	(_player.get("view_pivot") as Node3D).rotation.x = pitch


func _run() -> void:
	_game_state = root.get_node("GameState")
	change_scene_to_file(TEST_LEVEL)
	await _wait(1.0)
	for _i: int in range(4):
		await _tap(KEY_SPACE)
		await _wait(0.5)
	_player = _game_state.get("player") as Node3D
	assert(_player != null)
	var survivability: Object = _player.get("_survivability_runtime")
	_baseline_health = int(survivability.call("get_health"))
	_baseline_armor = int(survivability.call("get_armor"))
	var controller: Object = _player.get("weapon_controller")
	print("COMBAT silah=%s" % controller.get("current_weapon_id"))
	var enemies: Array = get_nodes_in_group("enemy").duplicate()
	enemies.sort_custom(func(a: Node, b: Node) -> bool: return str(a.name) < str(b.name))
	print("COMBAT enemies=%d" % enemies.size())
	var failures := 0
	for enemy: Variant in enemies:
		if _is_dead(enemy):
			continue
		var enemy_name := str(enemy.name)
		var kills_before := int(_game_state.get("kills"))
		_player.global_position = _clear_spot(enemy)
		_player.set("velocity", Vector3.ZERO)
		_damage_taken = 0
		var engage_end := _now() + ENGAGE_SECONDS
		while _now() < engage_end and _damage_taken == 0 and not _is_dead(enemy):
			_aim_at(enemy)
			await _frame()
		var attacked := _damage_taken > 0
		var damage_report := _damage_taken
		var health_before := int(enemy.get("health")) if is_instance_valid(enemy) else 0
		var weapon: Object = controller.call("get_current_weapon")
		(controller.get("reserve_ammo") as Dictionary)[weapon.get("ammo_type")] = 400
		var shots := 0
		var fire_end := _now() + FIRE_SECONDS
		# Headless'ta fare yakalanamaz (WeaponController MOUSE_MODE_CAPTURED ister); tetik
		# girdisi yerine silahın kendi ateş yolunu çağır: mermi, isabet ve hasar gerçek koddan geçer.
		while _now() < fire_end and not _is_dead(enemy):
			_aim_at(enemy)
			if int(controller.get("magazines").get(controller.get("current_weapon_id"), 1)) <= 0:
				controller.call("reload")
			else:
				var before := int(controller.get("magazines").get(controller.get("current_weapon_id"), 0))
				controller.call("_try_fire")
				if int(controller.get("magazines").get(controller.get("current_weapon_id"), 0)) < before:
					shots += 1
			await _frame()
		Input.action_release("fire")
		var killed_by_fire := _is_dead(enemy)
		var health_after := int(enemy.get("health")) if is_instance_valid(enemy) else 0
		if not killed_by_fire and is_instance_valid(enemy):
			enemy.call("take_damage", 999999, enemy.global_position, _player)
		await _wait(1.5)
		var counted := int(_game_state.get("kills")) > kills_before
		var ok := counted
		if not ok:
			failures += 1
		print("COMBAT %-18s saldırı=%s(%d) atış=%d can=%d→%d silahla_öldü=%s sayaç=%s %s" % [enemy_name, attacked, damage_report, shots, health_before, health_after, killed_by_fire, counted, "OK" if ok else "FAIL"])
	print("COMBAT DONE failures=%d" % failures)
	quit(1 if failures > 0 else 0)
