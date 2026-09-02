extends Node

const BUFF_PROJECTILE_SCENE := preload("res://scenes/actors/venom_marshall_buff_projectile.tscn")

class DummyEnemy:
	extends Node3D
	var health := 50
	var maximum_health := 100
	var _runtime_maximum_health := 100
	var _runtime_attack_damage := 20
	var _runtime_move_speed := 3.0
	var _runtime_chase_speed := 5.0


func _ready() -> void:
	var projectile := BUFF_PROJECTILE_SCENE.instantiate() as VexVenomMarshallBuffProjectile
	assert(projectile != null)
	add_child(projectile)

	projectile.field_radius = 7.0
	projectile.buff_grace_duration = 0.12
	projectile.call("_apply_field_radius")
	var collision := projectile.get_node("FieldCollision") as CollisionShape3D
	var cylinder := collision.shape as CylinderShape3D
	var field_visual := projectile.get_node("FieldVisual") as AnimatedSprite3D
	assert(is_equal_approx(projectile.get_field_radius(), 7.0))
	assert(is_equal_approx(cylinder.radius, 7.0))
	assert(is_equal_approx(field_visual.pixel_size, 14.0 / 512.0))

	var target := DummyEnemy.new()
	target.name = "BuffTarget"
	target.add_to_group("enemy")
	add_child(target)

	projectile.call("_apply_buff_to_enemy", target)
	assert(target.health == 80)
	assert(target._runtime_attack_damage == 25)
	assert(is_equal_approx(target._runtime_move_speed, 3.6))
	assert(is_equal_approx(target._runtime_chase_speed, 6.0))
	assert(target.has_meta("vex_venom_marshall_buffed"))

	# Aynı alan aynı hedefi tekrar iyileştirmez; stat buff yalnızca süre yeniler.
	projectile.call("_apply_buff_to_enemy", target)
	assert(target.health == 80)
	assert(target._runtime_attack_damage == 25)

	await get_tree().create_timer(0.20).timeout
	assert(target.get_node_or_null("VenomMarshallBuffStatus") == null)
	assert(target._runtime_attack_damage == 20)
	assert(is_equal_approx(target._runtime_move_speed, 3.0))
	assert(is_equal_approx(target._runtime_chase_speed, 5.0))
	assert(not target.has_meta("vex_venom_marshall_buffed"))

	projectile.free()
	target.free()
	for _frame: int in range(3):
		await get_tree().process_frame

	print("Venom Marshall buff runtime test passed")
	get_tree().quit(0)
