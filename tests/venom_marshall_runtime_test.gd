extends Node

const BUFF_PROJECTILE_SCENE := preload("res://scenes/actors/venom_marshall_buff_projectile.tscn")

class DummyEnemy:
	extends Node3D
	var health := 50
	var _runtime_maximum_health := 100
	var _runtime_attack_damage := 20

	func take_damage(_amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
		pass


func _ready() -> void:
	var projectile := BUFF_PROJECTILE_SCENE.instantiate() as VexVenomMarshallBuffProjectile
	assert(projectile != null)
	projectile.field_radius = 4.8
	projectile.field_duration = 0.4
	projectile.buff_duration = 0.18
	add_child(projectile)
	var deploy_audio := projectile.get_node_or_null("DeployAudio") as AudioStreamPlayer3D
	if deploy_audio != null:
		deploy_audio.stop()
		deploy_audio.stream = null

	assert(is_equal_approx(projectile.get_field_radius(), 4.8))
	var field_shape := (projectile.get_node("FieldCollision") as CollisionShape3D).shape as CylinderShape3D
	assert(field_shape != null)
	assert(is_equal_approx(field_shape.radius, 4.8))
	var field_mesh := (projectile.get_node("FieldDisc") as MeshInstance3D).mesh as CylinderMesh
	assert(field_mesh != null)
	assert(is_equal_approx(field_mesh.top_radius, 4.8))

	var source := Node3D.new()
	add_child(source)
	var target := DummyEnemy.new()
	target.add_to_group("enemy")
	add_child(target)
	projectile.launch_to(Vector3.ZERO, source)
	projectile.call("_deploy_field", Vector3.ZERO)
	assert(projectile.is_field_active())

	projectile.call("_apply_support_pulse", target)
	assert(target.health == 54)
	assert(target._runtime_attack_damage == 25)
	var status := target.get_node_or_null("VenomMarshallBuffStatus") as VexVenomMarshallBuffStatus
	assert(status != null)
	assert(status.get_damage_bonus() == 5)

	# Yenilenen nabız canı artırır fakat hasar bonusunu katlayarak biriktirmez.
	projectile.call("_apply_support_pulse", target)
	assert(target.health == 58)
	assert(target._runtime_attack_damage == 25)

	await get_tree().create_timer(0.24).timeout
	assert(target._runtime_attack_damage == 20)
	assert(target.get_node_or_null("VenomMarshallBuffStatus") == null)

	projectile.free()
	target.free()
	source.free()
	for _frame: int in range(3):
		await get_tree().process_frame
	print("Venom Marshall support runtime test passed")
	get_tree().quit(0)
