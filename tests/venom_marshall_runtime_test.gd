extends Node

const BUFF_PROJECTILE_SCENE := preload("res://scenes/actors/venom_marshall_buff_projectile.tscn")
const ACTOR_SCENE := preload("res://scenes/actors/venom_marshall.tscn")

class DummyEnemy:
	extends Node3D
	var health := 50
	var _runtime_maximum_health := 100
	var _runtime_attack_damage := 20

	func take_damage(_amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
		pass


func _ready() -> void:
	var actor := ACTOR_SCENE.instantiate() as VexVenomMarshall
	assert(actor != null)
	add_child(actor)
	actor.global_position = Vector3(3.0, 0.0, 4.0)
	actor.set_physics_process(false)
	assert(is_equal_approx(actor.buff_cast_range, 7.0))

	var candidate := DummyEnemy.new()
	candidate.name = "BuffCandidate"
	candidate.add_to_group("enemy")
	add_child(candidate)
	candidate.global_position = actor.global_position + Vector3(6.5, 0.0, 0.0)
	assert(bool(actor.call("_has_buff_candidate_in_self_field")))
	candidate.global_position = actor.global_position + Vector3(7.5, 0.0, 0.0)
	assert(not bool(actor.call("_has_buff_candidate_in_self_field")))
	candidate.global_position = actor.global_position + Vector3(3.0, 0.0, 0.0)

	var projectile := BUFF_PROJECTILE_SCENE.instantiate() as VexVenomMarshallBuffProjectile
	assert(projectile != null)
	assert(is_equal_approx(projectile.field_radius, 7.0))
	projectile.field_duration = 0.4
	projectile.buff_duration = 0.18
	add_child(projectile)
	var deploy_audio := projectile.get_node_or_null("DeployAudio") as AudioStreamPlayer3D
	if deploy_audio != null:
		deploy_audio.stop()
		deploy_audio.stream = null

	assert(is_equal_approx(projectile.get_field_radius(), 7.0))
	var field_shape := (projectile.get_node("FieldCollision") as CollisionShape3D).shape as CylinderShape3D
	assert(field_shape != null)
	assert(is_equal_approx(field_shape.radius, 7.0))
	var field_mesh := (projectile.get_node("FieldDisc") as MeshInstance3D).mesh as CylinderMesh
	assert(field_mesh != null)
	assert(is_equal_approx(field_mesh.top_radius, 7.0))
	var ground_visual := projectile.get_node("GroundFieldVisual") as AnimatedSprite3D
	assert(is_equal_approx(ground_visual.pixel_size, 14.0 / 512.0))
	var field_light := projectile.get_node("FieldLight") as OmniLight3D
	assert(is_equal_approx(field_light.omni_range, 8.0))

	# Buff artık bir müttefik konumuna uçmaz; doğrudan Venom Marshall'ın bulunduğu
	# noktada açılır ve alan merkezi kaynak yaratığın X/Z konumuyla aynıdır.
	projectile.deploy_at(actor.global_position, actor)
	assert(projectile.is_field_active())
	assert(is_equal_approx(projectile.global_position.x, actor.global_position.x))
	assert(is_equal_approx(projectile.global_position.z, actor.global_position.z))

	projectile.call("_apply_support_pulse", candidate)
	assert(candidate.health == 54)
	assert(candidate._runtime_attack_damage == 25)
	var status := candidate.get_node_or_null("VenomMarshallBuffStatus") as VexVenomMarshallBuffStatus
	assert(status != null)
	assert(status.get_damage_bonus() == 5)

	# Yenilenen nabız canı artırır fakat hasar bonusunu katlayarak biriktirmez.
	projectile.call("_apply_support_pulse", candidate)
	assert(candidate.health == 58)
	assert(candidate._runtime_attack_damage == 25)

	await get_tree().create_timer(0.24).timeout
	assert(candidate._runtime_attack_damage == 20)
	assert(candidate.get_node_or_null("VenomMarshallBuffStatus") == null)

	projectile.free()
	candidate.free()
	actor.free()
	for _frame: int in range(3):
		await get_tree().process_frame
	print("Venom Marshall support runtime test passed")
	get_tree().quit(0)
