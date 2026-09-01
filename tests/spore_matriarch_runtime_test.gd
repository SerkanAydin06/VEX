extends Node

const PROJECTILE_SCENE := preload("res://scenes/actors/spore_matriarch_projectile.tscn")
const POISON_STATUS := preload("res://scripts/actors/spore_poison_status.gd")

class DummyTarget:
	extends Node3D
	var damage_taken := 0

	func take_damage(amount: int, _hit_position := Vector3.ZERO, _source: Node = null) -> void:
		damage_taken += amount


func _ready() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as VexSporeMatriarchProjectile
	assert(projectile != null)
	add_child(projectile)

	# Bu regression alan/zehir lifecycle'ını doğrular. Headless dummy ses sürücüsü
	# çok kısa test çıkışında aktif WAV playback kaynağını bir kare daha tuttuğu
	# için ses yan etkisini fixture'da izole et; canonical projectile sahnesi değişmez.
	var deploy_audio := projectile.get_node_or_null("DeployAudio") as AudioStreamPlayer3D
	if deploy_audio != null:
		deploy_audio.stop()
		deploy_audio.stream = null

	projectile.launch(Vector3.FORWARD, self, 12)
	assert(is_equal_approx(projectile.get_field_radius(), 5.2))
	projectile.call("_deploy_field", Vector3.ZERO, null)
	assert(projectile.is_field_active())

	var target := DummyTarget.new()
	target.name = "PoisonTarget"
	target.add_to_group("player")
	add_child(target)
	var status := POISON_STATUS.new() as VexSporePoisonStatus
	status.name = "SporePoisonStatus"
	target.add_child(status)
	status.refresh_poison(0.34, 5, 0.10, null)
	assert(status.get_remaining_time() > 0.0)
	assert(status.get_tick_damage() == 5)

	await get_tree().create_timer(0.26).timeout
	assert(target.damage_taken >= 10)

	# Test fixture'larını synchronous temizle; çıkışta sahne/material/status
	# referansı bırakma.
	projectile.free()
	target.free()
	for _frame: int in range(4):
		await get_tree().process_frame

	print("Spore Matriarch poison runtime test passed")
	get_tree().quit(0)
