extends Node3D

const GOREHORN_SCENE := preload("res://scenes/actors/gorehorn.tscn")
const FLOOR_TOP_Y := 0.0

var failures: Array[String] = []


class MockPlayer:
	extends CharacterBody3D

	var is_dead := false
	var is_crouching := false
	var damage_events := 0

	func _init() -> void:
		collision_layer = 2
		collision_mask = 1 | 4
		var shape_node := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.34
		shape.height = 1.8
		shape_node.shape = shape
		add_child(shape_node)

	func broadcast_state() -> void:
		pass

	func take_damage(_amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
		damage_events += 1


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.active_difficulty = 1
	await _run_vertical_contact_case()
	await _run_player_loss_case()
	GameState.player = null
	if failures.is_empty():
		print("GOREHORN EDGE RUNTIME: dikey temas filtresi ve oyuncu kaybı cleanup geçti.")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		push_error("GOREHORN EDGE RUNTIME: %d hata." % failures.size())
		get_tree().quit(1)


func _run_vertical_contact_case() -> void:
	var case_root := Node3D.new()
	case_root.name = "VerticalContactCase"
	add_child(case_root)
	_add_floor(case_root)

	var player := MockPlayer.new()
	player.name = "MockPlayer"
	player.position = Vector3(0.0, 0.9, -0.65)
	case_root.add_child(player)
	GameState.register_player(player)

	var gorehorn := _spawn_test_gorehorn(case_root, "runtime_gorehorn_vertical")
	if gorehorn == null:
		GameState.player = null
		_dispose_case(case_root)
		await get_tree().process_frame
		return

	await get_tree().physics_frame
	var settings := gorehorn.special_ability_settings as VexGorehornChargeSettings
	if settings == null:
		failures.append("Dikey temas vakasında Gorehorn charge settings okunamadı.")
	else:
		settings.hit_distance = 1.15
		settings.vertical_hit_tolerance = 1.50
		if not bool(gorehorn.call("_is_player_within_charge_hit_volume", settings)):
			failures.append("Aynı kattaki yakın oyuncu Gorehorn temas hacminde sayılmadı.")

		player.position.y = gorehorn.global_position.y + settings.vertical_hit_tolerance + 1.0
		await get_tree().physics_frame
		if bool(gorehorn.call("_is_player_within_charge_hit_volume", settings)):
			failures.append("Dikey tolerans dışındaki oyuncu yatay yakınlık nedeniyle yanlış temas sayıldı.")

	GameState.player = null
	_dispose_case(case_root)
	await get_tree().process_frame


func _run_player_loss_case() -> void:
	var case_root := Node3D.new()
	case_root.name = "PlayerLossCase"
	add_child(case_root)
	_add_floor(case_root)

	var player := MockPlayer.new()
	player.name = "MockPlayer"
	player.position = Vector3(0.0, 0.9, -4.0)
	case_root.add_child(player)
	GameState.register_player(player)

	var gorehorn := _spawn_test_gorehorn(case_root, "runtime_gorehorn_player_loss")
	if gorehorn == null:
		GameState.player = null
		_dispose_case(case_root)
		await get_tree().process_frame
		return

	gorehorn.attack_range = 12.0
	gorehorn.attack_windup = 0.35
	gorehorn.attack_cooldown = 0.90
	await get_tree().physics_frame
	gorehorn.call("_attempt_attack")
	if not bool(gorehorn.get("_attack_locked")):
		failures.append("Oyuncu kaybı vakasında Gorehorn windup saldırı kilidine girmedi.")

	GameState.player = null
	player.queue_free()
	await get_tree().process_frame
	for _frame: int in range(3):
		await get_tree().physics_frame

	if bool(gorehorn.get("_attack_locked")):
		failures.append("Oyuncu windup sırasında silinince Gorehorn saldırı kilidi açık kaldı.")
	if bool(gorehorn.get("_charge_active")):
		failures.append("Oyuncu silindikten sonra Gorehorn şarj hareketi aktif kaldı.")
	if Vector2(gorehorn.velocity.x, gorehorn.velocity.z).length() > 0.01:
		failures.append("Oyuncu silindikten sonra Gorehorn yatay hızı temizlenmedi.")
	var sprite := gorehorn.get_node_or_null("AnimatedSprite3D") as AnimatedSprite3D
	if sprite == null or sprite.animation != &"idle":
		failures.append("Oyuncu kaybı cleanup sonrası Gorehorn idle poza dönmedi.")

	_dispose_case(case_root)
	await get_tree().process_frame


func _spawn_test_gorehorn(case_root: Node3D, runtime_id: String) -> VexGorehorn:
	var gorehorn := GOREHORN_SCENE.instantiate() as VexGorehorn
	if gorehorn == null:
		failures.append("%s: Gorehorn instantiate edilemedi." % runtime_id)
		return null
	gorehorn.enemy_id = StringName(runtime_id)
	gorehorn.position = Vector3(0.0, 1.2, 0.0)
	gorehorn.apply_difficulty_scaling = false
	gorehorn.detection_range = 0.1
	gorehorn.pursuit_range = 20.0
	gorehorn.attack_range = 12.0
	gorehorn.attack_windup = 0.10
	gorehorn.attack_cooldown = 0.90
	gorehorn.attack_lunge_speed = 12.0
	gorehorn.attack_lunge_acceleration = 120.0
	gorehorn.attack_lunge_duration = 0.65
	gorehorn.dormant_distance = 100.0

	for audio_name: StringName in [&"AttackAudio", &"ChargeImpactAudio", &"HurtAudio", &"DeathAudio"]:
		var audio := gorehorn.get_node_or_null(NodePath(audio_name)) as AudioStreamPlayer3D
		if audio != null:
			audio.stream = null

	case_root.add_child(gorehorn)
	return gorehorn


func _add_floor(case_root: Node3D) -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector3(0.0, FLOOR_TOP_Y - 0.1, -2.0)
	var shape_node := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(10.0, 0.2, 10.0)
	shape_node.shape = shape
	floor_body.add_child(shape_node)
	case_root.add_child(floor_body)


func _dispose_case(case_root: Node3D) -> void:
	for node: Node in case_root.find_children("*", "AudioStreamPlayer3D", true, false):
		var audio := node as AudioStreamPlayer3D
		audio.stop()
		audio.stream = null
	case_root.free()
