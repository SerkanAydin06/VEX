extends VexBaseLevel

const LOOM_HERALD_SCENE := preload("res://scenes/actors/loom_herald.tscn")
const LOOM_HERALD_ENEMY_ID := &"vex03_upper_loom_herald"
const LOOM_HERALD_ROOT_CLEARANCE := 0.98

var _alarm_triggered := false


func _ready() -> void:
	_spawn_loom_herald()
	super._ready()


func _spawn_loom_herald() -> void:
	var enemies := get_node_or_null("Enemies") as Node3D
	var spawn_marker := get_node_or_null(
		"Geometry/UpperLevel/Room_U01_StairLanding"
	) as Marker3D
	if enemies == null or spawn_marker == null or enemies.has_node("UpperLoomHerald"):
		return
	var loom_herald := LOOM_HERALD_SCENE.instantiate() as Node3D
	if loom_herald == null:
		return
	loom_herald.name = "UpperLoomHerald"
	loom_herald.set("enemy_id", LOOM_HERALD_ENEMY_ID)
	var local_transform := enemies.global_transform.affine_inverse() * spawn_marker.global_transform
	local_transform.origin += Vector3.UP * LOOM_HERALD_ROOT_CLEARANCE
	loom_herald.transform = local_transform
	enemies.add_child(loom_herald)


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	if keys.has(&"red"):
		GameState.set_objective("LEVEL03_OBJECTIVE_RED")
	elif keys.has(&"blue"):
		GameState.set_objective("LEVEL03_OBJECTIVE_BLUE")


func _on_gunshot_emitted(_position: Vector3, _loudness: float, source: Node) -> void:
	if _alarm_triggered or source == null:
		return
	_alarm_triggered = true
	GameState.notify("LEVEL03_GUNSHOT_ALARM")
