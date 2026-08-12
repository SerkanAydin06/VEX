class_name VexRavagerProjectile
extends Area3D

@export_range(1.0, 40.0, 0.5) var speed := 11.0
@export_range(0.2, 10.0, 0.1) var lifetime := 4.0
@export_range(0.0, 1.0, 0.01) var impact_surface_offset := 0.32

@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var visual: Sprite3D = $Visual
@onready var impact_visual: Sprite3D = $ImpactVisual
@onready var projectile_light: OmniLight3D = $Light
@onready var impact_audio: AudioStreamPlayer3D = $ImpactAudio

var damage := 10
var direction := Vector3.FORWARD
var source: Node = null
var _active := true


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_expire_later()


func launch(new_direction: Vector3, new_source: Node, new_damage: int) -> void:
	direction = new_direction.normalized()
	source = new_source
	damage = new_damage


func _physics_process(delta: float) -> void:
	if not _active:
		return

	# Area3D'yi yalnızca konumlandırmak, duran bir gövdeye doğru hareket
	# ederken bazı fizik karelerinde body_entered sinyalinin kaçmasına yol
	# açabiliyor. Her karede merminin katettiği yolu tarayarak hem hareketli
	# hem de hareketsiz oyuncuya çarpışmayı güvenilir hâle getir.
	var start_position := global_position
	var end_position := start_position + direction * speed * delta
	var exclusions: Array[RID] = [get_rid()]
	if source is CollisionObject3D:
		exclusions.append((source as CollisionObject3D).get_rid())

	var query := PhysicsRayQueryParameters3D.create(
		start_position,
		end_position,
		collision_mask,
		exclusions
	)
	query.hit_from_inside = true
	query.collide_with_bodies = true
	query.collide_with_areas = false
	var result := get_world_3d().direct_space_state.intersect_ray(query)
	if result.is_empty():
		global_position = end_position
		return

	var hit_position: Vector3 = result.get("position", end_position)
	var hit_normal: Vector3 = result.get("normal", -direction)
	if hit_normal.length_squared() <= 0.001:
		hit_normal = -direction
	global_position = hit_position + hit_normal.normalized() * impact_surface_offset
	var damage_target := _resolve_damage_target(result.get("collider") as Object)
	if damage_target != null:
		damage_target.call("take_damage", damage, global_position, source)
	_impact()


func _on_body_entered(body: Node3D) -> void:
	if not _active or body == source:
		return
	# Küresel çarpışma şekli duvara değdiğinde mermi merkezi yüzeyin içine
	# girmiş olabilir. Patlama görselini geliş yönüne çekerek duvarın önünde tut.
	global_position -= direction * impact_surface_offset
	var damage_target := _resolve_damage_target(body)
	if damage_target != null:
		damage_target.call("take_damage", damage, global_position, source)
	_impact()


func _resolve_damage_target(collider: Object) -> Node:
	if collider is Node and collider.has_method("take_damage"):
		return collider as Node
	if collider is Node:
		var parent := (collider as Node).get_parent()
		if parent != null and parent.has_method("take_damage"):
			return parent
	return null


func _impact() -> void:
	if not _active:
		return
	_active = false
	set_deferred("monitoring", false)
	collision_shape.set_deferred("disabled", true)
	visual.visible = false
	impact_visual.visible = true
	impact_visual.scale = Vector3(0.55, 0.55, 0.55)
	projectile_light.light_energy = 4.0
	if impact_audio.stream != null:
		impact_audio.play()
	var impact_tween := create_tween().set_parallel(true)
	impact_tween.tween_property(impact_visual, "scale", Vector3(1.35, 1.35, 1.35), 0.14)
	impact_tween.tween_property(impact_visual, "modulate:a", 0.0, 0.16)
	impact_tween.tween_property(projectile_light, "light_energy", 0.0, 0.16)
	await impact_tween.finished
	if impact_audio.stream != null and impact_audio.playing:
		await impact_audio.finished
	if is_inside_tree():
		queue_free()


func _expire_later() -> void:
	await get_tree().create_timer(lifetime).timeout
	if is_inside_tree() and _active:
		queue_free()
