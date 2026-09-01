extends VexBaseLevel

const MAGMA_MAULER_PILOT: PackedScene = preload("res://scenes/experimental/magma_mauler.tscn")


func _ready() -> void:
	_spawn_magma_mauler_pilot()
	super._ready()


func _spawn_magma_mauler_pilot() -> void:
	var enemies := get_node_or_null("Enemies") as Node3D
	if enemies == null:
		push_warning("Level Test Enemies düğümü bulunamadı; Magma Mauler pilotu spawn edilmedi.")
		return
	var mauler := MAGMA_MAULER_PILOT.instantiate() as Node3D
	if mauler == null:
		push_warning("Magma Mauler pilot sahnesi instantiate edilemedi.")
		return
	mauler.name = "MagmaMaulerPilot"
	mauler.position = Vector3(0.0, 1.22, -10.0)
	mauler.set("enemy_id", &"level_test_magma_mauler")
	mauler.set("maximum_health", 500)
	enemies.add_child(mauler)


func _show_briefing() -> void:
	GameState.notify("LEVEL TEST • 5x5 TEST ALANI • TÜM GÜNCEL SİLAH VE DÜŞMANLAR")
