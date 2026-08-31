extends Node3D

const GOREHORN_SCENE := preload("res://scenes/actors/gorehorn.tscn")

const HIT_TIMEOUT_SECONDS := 2.0
const WALL_TIMEOUT_SECONDS := 2.0
const RECOVERY_TIMEOUT_SECONDS := 1.5
const FLOOR_TOP_Y := 0.0

var failures: Array[String] = []


class MockPlayer:
	extends CharacterBody3D

	var is_dead := false
	var is_crouching := false
	var damage_events := 0
	var impulse_events := 0
	var shake_events := 0
	var shock_events := 0
	var last_damage := 0
	var last_impulse_direction := Vector3.ZERO
	var last_impulse_horizontal_speed := 0.0
	var last_impulse_upward_speed := 0.0
	var last_impulse_duration := 0.0
	var last_shake_strength := 0.0
	var last_shock_alpha := 0.0

	func _init() -> void:
		collision_layer = 2
		collision_mask = 1 | 4
		var shape_node := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.42
		shape.height = 1.8
		shape_node.shape = shape
		add_child(shape_node)

	func broadcast_state() -> void:
		pass

	func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
		damage_events += 1
		last_damage = amount

	func apply_external_impulse(
		direction: Vector3,
		horizontal_speed: float,
		upward_speed: float,
		duration: float
	) -> void:
		impulse_events += 1
		last_impulse_direction = direction
		last_impulse_horizontal_speed = horizontal_speed
		last_impulse_upward_speed = upward_speed
		last_impulse_duration = duration

	func request_camera_shake(strength: float, _duration: float) -> void:
		shake_events += 1
		last_shake_strength = strength

	func request_impact_shock(_tint: Color, peak_alpha: float, _duration: float) -> void:
		shock_events += 1
		last_shock_alpha = peak_alpha


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.active_difficulty = 1
	await _run_player_hit_case()
	await _run_wall_block_case()
	GameState.player = null
	if failures.is_empty():
		print("GOREHORN CHARGE RUNTIME: tek vuruş, itme, geri bildirim, duvar duruşu ve idle toparlanması geçti.")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		push_error("GOREHORN CHARGE RUNTIME: %d hata." % failures.size())
		get_tree().quit(1)


func _run_player_hit_case() -> void:
	var case_root := Node3D.new()
	case_root.name = "PlayerHitCase"
	add_child(case_root)
	_add_floor(case_root)

	var player := MockPlayer.new()
	player.name = "MockPlayer"
	player.position = Vector3(0.0, 0.9, -5.0)
	case_root.add_child(player)
	GameState.register_player(player)
	await get_tree().physics_frame

	var gorehorn := _spawn_test_gorehorn(case_root, "runtime_gorehorn_hit")
	if gorehorn == null:
		GameState.player = null
		case_root.free()
		await get_tree().process_frame
		return

	await get_tree().physics_frame
	gorehorn.call("_attempt_attack")

	var elapsed := 0.0
	while player.damage_events == 0 and elapsed < HIT_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	if player.damage_events != 1:
		failures.append("Oyuncu temasında tam bir hasar olayı oluşmadı: %d." % player.damage_events)
	else:
		if player.last_damage != int(gorehorn.get("_runtime_attack_damage")):
			failures.append("Şarj hasarı runtime düşman hasarıyla eşleşmiyor.")
		if player.impulse_events != 1:
			failures.append("Başarılı temas tek bir external impulse üretmedi.")
		if player.shake_events != 1:
			failures.append("Başarılı temas tek bir kamera sarsıntısı isteği üretmedi.")
		if player.shock_events != 1:
			failures.append("Başarılı temas tek bir darbe perdesi isteği üretmedi.")
		if player.last_impulse_direction.z >= -0.5:
			failures.append("Boynuz itmesi şarj yönüne doğru uygulanmadı.")
		var settings := gorehorn.special_ability_settings as VexGorehornChargeSettings
		if settings == null:
			failures.append("Runtime Gorehorn şarj ayarı kayboldu.")
		else:
			if not is_equal_approx(player.last_impulse_horizontal_speed, settings.knockback_horizontal_speed):
				failures.append("Runtime yatay itme Inspector ayarıyla eşleşmiyor.")
			if not is_equal_approx(player.last_impulse_upward_speed, settings.knockback_upward_speed):
				failures.append("Runtime yukarı itme Inspector ayarıyla eşleşmiyor.")
			if not is_equal_approx(player.last_impulse_duration, settings.knockback_duration):
				failures.append("Runtime itme süresi Inspector ayarıyla eşleşmiyor.")
			if not is_equal_approx(player.last_shake_strength, settings.impact_shake_strength):
				failures.append("Runtime kamera sarsıntısı Inspector ayarıyla eşleşmiyor.")
			if not is_equal_approx(player.last_shock_alpha, settings.impact_shock_peak_alpha):
				failures.append("Runtime darbe perdesi Inspector ayarıyla eşleşmiyor.")

	await get_tree().physics_frame
	var sprite := gorehorn.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite == null or sprite.animation != &"idle":
		failures.append("Oyuncu temasından sonra Gorehorn cooldown beklemeden idle'a dönmedi.")
	if not bool(gorehorn.get("_attack_locked")):
		failures.append("Idle toparlanma pozu saldırı cooldown kilidini erken kaldırdı.")

	# Aynı şarjın ikinci vuruş üretmediğini doğrularken yeni saldırıyı engelle.
	player.position = Vector3(0.0, 0.9, -30.0)
	await _wait_seconds(0.30)
	if player.damage_events != 1 or player.impulse_events != 1:
		failures.append("Tek şarj oyuncuya birden fazla hasar veya itme uyguladı.")

	var recovery_elapsed := 0.0
	while bool(gorehorn.get("_attack_locked")) and recovery_elapsed < RECOVERY_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		recovery_elapsed += get_physics_process_delta_time()
	if bool(gorehorn.get("_attack_locked")):
		failures.append("Başarılı şarj cooldown sonunda saldırı kilidini bırakmadı.")

	GameState.player = null
	case_root.free()
	await get_tree().process_frame


