@tool
class_name VexPickup
extends Area3D

@export_category("Toplanabilir Nesne")
@export var pickup_id: StringName = &"pickup"
@export_enum("health", "armor", "bullets", "shells", "shotgun", "ak47", "rifle_ammo", "mp90", "mp90_ammo", "night_vision", "key_blue", "key_red") var pickup_type: String = "health"
@export_range(1, 200, 1) var amount := 25
@export var display_name := "NESNE"

@export_category("Zorluk Dağılımı")
@export_range(0, 3, 1) var spawn_max_difficulty := 3
@export var scale_amount_with_difficulty := true
@export var visual_texture: Texture2D:
	set(value):
		visual_texture = value
		_apply_visual()
@export_range(0.001, 0.02, 0.0001) var visual_pixel_size := 0.00255:
	set(value):
		visual_pixel_size = value
		_apply_visual()

@export_category("Görsel Hareket")
@export_range(0.0, 0.5, 0.01) var bob_height := 0.09
@export_range(0.1, 5.0, 0.1) var bob_speed := 1.8

var visual_pivot: Node3D
var visual: Sprite3D
var collision_shape: CollisionShape3D
var pickup_audio: AudioStreamPlayer3D

var _base_pivot_position := Vector3.ZERO
var _phase := 0.0
var _elapsed := 0.0
var _collected := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		if GameState.active_difficulty > spawn_max_difficulty:
			queue_free()
			return
		_apply_difficulty_amount()

	_resolve_scene_nodes()
	_apply_default_texture_for_type()
	_apply_visual()
	if visual == null or visual_pivot == null:
		push_warning("%s: Visual veya VisualPivot/Visual bulunamadı; pickup görseli devre dışı." % get_path())
		set_process(false)
		return
	if Engine.is_editor_hint():
		set_process(false)
		return

	if GameState.was_pickup_collected(pickup_id):
		queue_free()
		return

	_base_pivot_position = visual_pivot.position
	_phase = randf_range(0.0, TAU)
	_elapsed = 0.0
	set_process(true)
	body_entered.connect(_on_body_entered)


func _apply_difficulty_amount() -> void:
	if not scale_amount_with_difficulty:
		return
	if pickup_type in ["shotgun", "ak47", "mp90", "night_vision", "key_blue", "key_red"]:
		return
	var profile := GameState.get_active_difficulty_profile()
	var multiplier := float(profile.get("resource_multiplier", 1.0))
	amount = maxi(1, int(round(float(amount) * multiplier)))


func _apply_default_texture_for_type() -> void:
	if visual_texture != null:
		return
	var candidates: Array[String] = []
	match pickup_type:
		"ak47":
			candidates = [
				"res://assets/pickups/ak47.png",
			]
		"rifle_ammo":
			candidates = [
				"res://assets/pickups/ak47_ammo.png",
			]
		"mp90":
			candidates = [
				"res://assets/pickups/mp90.png",
			]
		"mp90_ammo":
			candidates = [
				"res://assets/pickups/mp90_ammo.png",
			]
		"night_vision":
			candidates = [
				"res://assets/pickups/night_vision.png",
			]
	for candidate: String in candidates:
		if ResourceLoader.exists(candidate):
			visual_texture = load(candidate) as Texture2D
			return

	# Dosya adı uyuşmazsa pickup görünmez kalmasın.
	var fallback := ""
	if pickup_type in ["ak47", "mp90"]:
		fallback = "res://assets/pickups/shotgun.png"
	elif pickup_type in ["rifle_ammo", "mp90_ammo"]:
		fallback = "res://assets/pickups/ammo_bullets.png"
	if not candidates.is_empty() and not fallback.is_empty() and ResourceLoader.exists(fallback):
		visual_texture = load(fallback) as Texture2D


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _collected:
		return

	_elapsed += delta
	var movement_phase := _phase + _elapsed
	visual_pivot.position.y = (
		_base_pivot_position.y
		+ sin(movement_phase * bob_speed) * bob_height
	)


func _on_body_entered(body: Node3D) -> void:
	if _collected or not body.has_method("collect_pickup"):
		return

	var consumed := bool(body.call("collect_pickup", StringName(pickup_type), amount))
	if not consumed:
		GameState.notify("%s KAPASİTESİ DOLU" % display_name)
		return

	_collected = true
	set_process(false)
	GameState.register_pickup_collected(pickup_id)
	set_deferred("monitoring", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	visual.visible = false
	if pickup_audio != null and pickup_audio.stream != null:
		pickup_audio.play()
	call_deferred("_finish_collection")


func _finish_collection() -> void:
	if pickup_audio != null and pickup_audio.stream != null and pickup_audio.playing:
		await pickup_audio.finished
	if is_inside_tree():
		queue_free()


func _resolve_scene_nodes() -> void:
	visual_pivot = get_node_or_null("VisualPivot") as Node3D
	if visual_pivot != null:
		visual = get_node_or_null("VisualPivot/Visual") as Sprite3D

	if visual == null:
		visual = get_node_or_null("Visual") as Sprite3D
		visual_pivot = visual

	collision_shape = get_node_or_null("CollisionShape3D") as CollisionShape3D
	pickup_audio = get_node_or_null("PickupAudio") as AudioStreamPlayer3D


func _apply_visual() -> void:
	if not is_inside_tree():
		return
	var target := get_node_or_null("VisualPivot/Visual") as Sprite3D
	if target == null:
		target = get_node_or_null("Visual") as Sprite3D
	if target != null:
		target.texture = visual_texture
		target.pixel_size = visual_pixel_size
		target.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
		target.double_sided = true
		target.modulate = Color(1, 1, 1, 1)
