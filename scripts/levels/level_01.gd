extends VexBaseLevel

const TRAINING_OVERLAY_SCENE := preload("res://scenes/levels/level_01_training_overlay.tscn")

var _training_overlay: Node3D


func _on_level_ready() -> void:
	_configure_first_fracture_start()
	if TRAINING_OVERLAY_SCENE == null:
		push_error("VEX-01 eğitim overlay sahnesi yüklenemedi.")
		return
	_training_overlay = TRAINING_OVERLAY_SCENE.instantiate() as Node3D
	if _training_overlay == null:
		push_error("VEX-01 eğitim overlay sahnesi instantiate edilemedi.")
		return
	add_child(_training_overlay)


func _configure_first_fracture_start() -> void:
	# Player sahnesi diğer görevler ve test sahneleri için P-01 ile başlar.
	# İlk Kırılma'da ise P-01 R03 güvenlik dolabından fiziksel olarak edinilir.
	# Bu override yalnız kampanyanın ilk aşamasında çalışır; tamamlanmış kampanya
	# ile olası tekrar girişlerde taşınan loadout'a dokunmaz.
	if GameState.campaign_stage != 0 or player == null:
		return
	var weapon_controller := player.get_node_or_null("WeaponController") as VexWeaponController
	if weapon_controller == null:
		push_warning("VEX-01 silahsız başlangıç için WeaponController bulunamadı.")
		return
	weapon_controller.unlocked_weapons.clear()
	weapon_controller.acquired_weapons.clear()
	weapon_controller.current_weapon_id = &""
	weapon_controller.magazines[&"p01"] = 0
	weapon_controller.reserve_ammo[&"bullets"] = 0
	weapon_controller.reserve_ammo[&"shells"] = 0
	weapon_controller.reserve_ammo[&"rifle_ammo"] = 0
	weapon_controller.reserve_ammo[&"mp90_ammo"] = 0
	weapon_controller.flashlight_enabled = false
	weapon_controller.broadcast_state()


func _on_key_inventory_changed(keys: Array[StringName]) -> void:
	var has_blue := keys.has(&"blue")
	var has_red := keys.has(&"red")
	if has_blue and has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_BOTH_KEYS")
	elif has_red:
		GameState.set_objective("LEVEL01_OBJECTIVE_RED_ONLY")
	elif has_blue:
		GameState.set_objective("LEVEL01_OBJECTIVE_BLUE_ONLY")
