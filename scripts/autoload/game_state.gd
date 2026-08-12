extends Node

signal player_registered(player: Node)
signal player_stats_changed(health: int, max_health: int, armor: int)
signal weapon_changed(weapon_id: StringName, display_name: String)
signal ammo_changed(current: int, reserve: int)
signal key_inventory_changed(keys: Array[StringName])
signal objective_changed(text: String)
signal notification_requested(text: String)
signal pickup_notification_requested(text: String, category: StringName)
signal level_stats_changed(kills: int, total_enemies: int, secrets: int, total_secrets: int)
signal hit_confirmed
signal damage_received(amount: int)
signal player_died

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const LEVEL_01_PATH := "res://scenes/levels/level_01.tscn"
const LEVEL_02_PATH := "res://scenes/levels/level_02.tscn"
const LEVEL_COMPLETE_PATH := "res://scenes/ui/level_complete.tscn"
const SAVE_PATH := "user://vex_save.cfg"
const SAVE_VERSION := 3
const CHECKPOINTS_ENABLED := false

var player: Node = null
var hud: CanvasLayer = null
var objective := "TESİSTEN ÇIKIŞ YOLUNU BUL"
var kills := 0
var total_enemies := 0
var secrets := 0
var total_secrets := 1
var run_started_msec := 0
var loading_saved_state := false
var saved_run_state: Dictionary = {}
var last_level_summary: Dictionary = {}
var defeated_enemy_ids: Array[StringName] = []
var collected_pickup_ids: Array[StringName] = []
var found_secret_ids: Array[StringName] = []
var active_difficulty := 1
var current_level_path := LEVEL_01_PATH
var pending_next_level_path := ""
var pending_player_restore_state: Dictionary = {}
var current_level_start_state: Dictionary = {}


func start_new_game() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_clear_saved_run()
	loading_saved_state = false
	saved_run_state = {}
	pending_player_restore_state = {}
	current_level_start_state = {}
	pending_next_level_path = ""
	current_level_path = LEVEL_01_PATH
	_reset_level_counters()
	active_difficulty = SettingsManager.difficulty
	run_started_msec = Time.get_ticks_msec()
	get_tree().change_scene_to_file(current_level_path)


func continue_game() -> void:
	if not CHECKPOINTS_ENABLED:
		start_new_game()
		return
	if not _load_run():
		start_new_game()
		return
	get_tree().paused = false
	loading_saved_state = true
	run_started_msec = Time.get_ticks_msec() - int(saved_run_state.get("elapsed_msec", 0))
	get_tree().change_scene_to_file(LEVEL_01_PATH)


func restart_level(_restore_full_health: bool = false) -> void:
	# Kontrol noktaları yok. Oyuncu bulunduğu bölümün en başından başlar.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	loading_saved_state = false
	saved_run_state = {}
	pending_next_level_path = ""
	_reset_level_counters()
	pending_player_restore_state = current_level_start_state.duplicate(true)
	pending_player_restore_state["health"] = 100
	run_started_msec = Time.get_ticks_msec()
	get_tree().change_scene_to_file(current_level_path)


func return_to_main_menu() -> void:
	get_tree().paused = false
	player = null
	hud = null
	pending_next_level_path = ""
	pending_player_restore_state = {}
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func has_save() -> bool:
	return CHECKPOINTS_ENABLED and FileAccess.file_exists(SAVE_PATH)


func checkpoints_enabled() -> bool:
	return CHECKPOINTS_ENABLED


func register_player(value: Node) -> void:
	player = value
	player_registered.emit(player)
	if not pending_player_restore_state.is_empty() and player.has_method("restore_run_state"):
		var restore_state := pending_player_restore_state.duplicate(true)
		pending_player_restore_state = {}
		player.call_deferred("restore_run_state", restore_state)
	elif loading_saved_state and not saved_run_state.is_empty() and player.has_method("restore_run_state"):
		player.call_deferred("restore_run_state", saved_run_state)
	else:
		player.call_deferred("broadcast_state")


