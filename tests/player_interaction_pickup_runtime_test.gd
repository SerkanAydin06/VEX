extends Node

var _failures: Array[String] = []


class DummyInteractable:
	extends Node
	var interactions := 0
	var last_actor: Node = null

	func interact(actor: Node) -> void:
		interactions += 1
		last_actor = actor

	func get_interaction_text(_actor: Node) -> String:
		return "TEST_PROMPT"


class DummyWeaponController:
	extends RefCounted
	var ammo := 0
	var ammo_capacity := 10
	var world_weapon_calls := 0
	var direct_unlocks: Array[StringName] = []
	var world_result := {
		"success": true,
		"weapon_id": &"p20",
		"displaced_weapon_id": &"p01",
	}

	func add_ammo(_ammo_type: StringName, amount: int) -> int:
		if amount <= 0 or ammo >= ammo_capacity:
			return 0
		var accepted := mini(amount, ammo_capacity - ammo)
		ammo += accepted
		return accepted

	func equip_world_weapon(_weapon_id: StringName, _bonus_ammo: int) -> Dictionary:
		world_weapon_calls += 1
		return world_result.duplicate(true)

	func unlock_weapon(weapon_id: StringName, _bonus_ammo: int) -> void:
		direct_unlocks.append(weapon_id)


func _ready() -> void:
	_test_interaction_runtime()
	_test_pickup_runtime()
	await _test_pickup_without_visual_stays_collectible()
	if not _failures.is_empty():
		for failure in _failures:
			push_error(failure)
		get_tree().quit(1)
		return
	print("PLAYER INTERACTION PICKUP RUNTIME TEST: OK")
	get_tree().quit(0)


func _test_interaction_runtime() -> void:
	var runtime := VexPlayerInteractionRuntime.new()
	var actor := Node.new()
	var direct := DummyInteractable.new()
	_expect(runtime.try_interact(direct, actor), "Direct interactable çağrılamıyor")
	_expect(direct.interactions == 1, "Direct interactable etkileşim sayısı değişti")
	_expect(direct.last_actor == actor, "Direct interactable actor kontratı değişti")
	_expect(runtime.get_interaction_prompt(direct, actor) == "TEST_PROMPT", "Direct prompt çözümü değişti")

	var parent := DummyInteractable.new()
	var child := Node.new()
	parent.add_child(child)
	_expect(runtime.resolve_interactable(child) == parent, "Collider parent interactable çözülmüyor")
	_expect(runtime.try_interact(child, actor), "Parent interactable çağrılamıyor")
	_expect(parent.interactions == 1, "Parent interactable etkileşim sayısı değişti")
	_expect(runtime.get_interaction_prompt(child, actor) == "TEST_PROMPT", "Parent prompt çözümü değişti")

	actor.free()
	direct.free()
	parent.free()


func _test_pickup_runtime() -> void:
	var runtime := VexPlayerPickupRuntime.new()
	var initial_keys: Array[StringName] = []
	runtime.initialize(initial_keys, false)
	var survivability := VexPlayerSurvivabilityRuntime.new()
	survivability.initialize(100, 100, 0, 0.60, 0.90)
	survivability.apply_damage(50, false)
	var weapons := DummyWeaponController.new()

	var health_result := runtime.collect_pickup(&"health", 25, survivability, weapons)
	_expect(bool(health_result.get("success", false)), "Health pickup runtime tarafından kabul edilmiyor")
	_expect(int(health_result.get("collected_amount", 0)) == 25, "Health pickup accepted amount değişti")
	_expect(survivability.get_health() == 75, "Health pickup survivability state'ini güncellemiyor")

	var armor_result := runtime.collect_pickup(&"armor", 150, survivability, weapons)
	_expect(bool(armor_result.get("success", false)), "Armor pickup runtime tarafından kabul edilmiyor")
	_expect(int(armor_result.get("collected_amount", 0)) == 100, "Armor pickup clamp değişti")
	_expect(survivability.get_armor() == 100, "Armor pickup survivability state'ini güncellemiyor")
	_expect(not bool(runtime.collect_pickup(&"armor", 1, survivability, weapons).get("success", false)), "Dolu armor pickup tüketiliyor")

	var ammo_result := runtime.collect_pickup(&"bullets", 12, survivability, weapons)
	_expect(bool(ammo_result.get("success", false)), "Ammo pickup runtime tarafından kabul edilmiyor")
	_expect(int(ammo_result.get("collected_amount", 0)) == 10, "Ammo accepted amount controller sonucunu korumuyor")
	_expect(not bool(runtime.collect_pickup(&"bullets", 1, survivability, weapons).get("success", false)), "Dolu ammo pickup tüketiliyor")

	var world_result := runtime.collect_pickup(&"p20", 0, survivability, weapons)
	_expect(bool(world_result.get("success", false)), "World weapon pickup sonucu kayboldu")
	_expect(StringName(str(world_result.get("weapon_id", ""))) == &"p20", "World weapon id sonucu değişti")
	_expect(StringName(str(world_result.get("displaced_weapon_id", ""))) == &"p01", "Displaced weapon sonucu kayboldu")
	_expect(weapons.world_weapon_calls == 1, "World weapon controller çağrısı değişti")

	var direct_result := runtime.collect_pickup(&"vx47", 20, survivability, weapons)
	_expect(bool(direct_result.get("success", false)), "Direct weapon pickup sonucu kayboldu")
	_expect(weapons.direct_unlocks == [&"vx47"], "Direct weapon unlock çağrısı değişti")

	_expect(bool(runtime.collect_pickup(&"night_vision", 1, survivability, weapons).get("success", false)), "Night vision ilk pickup kabul edilmiyor")
	_expect(runtime.owns_night_vision(), "Night vision ownership tutulmuyor")
	_expect(not bool(runtime.collect_pickup(&"night_vision", 1, survivability, weapons).get("success", false)), "Night vision tekrar tüketiliyor")

	_expect(bool(runtime.collect_pickup(&"key_blue", 1, survivability, weapons).get("success", false)), "Blue key pickup kabul edilmiyor")
	_expect(runtime.has_key(&"blue"), "Blue key ownership tutulmuyor")
	_expect(not bool(runtime.collect_pickup(&"key_blue", 1, survivability, weapons).get("success", false)), "Aynı key tekrar tüketiliyor")

	runtime.restore_state(["blue", "blue", "invalid", "red"], true)
	_expect(runtime.get_keys() == [&"blue", &"red"], "Restore key sanitization değişti")
	_expect(runtime.owns_night_vision(), "Restore night vision ownership değişti")
	_expect(not bool(runtime.collect_pickup(&"unknown", 1, survivability, weapons).get("success", false)), "Bilinmeyen pickup tüketiliyor")


func _test_pickup_without_visual_stays_collectible() -> void:
	var pickup := VexPickup.new()
	pickup.persist_collection = false
	pickup.scale_amount_with_difficulty = false
	add_child(pickup)
	await get_tree().process_frame
	var collection_callable := Callable(pickup, "_on_body_entered")
	_expect(
		pickup.is_connected(&"body_entered", collection_callable),
		"Görselsiz pickup body_entered bağlantısını kaybediyor"
	)
	pickup.queue_free()
	await get_tree().process_frame


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
