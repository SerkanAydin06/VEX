@tool
class_name VexPickup
extends Area3D

@export_category("Toplanabilir Nesne")
@export var pickup_id: StringName = &"pickup"
@export_enum("health", "armor", "bullets", "shells", "p01", "p07", "p14", "p20", "sg04", "sg09", "sg15", "vx47", "rifle_ammo", "mp90", "mp90_ammo", "night_vision", "key_blue", "key_red", "key_yellow") var pickup_type: String = "health"
@export_range(0, 200, 1) var amount := 25
@export var display_name := "NESNE"
@export var persist_collection := true

@export_category("Zorluk Dağılımı")
@export_range(0, 3, 1) var spawn_max_difficulty := 3
@export var scale_amount_with_difficulty := true
@export var difficulty_amount_multipliers := PackedFloat32Array([1.35, 1.0, 0.80, 0.60])

@export_category("Görsel")
@export var visual_texture: Texture2D:
	set(value):
		visual_texture = value
		_apply_visual()
@export_range(0.0001, 0.02, 0.0001) var visual_pixel_size := 0.00055:
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
var _runtime_amount := 0
var _pickup_blocked_until_msec := 0

func _ready() -> void:
	_runtime_amount = amount
	if not Engine.is_editor_hint():
		if GameState.active_difficulty > spawn_max_difficulty:
			queue_free()
			return
		_runtime_amount = _get_runtime_amount()

	_resolve_scene_nodes()
	_apply_visual()
	if Engine.is_editor_hint():
		set_process(false)
		return

	if persist_collection and GameState.was_pickup_collected(pickup_id):
		queue_free()
		return

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	if visual == null or visual_pivot == null:
		push_warning("%s: Visual veya VisualPivot/Visual bulunamadı; pickup görseli devre dışı." % get_path())
		set_process(false)
		return

	_base_pivot_position = visual_pivot.position
	_phase = randf_range(0.0, TAU)
	_elapsed = 0.0
	set_process(true)


func _get_runtime_amount() -> int:
	if not scale_amount_with_difficulty:
		return amount
	if pickup_type in ["p01", "p07", "p14", "p20", "sg04", "sg09", "sg15", "vx47", "mp90", "night_vision", "key_blue", "key_red", "key_yellow"]:
		return amount
	if difficulty_amount_multipliers.is_empty():
		return amount
	var difficulty_index := clampi(
		GameState.active_difficulty,
		0,
		difficulty_amount_multipliers.size() - 1
	)
	var multiplier := maxf(0.0, difficulty_amount_multipliers[difficulty_index])
	return maxi(1, int(round(float(amount) * multiplier)))


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
	if Time.get_ticks_msec() < _pickup_blocked_until_msec:
		return
	if _collected or not body.has_method("collect_pickup"):
		return

	var consumed := bool(body.call("collect_pickup", StringName(pickup_type), _runtime_amount, self))
	if not consumed:
		GameState.notify(tr("PICKUP_CAPACITY_FULL") % tr(display_name))
		return

	_collected = true
	set_process(false)
	if persist_collection:
		GameState.register_pickup_collected(pickup_id)
	set_deferred("monitoring", false)
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if visual != null:
		visual.visible = false
	if pickup_audio != null and pickup_audio.stream != null:
		pickup_audio.play()
	call_deferred("_finish_collection")

func block_pickup_for(duration: float) -> void:
	_pickup_blocked_until_msec = Time.get_ticks_msec() + int(duration * 1000.0)

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
