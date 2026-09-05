extends VexBaseLevel

const LOOM_HERALD_SCENE := preload("res://scenes/actors/loom_herald.tscn")
const LOOM_HERALD_TEST_ID := &"level_test_loom_herald"
const LOOM_HERALD_ROOT_CLEARANCE := 0.98


func _ready() -> void:
	_spawn_loom_herald()
	super._ready()


func _spawn_loom_herald() -> void:
	var enemies := get_node_or_null("Enemies") as Node3D
	var room := get_node_or_null("Geometry/Room_C0_R2") as Node3D
	if enemies == null or room == null or enemies.has_node("LoomHerald"):
		return
	var loom_herald := LOOM_HERALD_SCENE.instantiate() as Node3D
	if loom_herald == null:
		return
	loom_herald.name = "LoomHerald"
	loom_herald.set("enemy_id", LOOM_HERALD_TEST_ID)
	var local_transform := enemies.global_transform.affine_inverse() * room.global_transform
	local_transform.origin += Vector3.UP * LOOM_HERALD_ROOT_CLEARANCE
	loom_herald.transform = local_transform
	enemies.add_child(loom_herald)


func _show_briefing() -> void:
	GameState.notify("LEVEL TEST • 5x5 TEST ALANI • TÜM GÜNCEL SİLAH VE DÜŞMANLAR")