func register_hud(value: CanvasLayer) -> void:
	hud = value
	if player != null and is_instance_valid(player) and player.has_method("broadcast_state"):
		player.call_deferred("broadcast_state")
	objective_changed.emit(objective)
	level_stats_changed.emit(kills, total_enemies, secrets, total_secrets)


func begin_level(enemy_count: int, secret_count: int, first_objective: String) -> void:
	total_enemies = enemy_count
	total_secrets = secret_count
	if loading_saved_state:
		objective = str(saved_run_state.get("objective", first_objective))
	else:
		objective = first_objective
		kills = 0
		secrets = 0
	objective_changed.emit(objective)
	level_stats_changed.emit(kills, total_enemies, secrets, total_secrets)


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)


func notify(text: String) -> void:
	notification_requested.emit(text)


func notify_pickup(text: String, category: StringName) -> void:
	pickup_notification_requested.emit(text, category)


func publish_player_stats(health: int, max_health: int, armor: int) -> void:
	player_stats_changed.emit(health, max_health, armor)


func publish_weapon(weapon_id: StringName, display_name: String) -> void:
	weapon_changed.emit(weapon_id, display_name)


func publish_ammo(current: int, reserve: int) -> void:
	ammo_changed.emit(current, reserve)


func publish_keys(keys: Array[StringName]) -> void:
	key_inventory_changed.emit(keys)


func register_enemy_defeated(enemy_id: StringName = &"") -> void:
	if enemy_id != &"" and not defeated_enemy_ids.has(enemy_id):
		defeated_enemy_ids.append(enemy_id)
	kills += 1
	level_stats_changed.emit(kills, total_enemies, secrets, total_secrets)


func was_enemy_defeated(enemy_id: StringName) -> bool:
	return enemy_id != &"" and defeated_enemy_ids.has(enemy_id)


func register_pickup_collected(pickup_id: StringName) -> void:
	if pickup_id != &"" and not collected_pickup_ids.has(pickup_id):
		collected_pickup_ids.append(pickup_id)


func was_pickup_collected(pickup_id: StringName) -> bool:
	return pickup_id != &"" and collected_pickup_ids.has(pickup_id)


func register_secret_found(secret_id: StringName = &"") -> void:
	if secret_id != &"" and found_secret_ids.has(secret_id):
		return
	if secret_id != &"":
		found_secret_ids.append(secret_id)
	secrets = found_secret_ids.size() if not found_secret_ids.is_empty() else secrets + 1
	level_stats_changed.emit(kills, total_enemies, secrets, total_secrets)
	notify("GİZLİ ALAN BULUNDU")


func was_secret_found(secret_id: StringName) -> bool:
	return secret_id != &"" and found_secret_ids.has(secret_id)


func get_active_difficulty_name() -> String:
	return SettingsManager.get_difficulty_display_name(active_difficulty)


func get_active_difficulty_profile() -> Dictionary:
	return SettingsManager.get_difficulty_profile(active_difficulty)


func confirm_hit() -> void:
	hit_confirmed.emit()


func report_damage(amount: int) -> void:
	damage_received.emit(amount)


func report_player_death() -> void:
	player_died.emit()


func save_checkpoint() -> bool:
	if not CHECKPOINTS_ENABLED:
		return false
	if player == null or not is_instance_valid(player) or not player.has_method("capture_run_state"):
		return false
	var state: Dictionary = player.call("capture_run_state")
	state["kills"] = kills
	state["secrets"] = secrets
	state["objective"] = objective
	state["save_version"] = SAVE_VERSION
	state["elapsed_msec"] = Time.get_ticks_msec() - run_started_msec
	state["defeated_enemy_ids"] = defeated_enemy_ids.duplicate()
	state["collected_pickup_ids"] = collected_pickup_ids.duplicate()
	state["found_secret_ids"] = found_secret_ids.duplicate()
	state["difficulty"] = active_difficulty
	var config := ConfigFile.new()
	for key: String in state.keys():
		config.set_value("run", key, state[key])
	var error := config.save(SAVE_PATH)
	if error != OK:
		push_error("VEX kayıt dosyası yazılamadı. Hata kodu: %s" % error)
		return false
	return true


