extends Node

const PROJECTILE_SCENE := preload("res://scenes/actors/spore_matriarch_projectile.tscn")

class DummyTarget:
	extends Node3D
	var damage_taken := 0
	var last_source: Node = null

	func take_damage(amount: int, _hit_position := Vector3.ZERO, source: Node = null) -> void:
		damage_taken += amount
		last_source = source


func _ready() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as VexSporeMatriarchProjectile
	assert(projectile != null)
	projectile.field_radius = 4.4
	projectile.poison_duration = 0.34
	projectile.poison_tick_interval = 0.10
	add_child(projectile)

	# Bu regression alan/zehir lifecycle'ını doğrular. Headless dummy ses sürücüsü
	# çok kısa test çıkışında aktif WAV playback kaynağını bir kare daha tuttuğu
	# için ses yan etkisini fixture'da izole et; canonical projectile sahnesi değişmez.
	var deploy_audio := projectile.get_node_or_null("DeployAudio") as AudioStreamPlayer3D
	if deploy_audio != null:
		deploy_audio.stop()
		deploy_audio.stream = null

	# Inspector field_radius fizik alanı, disk görseli ve ışık menzilinin tek
	# otoritesi olmalı; scene subresource sabitleri tuning'i ezmemeli.
	assert(is_equal_approx(projectile.get_field_radius(), 4.4))
	var field_collision := projectile.get_node("FieldCollision") as CollisionShape3D
	var field_shape := field_collision.shape as CylinderShape3D
	assert(field_shape != null)
	assert(is_equal_approx(field_shape.radius, 4.4))
	var field_disc := projectile.get_node("FieldDisc") as MeshInstance3D
	var field_mesh := field_disc.mesh as CylinderMesh
	assert(field_mesh != null)
	assert(is_equal_approx(field_mesh.top_radius, 4.4))
	assert(is_equal_approx(field_mesh.bottom_radius, 4.4))
	var field_light := projectile.get_node("FieldLight") as OmniLight3D
	assert(is_equal_approx(field_light.omni_range, 5.4))

	var source := Node3D.new()
	source.name = "TemporarySporeSource"
	add_child(source)
	projectile.launch(Vector3.FORWARD, source, 12)

	var target := DummyTarget.new()
	target.name = "PoisonTarget"
	target.add_to_group("player")
	add_child(target)

	# Kaynak yaratık alan/DoT bitmeden sahneden çıkarsa freed Node referansı hasar
	# API'sine taşınmamalı. Projectile ve status bu durumda null source ile devam eder.
	source.free()
	projectile.call("_deploy_field", Vector3.ZERO, target)
	assert(projectile.is_field_active())
	assert(target.damage_taken == 3)
	assert(target.last_source == null)

	var status := target.get_node_or_null("SporePoisonStatus") as VexSporePoisonStatus
	assert(status != null)
	assert(status.get_remaining_time() > 0.0)
	assert(status.get_tick_damage() == 4)

	await get_tree().create_timer(0.26).timeout
	assert(target.damage_taken >= 11)
	assert(target.last_source == null)

	# Test fixture'larını synchronous temizle; çıkışta sahne/material/status
	# referansı bırakma.
	projectile.free()
	target.free()
	for _frame: int in range(4):
		await get_tree().process_frame

	print("Spore Matriarch poison runtime test passed")
	get_tree().quit(0)
