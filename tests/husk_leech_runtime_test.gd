extends Node

const PROJECTILE_SCENE := preload("res://scenes/actors/husk_leech_projectile.tscn")
const OVERLAY_NAME := "HuskLeechVenomOverlay"


class DummyPlayer:
	extends Node3D
	var damage_taken := 0
	var last_source: Node = null

	func take_damage(amount: int, _hit_position := Vector3.ZERO, source: Node = null) -> void:
		damage_taken += amount
		last_source = source


func _spawn_projectile(damage: int, duration: float, peak_alpha: float) -> VexHuskLeechProjectile:
	var projectile := PROJECTILE_SCENE.instantiate() as VexHuskLeechProjectile
	assert(projectile != null)
	projectile.venom_overlay_duration = duration
	projectile.venom_overlay_peak_alpha = peak_alpha
	add_child(projectile)
	projectile.launch(Vector3.FORWARD, self, damage)

	var impact_audio := projectile.get_node_or_null("ImpactAudio") as AudioStreamPlayer3D
	if impact_audio != null:
		impact_audio.stop()
		impact_audio.stream = null
	return projectile


func _ready() -> void:
	var target := DummyPlayer.new()
	target.name = "HuskLeechRuntimePlayer"
	target.add_to_group("player")
	add_child(target)

	var first_projectile := _spawn_projectile(17, 5.0, 0.80)
	first_projectile.call("_on_body_entered", target)
	assert(target.damage_taken == 17)
	assert(target.last_source == self)

	var overlay := target.get_node_or_null(OVERLAY_NAME) as VexHuskLeechVenomOverlay
	assert(overlay != null)
	assert(overlay.layer == 96)

	var shade := overlay.get_node("PoisonShade") as ColorRect
	var decal := overlay.get_node("PoisonDecal") as TextureRect
	assert(shade != null)
	assert(decal != null)
	assert(shade.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(decal.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	assert(decal.stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert(is_equal_approx(decal.modulate.a, 0.80))

	var atlas := decal.texture as AtlasTexture
	assert(atlas != null)
	assert(atlas.region == Rect2(0.0, 0.0, 418.0, 235.0))
	var overlay_instance_id := overlay.get_instance_id()

	# Gerçek zaman beklemeden 5 saniyelik sekansı elle ilerlet. İlk dört kare
	# toplam 3 saniye (0.75 sn/kare), son dört kare toplam 2 saniye (0.5 sn/kare).
	overlay.set_process(false)
	overlay.call("_process", 2.99)
	assert(atlas.region == Rect2(1254.0, 0.0, 418.0, 235.0))
	overlay.call("_process", 0.02)
	assert(atlas.region == Rect2(1672.0, 0.0, 418.0, 235.0))
	overlay.call("_process", 1.98)
	assert(atlas.region == Rect2(2926.0, 0.0, 418.0, 235.0))

	# İkinci isabet yeni CanvasLayer üretmemeli; aynı overlay ilk kareye dönüp
	# yeniden tam 5 saniyelik sekansla başlamalı.
	var second_projectile := _spawn_projectile(11, 5.0, 0.65)
	second_projectile.call("_on_body_entered", target)
	assert(target.damage_taken == 28)
	assert(target.last_source == self)

	var refreshed_overlay := target.get_node_or_null(OVERLAY_NAME) as VexHuskLeechVenomOverlay
	assert(refreshed_overlay != null)
	assert(refreshed_overlay.get_instance_id() == overlay_instance_id)
	var refreshed_decal := refreshed_overlay.get_node("PoisonDecal") as TextureRect
	var refreshed_atlas := refreshed_decal.texture as AtlasTexture
	assert(refreshed_atlas != null)
	assert(refreshed_atlas.region == Rect2(0.0, 0.0, 418.0, 235.0))
	assert(is_equal_approx(refreshed_decal.modulate.a, 0.65))

	var overlay_count := 0
	for child: Node in target.get_children():
		if child.name == OVERLAY_NAME:
			overlay_count += 1
	assert(overlay_count == 1)

	refreshed_overlay.set_process(false)
	refreshed_overlay.call("_process", 5.0)
	await get_tree().process_frame
	assert(target.get_node_or_null(OVERLAY_NAME) == null)

	if is_instance_valid(first_projectile):
		first_projectile.free()
	if is_instance_valid(second_projectile):
		second_projectile.free()
	target.free()
	for _frame: int in range(3):
		await get_tree().process_frame

	print("Husk Leech runtime test passed")
	get_tree().quit(0)