func complete_level(next_level_path: String = "") -> void:
	var elapsed_msec := Time.get_ticks_msec() - run_started_msec
	var level_label := current_level_path.get_file().get_basename().to_upper()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_level_display_name"):
		level_label = str(current_scene.call("get_level_display_name"))

	pending_next_level_path = next_level_path
	if next_level_path != "" and player != null and is_instance_valid(player) and player.has_method("capture_run_state"):
		var carry_state: Dictionary = player.call("capture_run_state")
		carry_state.erase("position")
		carry_state.erase("rotation_y")
		carry_state["keys"] = []
		pending_player_restore_state = carry_state.duplicate(true)
	else:
		pending_player_restore_state = {}

	last_level_summary = {
		"kills": kills,
		"total_enemies": total_enemies,
		"secrets": secrets,
		"total_secrets": total_secrets,
		"elapsed_msec": elapsed_msec,
		"difficulty": get_active_difficulty_name(),
		"level_label": level_label,
	}
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(LEVEL_COMPLETE_PATH)


func has_pending_next_level() -> bool:
	return pending_next_level_path != ""


func continue_to_next_level() -> void:
	if pending_next_level_path == "":
		restart_level()
		return
	var next_path := pending_next_level_path
	var carry_state := pending_player_restore_state.duplicate(true)
	pending_next_level_path = ""
	pending_player_restore_state = {}
	loading_saved_state = false
	saved_run_state = {}
	current_level_path = next_path
	_reset_level_counters()
	current_level_start_state = carry_state.duplicate(true)
	pending_player_restore_state = carry_state
	run_started_msec = Time.get_ticks_msec()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(current_level_path)


func _clear_saved_run() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		var remove_error := DirAccess.remove_absolute(SAVE_PATH)
		if remove_error != OK:
			push_warning("Eski VEX kayıt dosyası silinemedi. Hata kodu: %s" % remove_error)


func _load_run() -> bool:
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		return false
	saved_run_state = {}
	for key: String in config.get_section_keys("run"):
		saved_run_state[key] = config.get_value("run", key)
	if int(saved_run_state.get("save_version", 0)) != SAVE_VERSION:
		saved_run_state = {}
		return false
	kills = int(saved_run_state.get("kills", 0))
	secrets = int(saved_run_state.get("secrets", 0))
	objective = str(saved_run_state.get("objective", "TESİSTEN ÇIKIŞ YOLUNU BUL"))
	defeated_enemy_ids.clear()
	var stored_enemies: Array = saved_run_state.get("defeated_enemy_ids", []) as Array
	for stored_enemy: Variant in stored_enemies:
		defeated_enemy_ids.append(StringName(str(stored_enemy)))
	collected_pickup_ids.clear()
	var stored_pickups: Array = saved_run_state.get("collected_pickup_ids", []) as Array
	for stored_pickup: Variant in stored_pickups:
		collected_pickup_ids.append(StringName(str(stored_pickup)))
	found_secret_ids.clear()
	var stored_secrets: Array = saved_run_state.get("found_secret_ids", []) as Array
	for stored_secret: Variant in stored_secrets:
		found_secret_ids.append(StringName(str(stored_secret)))
	active_difficulty = clampi(
		int(saved_run_state.get("difficulty", SettingsManager.difficulty)),
		SettingsManager.Difficulty.EASY,
		SettingsManager.Difficulty.NIGHTMARE
	)
	return true


func _reset_level_counters() -> void:
	player = null
	hud = null
	objective = "TESİSTEN ÇIKIŞ YOLUNU BUL"
	kills = 0
	total_enemies = 0
	secrets = 0
	total_secrets = 1
	defeated_enemy_ids.clear()
	collected_pickup_ids.clear()
	found_secret_ids.clear()
