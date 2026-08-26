extends VexBaseLevel

const TRAINING_OVERLAY_SCENE := preload("res://scenes/levels/level_01_training_overlay.tscn")

var _training_overlay: Node3D


func _on_level_ready() -> void:
	if TRAINING_OVERLAY_SCENE == null:
		push_error("VEX-01 eğitim overlay sahnesi yüklenemedi.")
		return
	_training_overlay = TRAINING_OVERLAY_SCENE.instantiate() as Node3D
	if _training_overlay == null:
		push_error("VEX-01 eğitim overlay sahnesi instantiate edilemedi.")
		return
	add_child(_training_overlay)


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	var has_blue := keys.has(&"blue")
	var has_red := keys.has(&"red")
	if has_blue and has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_BOTH_KEYS")
	elif has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_RED_ONLY")
	elif has_blue:
		GameState.set_objective("LEVEL01_OBJECTIVE_BLUE_ONLY")