func _run_wall_block_case() -> void:
	var case_root := Node3D.new()
	case_root.name = "WallBlockCase"
	add_child(case_root)
	_add_floor(case_root)

	var player := MockPlayer.new()
	player.name = "MockPlayer"
	player.position = Vector3(0.0, 0.9, -8.0)
	case_root.add_child(player)
	GameState.register_player(player)
	await get_tree().physics_frame

	var gorehorn := _spawn_test_gorehorn(case_root, "runtime_gorehorn_wall")
	if gorehorn == null:
		GameState.player = null
		case_root.free()
		await get_tree().process_frame
		return

	await get_tree().physics_frame
	gorehorn.call("_attempt_attack")

	var activation_elapsed := 0.0
	while not bool(gorehorn.get("_charge_active")) and activation_elapsed < 0.6:
		await get_tree().physics_frame
		activation_elapsed += get_physics_process_delta_time()
	if not bool(gorehorn.get("_charge_active")):
		failures.append("Duvar vakasında Gorehorn şarj durumuna giremedi.")
	else:
		_add_wall(case_root, Vector3(0.0, 2.0, -2.4))

	var elapsed := 0.0
	while not bool(gorehorn.get("_charge_blocked")) and elapsed < WALL_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()

	if not bool(gorehorn.get("_charge_blocked")):
		failures.append("Gorehorn fizik duvarına çarpınca şarjı blocked olarak bitirmedi.")
	if bool(gorehorn.get("_charge_active")):
		failures.append("Duvar çarpışmasından sonra şarj hareketi aktif kaldı.")
	if player.damage_events != 0 or player.impulse_events != 0:
		failures.append("Duvar arkasındaki oyuncu şarj hasarı veya itme aldı.")
	if Vector2(gorehorn.velocity.x, gorehorn.velocity.z).length() > 0.01:
		failures.append("Duvar çarpışmasından sonra yatay şarj hızı sıfırlanmadı.")

	await get_tree().physics_frame
	var sprite := gorehorn.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite == null or sprite.animation != &"idle":
		failures.append("Duvar çarpışmasından sonra Gorehorn idle toparlanmasına dönmedi.")

	var recovery_elapsed := 0.0
	while bool(gorehorn.get("_attack_locked")) and recovery_elapsed < RECOVERY_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		recovery_elapsed += get_physics_process_delta_time()
	if bool(gorehorn.get("_attack_locked")):
		failures.append("Duvara çarpan şarj toparlanma sonunda kilidi bırakmadı.")

	GameState.player = null
	case_root.free()
	await get_tree().process_frame


func _spawn_test_gorehorn(case_root: Node3D, runtime_id: String) -> VexGorehorn:
	var gorehorn := GOREHORN_SCENE.instantiate() as VexGorehorn
	if gorehorn == null:
		failures.append("%s: Gorehorn instantiate edilemedi." % runtime_id)
		return null
	gorehorn.enemy_id = StringName(runtime_id)
	gorehorn.position = Vector3(0.0, 1.2, 0.0)
	gorehorn.apply_difficulty_scaling = false
	gorehorn.detection_range = 1.0
	gorehorn.pursuit_range = 20.0
	gorehorn.attack_range = 12.0
	gorehorn.attack_windup = 0.08
	gorehorn.attack_cooldown = 0.90
	gorehorn.attack_lunge_speed = 12.0
	gorehorn.attack_lunge_acceleration = 120.0
	gorehorn.attack_lunge_duration = 0.65
	gorehorn.dormant_distance = 100.0

	var settings := gorehorn.special_ability_settings.duplicate(true) as VexGorehornChargeSettings
	if settings == null:
		failures.append("%s: şarj ayarı duplicate edilemedi." % runtime_id)
		gorehorn.free()
		return null
	settings.hit_distance = 1.15
	settings.recovery_duration = 0.15
	settings.blocked_recovery_duration = 0.22
	settings.impact_shake_enabled = true
	settings.impact_shock_enabled = true
	gorehorn.special_ability_settings = settings
	case_root.add_child(gorehorn)
	return gorehorn


func _add_floor(case_root: Node3D) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector3(0.0, FLOOR_TOP_Y - 0.1, -4.0)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(12.0, 0.2, 16.0)
	shape_node.shape = shape
	floor_body.add_child(shape_node)
	case_root.add_child(floor_body)


func _add_wall(case_root: Node3D, wall_position: Vector3) -> void:
	var wall_body := StaticBody3D.new()
	wall_body.name = "ChargeWall"
	wall_body.collision_layer = 1
	wall_body.collision_mask = 0
	wall_body.position = wall_position
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(6.0, 4.0, 0.35)
	shape_node.shape = shape
	wall_body.add_child(shape_node)
	case_root.add_child(wall_body)


func _wait_seconds(duration: float) -> void:
	var elapsed := 0.0
	while elapsed < duration:
		await get_tree().physics_frame
		elapsed += get_physics_process_delta_time()
