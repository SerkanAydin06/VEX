extends Node3D

const DOOR_SCENE := preload("res://scenes/props/door_side_slide.tscn")
const WARDEN_SCENE := preload("res://scenes/actors/crucible_warden.tscn")

const CASE_TIMEOUT_SECONDS := 12.0
const POST_CROSS_ATTACK_TIMEOUT_SECONDS := 6.0
const FLOOR_Y := -1.32

var failures: Array[String] = []


class MockPlayer:
	extends CharacterBody3D

	var is_dead := false
	var is_crouching := false
	var damage_events := 0

	func _init() -> void:
		collision_layer = 2
		collision_mask = 1
		var shape_node := CollisionShape3D.new()
		var shape := CapsuleShape3D.new()
		shape.radius = 0.42
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
	await _run_case(0.0, "X ekseni")
	await _run_case(PI * 0.5, "Z ekseni")
	GameState.player = null
	if failures.is_empty():
		print("WARDEN DOOR RUNTIME: 2 yön geçti; kapı geçişi ve saldırı devamlılığı temiz.")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		push_error("WARDEN DOOR RUNTIME: %d hata." % failures.size())
		get_tree().quit(1)


func _run_case(rotation_y: float, label: String) -> void:
	var case_root := Node3D.new()
	case_root.name = "Case_%s" % label
	add_child(case_root)
	var travel_axis := Vector3.RIGHT.rotated(Vector3.UP, rotation_y).normalized()

	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	floor_body.collision_mask = 0
	floor_body.position = Vector3(0.0, FLOOR_Y, 0.0)
	var floor_shape_node := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20.0, 0.2, 10.0)
	floor_shape_node.shape = floor_shape
	floor_body.add_child(floor_shape_node)
	case_root.add_child(floor_body)

	var door := DOOR_SCENE.instantiate() as VexDoor
	if door == null:
		failures.append("%s: kapı instantiate edilemedi." % label)
		case_root.queue_free()
		await get_tree().process_frame
		return
	door.rotation.y = rotation_y
	door.position.y = 1.02
	door.auto_close = false
	door.opening_time = 0.05
	door.allow_enemy_open = true
	case_root.add_child(door)
	door.request_enemy_open()
	var open_wait := 0.0
	while not door.is_open and open_wait < 2.0:
		await get_tree().physics_frame
		open_wait += get_physics_process_delta_time()
	if not door.is_open:
		failures.append("%s: kapı test başlangıcında 2 saniyede tam açılmadı." % label)

	var player := MockPlayer.new()
	player.name = "MockPlayer"
	player.position = travel_axis * 6.0
	case_root.add_child(player)
	GameState.register_player(player)
	await get_tree().physics_frame

	var warden := WARDEN_SCENE.instantiate() as VexCrucibleWarden
	if warden == null:
		failures.append("%s: Warden instantiate edilemedi." % label)
		GameState.player = null
		case_root.queue_free()
		await get_tree().process_frame
		return
	warden.enemy_id = StringName("runtime_warden_%s" % label)
	warden.position = -travel_axis * 6.0
	warden.apply_difficulty_scaling = false
	warden.detection_range = 30.0
	warden.pursuit_range = 30.0
	case_root.add_child(warden)
	await get_tree().physics_frame
	warden.take_damage(1, player.global_position, player)

	var crossed := false
	var attacked_after_crossing := false
	var elapsed := 0.0
	var crossed_at := 0.0
	while elapsed < CASE_TIMEOUT_SECONDS + POST_CROSS_ATTACK_TIMEOUT_SECONDS:
		await get_tree().physics_frame
		var delta := get_physics_process_delta_time()
		elapsed += delta
		if not is_instance_valid(warden):
			failures.append("%s: Warden test sırasında sahneden çıktı." % label)
			break
		var progress := warden.global_position.dot(travel_axis)
		if not crossed and progress >= 0.9:
			crossed = true
			crossed_at = elapsed
		if crossed and (
			int(warden.get("state")) == VexRavager.State.ATTACK
			or bool(warden.get("_attack_locked"))
			or player.damage_events > 0
		):
			attacked_after_crossing = true
			break
		if not crossed and elapsed >= CASE_TIMEOUT_SECONDS:
			break
		if crossed and elapsed - crossed_at >= POST_CROSS_ATTACK_TIMEOUT_SECONDS:
			break

	if not crossed:
		failures.append(
			"%s: Warden açık kapıyı %.1f saniyede geçemedi (konum=%s)."
			% [label, CASE_TIMEOUT_SECONDS, str(warden.global_position if is_instance_valid(warden) else Vector3.ZERO)]
		)
	elif not attacked_after_crossing:
		failures.append("%s: Warden kapıdan sonra saldırı durumuna dönemedi." % label)

	GameState.player = null
	case_root.queue_free()
	await get_tree().process_frame
