extends Node

signal player_registered(player: Node)
signal player_stats_changed(health: int, max_health: int, armor: int)
signal player_stamina_changed(current: float, maximum: float, sprinting: bool)
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
signal hub_mission_changed(path: String, label: String)
signal noise_emitted(position: Vector3, loudness: float, source: Node)
signal gunshot_emitted(position: Vector3, loudness: float, source: Node)
signal headshot_confirmed

const MAIN_MENU_PATH := "res://scenes/ui/main_menu.tscn"
const LEVEL_01_PATH := "res://scenes/levels/level_01.tscn"
const LEVEL_02_PATH := "res://scenes/levels/level_02.tscn"
const BASTION_7_PATH := "res://scenes/hub/bastion_7.tscn"
const LEVEL_COMPLETE_PATH := "res://scenes/ui/level_complete.tscn"
const SAVE_PATH := "user://vex_save.cfg"
const SAVE_TEMP_PATH := "user://vex_save.tmp"
const SAVE_BACKUP_PATH := "user://vex_save.bak"
const SAVE_VERSION := 4
const CHECKPOINTS_ENABLED := true

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
var campaign_stage := 0
var hub_selected_mission_path := ""
var hub_selected_mission_label := ""
var _save_request_pending := false


func start_new_game() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_clear_saved_run()
	loading_saved_state = false
	saved_run_state = {}
	pending_player_restore_state = {}
	current_level_start_state = {}
	pending_next_level_path = ""
	hub_selected_mission_path = ""
	hub_selected_mission_label = ""
	campaign_stage = 0
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
	pending_player_restore_state = {}
	get_tree().paused = false
	loading_saved_state = true
	run_started_msec = Time.get_ticks_msec() - int(saved_run_state.get("elapsed_msec", 0))
	current_level_path = str(saved_run_state.get("current_level_path", LEVEL_01_PATH))
	if not ResourceLoader.exists(current_level_path):
		start_new_game()
		return
	var resume_mode := str(saved_run_state.get("resume_mode", "level"))
	if resume_mode == "transition":
		loading_saved_state = false
		pending_player_restore_state = (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)
		current_level_start_state = pending_player_restore_state.duplicate(true)
		_reset_level_counters()
		current_level_path = str(saved_run_state.get("current_level_path", LEVEL_01_PATH))
		pending_player_restore_state = (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)
		get_tree().change_scene_to_file(current_level_path)
		return
	get_tree().change_scene_to_file(current_level_path)


func restart_level(_restore_full_health: bool = false) -> void:
	# Legacy restart: bölümü mevcut bölüm başlangıcından açar.
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	loading_saved_state = false
	saved_run_state = {}
	pending_next_level_path = ""
	pending_player_restore_state = {}
	_reset_level_counters()
	pending_player_restore_state = current_level_start_state.duplicate(true)
	pending_player_restore_state["health"] = 100 if _restore_full_health else int(pending_player_restore_state.get("health", 100))
	run_started_msec = Time.get_ticks_msec()
	get_tree().change_scene_to_file(current_level_path)


func restart_checkpoint() -> void:
	pending_player_restore_state = {}
	if not CHECKPOINTS_ENABLED or not has_save():
		restart_level(false)
		return
	if not _load_run():
		restart_level(false)
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	loading_saved_state = true
	run_started_msec = Time.get_ticks_msec() - int(saved_run_state.get("elapsed_msec", 0))
	current_level_path = str(saved_run_state.get("current_level_path", LEVEL_01_PATH))
	if not ResourceLoader.exists(current_level_path):
		restart_level(false)
		return
	var resume_mode := str(saved_run_state.get("resume_mode", "level"))
	if resume_mode == "transition":
		loading_saved_state = false
		pending_player_restore_state = (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)
		get_tree().change_scene_to_file(current_level_path)
		return
	get_tree().change_scene_to_file(current_level_path)


func return_to_main_menu() -> void:
	get_tree().paused = false
	player = null
	hud = null
	pending_next_level_path = ""
	pending_player_restore_state = {}
	hub_selected_mission_path = ""
	hub_selected_mission_label = ""
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func has_save() -> bool:
	return CHECKPOINTS_ENABLED and (FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH))


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
	# Her bölümün girişini güvenli checkpoint olarak kaydet. Oyuncu hazır olduktan
	# sonra ertelenmiş çağrı ile save alınır; HUD/weapon state eksik kalmaz.
	# Save the exact state at the level entry so Restart Level is deterministic.
	call_deferred("_capture_level_start_state")
	if CHECKPOINTS_ENABLED:
		call_deferred("save_checkpoint")


func _capture_level_start_state() -> void:
	if player == null or not is_instance_valid(player) or not player.has_method("capture_run_state"):
		return
	current_level_start_state = player.call("capture_run_state").duplicate(true)


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)
	_request_checkpoint_save()


func notify(text: String) -> void:
	notification_requested.emit(text)


func notify_pickup(text: String, category: StringName) -> void:
	pickup_notification_requested.emit(text, category)


func publish_player_stats(health: int, max_health: int, armor: int) -> void:
	player_stats_changed.emit(health, max_health, armor)


func publish_player_stamina(current: float, maximum: float, sprinting: bool) -> void:
	player_stamina_changed.emit(current, maximum, sprinting)


func publish_weapon(weapon_id: StringName, display_name: String) -> void:
	weapon_changed.emit(weapon_id, display_name)


func publish_ammo(current: int, reserve: int) -> void:
	ammo_changed.emit(current, reserve)


func publish_keys(keys: Array[StringName]) -> void:
	key_inventory_changed.emit(keys)


func register_enemy_defeated(enemy_id: StringName = &"") -> void:
	if enemy_id != &"" and defeated_enemy_ids.has(enemy_id):
		return
	if enemy_id != &"":
		defeated_enemy_ids.append(enemy_id)
	kills += 1
	level_stats_changed.emit(kills, total_enemies, secrets, total_secrets)
	_request_checkpoint_save()


func was_enemy_defeated(enemy_id: StringName) -> bool:
	return enemy_id != &"" and defeated_enemy_ids.has(enemy_id)


func register_pickup_collected(pickup_id: StringName) -> void:
	if pickup_id == &"" or collected_pickup_ids.has(pickup_id):
		return
	collected_pickup_ids.append(pickup_id)
	_request_checkpoint_save()


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
	_request_checkpoint_save()


func was_secret_found(secret_id: StringName) -> bool:
	return secret_id != &"" and found_secret_ids.has(secret_id)


func get_active_difficulty_name() -> String:
	return SettingsManager.get_difficulty_display_name(active_difficulty)


func get_active_difficulty_profile() -> Dictionary:
	return SettingsManager.get_difficulty_profile(active_difficulty)


func confirm_hit() -> void:
	hit_confirmed.emit()


func confirm_headshot() -> void:
	headshot_confirmed.emit()


func emit_noise(position: Vector3, loudness: float, source: Node = null) -> void:
	if loudness <= 0.0:
		return
	noise_emitted.emit(position, loudness, source)


func emit_gunshot(position: Vector3, loudness: float, source: Node = null) -> void:
	if loudness <= 0.0:
		return
	noise_emitted.emit(position, loudness, source)
	gunshot_emitted.emit(position, loudness, source)


func report_damage(amount: int) -> void:
	damage_received.emit(amount)


func report_player_death() -> void:
	player_died.emit()


func save_checkpoint(reason: String = "checkpoint") -> bool:
	if not CHECKPOINTS_ENABLED:
		return false
	if player == null or not is_instance_valid(player) or not player.has_method("capture_run_state"):
		return false
	var player_state: Dictionary = player.call("capture_run_state")
	var state := _build_save_state(player_state, reason, "level")
	state["current_level_path"] = current_level_path
	var config := ConfigFile.new()
	for key: String in state.keys():
		config.set_value("run", key, state[key])
	return _write_save_config(config)


func _build_save_state(player_state: Dictionary, reason: String, resume_mode: String) -> Dictionary:
	var state := {
		"save_version": SAVE_VERSION,
		"save_reason": reason,
		"saved_unix_time": Time.get_unix_time_from_system(),
		"elapsed_msec": Time.get_ticks_msec() - run_started_msec,
		"current_level_path": current_level_path,
		"resume_mode": resume_mode,
		"resume_player_state": player_state.duplicate(true),
		"kills": kills,
		"secrets": secrets,
		"objective": objective,
		"defeated_enemy_ids": defeated_enemy_ids.duplicate(),
		"collected_pickup_ids": collected_pickup_ids.duplicate(),
		"found_secret_ids": found_secret_ids.duplicate(),
		"difficulty": active_difficulty,
		"campaign_stage": campaign_stage,
		"hub_selected_mission_path": hub_selected_mission_path,
		"hub_selected_mission_label": hub_selected_mission_label,
	}
	# Eski save formatıyla uyumluluk için oyuncu alanlarını üst seviyede de tut.
	for key: String in player_state.keys():
		state[key] = player_state[key]
	return state


func _write_save_config(config: ConfigFile) -> bool:
	var temp_error := config.save(SAVE_TEMP_PATH)
	if temp_error != OK:
		push_error("VEX geçici kayıt dosyası yazılamadı. Hata kodu: %s" % temp_error)
		return false

	# Önce mevcut sağlam kaydı yedeğe taşı. Yeni kayıt yarım kalırsa .bak kullanılabilir.
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		DirAccess.remove_absolute(SAVE_BACKUP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)
		if backup_error != OK:
			push_warning("VEX eski kayıt yedeklenemedi. Hata kodu: %s" % backup_error)

	var rename_error := DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if rename_error != OK:
		# Eski kayıt hâlâ duruyorsa mümkün olduğunca geri getir.
		if not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.rename_absolute(SAVE_BACKUP_PATH, SAVE_PATH)
		push_error("VEX kayıt dosyası etkinleştirilemedi. Hata kodu: %s" % rename_error)
		return false

	return true


func _request_checkpoint_save() -> void:
	if not CHECKPOINTS_ENABLED or _save_request_pending:
		return
	if player == null or not is_instance_valid(player):
		return
	_save_request_pending = true
	call_deferred("_flush_checkpoint_save")


func _flush_checkpoint_save() -> void:
	_save_request_pending = false
	if not is_inside_tree() or player == null or not is_instance_valid(player):
		return
	save_checkpoint("auto")


func complete_level(next_level_path: String = "") -> void:
	var elapsed_msec := Time.get_ticks_msec() - run_started_msec
	var level_label := current_level_path.get_file().get_basename().to_upper()
	var current_scene := get_tree().current_scene
	if current_scene != null and current_scene.has_method("get_level_display_name"):
		level_label = str(current_scene.call("get_level_display_name"))

	_register_campaign_completion(current_scene)
	pending_next_level_path = next_level_path
	if next_level_path != "" and player != null and is_instance_valid(player) and player.has_method("capture_run_state"):
		var carry_state: Dictionary = player.call("capture_run_state")
		carry_state.erase("position")
		carry_state.erase("rotation_y")
		carry_state["keys"] = []
		pending_player_restore_state = carry_state.duplicate(true)
		# Bölüm geçişini de diske kaydet. Böylece level complete ekranında oyun kapanırsa
		# oyuncu tamamladığı bölümü tekrar etmek zorunda kalmaz.
		current_level_path = next_level_path
		var transition_state := _build_save_state(carry_state, "level_complete", "transition")
		transition_state["resume_player_state"] = carry_state.duplicate(true)
		var config := ConfigFile.new()
		for key: String in transition_state.keys():
			config.set_value("run", key, transition_state[key])
		_write_save_config(config)
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


func pending_next_is_hub() -> bool:
	return pending_next_level_path == BASTION_7_PATH


func select_hub_mission(mission_path: String, mission_label: String) -> bool:
	if mission_path.is_empty():
		hub_selected_mission_path = ""
		hub_selected_mission_label = ""
		hub_mission_changed.emit("", "")
		notify("BASTION-7 // YENİ OPERASYON HENÜZ HAZIR DEĞİL")
		return false
	hub_selected_mission_path = mission_path
	hub_selected_mission_label = mission_label
	hub_mission_changed.emit(hub_selected_mission_path, hub_selected_mission_label)
	notify("OPERASYON SEÇİLDİ // %s" % hub_selected_mission_label)
	set_objective("OPERASYON TERMİNALİNDEN GÖREVE ÇIK")
	return true


func has_hub_selected_mission() -> bool:
	return not hub_selected_mission_path.is_empty()


func get_hub_selected_mission_label() -> String:
	return hub_selected_mission_label


func deploy_selected_hub_mission() -> bool:
	if hub_selected_mission_path.is_empty():
		notify("ÖNCE OPERASYON TERMİNALİNDEN GÖREV SEÇ")
		set_objective("OPERASYON TERMİNALİNİ KULLAN")
		return false

	var carry_state: Dictionary = {}
	if player != null and is_instance_valid(player) and player.has_method("capture_run_state"):
		carry_state = player.call("capture_run_state")
		carry_state.erase("position")
		carry_state.erase("rotation_y")
		carry_state["keys"] = []

	var next_path := hub_selected_mission_path
	hub_selected_mission_path = ""
	hub_selected_mission_label = ""
	loading_saved_state = false
	saved_run_state = {}
	current_level_path = next_path
	_reset_level_counters()
	current_level_start_state = carry_state.duplicate(true)
	pending_player_restore_state = carry_state
	run_started_msec = Time.get_ticks_msec()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file(current_level_path)
	return true


func _register_campaign_completion(current_scene: Node) -> void:
	if current_scene == null or not current_scene.has_method("get_campaign_completion_stage"):
		return
	var completed_stage := int(current_scene.call("get_campaign_completion_stage"))
	campaign_stage = maxi(campaign_stage, completed_stage)


func _clear_saved_run() -> void:
	for path in [SAVE_PATH, SAVE_TEMP_PATH, SAVE_BACKUP_PATH]:
		if FileAccess.file_exists(path):
			var remove_error := DirAccess.remove_absolute(path)
			if remove_error != OK:
				push_warning("VEX kayıt dosyası silinemedi: %s (hata %s)" % [path, remove_error])


func _load_run() -> bool:
	saved_run_state = {}
	var config := ConfigFile.new()
	var error := config.load(SAVE_PATH)
	if error != OK:
		# Ana kayıt bozulduysa son sağlam yedeği dene.
		if not FileAccess.file_exists(SAVE_BACKUP_PATH):
			return false
		config = ConfigFile.new()
		error = config.load(SAVE_BACKUP_PATH)
		if error != OK:
			return false

	for key: String in config.get_section_keys("run"):
		saved_run_state[key] = config.get_value("run", key)

	var version := int(saved_run_state.get("save_version", 0))
	if version < 3 or version > SAVE_VERSION:
		saved_run_state = {}
		return false
	if version < SAVE_VERSION:
		_migrate_save_state(version)

	var level_path := str(saved_run_state.get("current_level_path", LEVEL_01_PATH))
	if not ResourceLoader.exists(level_path):
		saved_run_state = {}
		return false

	kills = maxi(0, int(saved_run_state.get("kills", 0)))
	secrets = maxi(0, int(saved_run_state.get("secrets", 0)))
	objective = str(saved_run_state.get("objective", "TESİSTEN ÇIKIŞ YOLUNU BUL"))
	defeated_enemy_ids.clear()
	var stored_enemies: Array = saved_run_state.get("defeated_enemy_ids", []) as Array
	for stored_enemy: Variant in stored_enemies:
		var enemy_id := StringName(str(stored_enemy))
		if enemy_id != &"" and not defeated_enemy_ids.has(enemy_id):
			defeated_enemy_ids.append(enemy_id)
	collected_pickup_ids.clear()
	var stored_pickups: Array = saved_run_state.get("collected_pickup_ids", []) as Array
	for stored_pickup: Variant in stored_pickups:
		var pickup_id := StringName(str(stored_pickup))
		if pickup_id != &"" and not collected_pickup_ids.has(pickup_id):
			collected_pickup_ids.append(pickup_id)
	found_secret_ids.clear()
	var stored_secrets: Array = saved_run_state.get("found_secret_ids", []) as Array
	for stored_secret: Variant in stored_secrets:
		var secret_id := StringName(str(stored_secret))
		if secret_id != &"" and not found_secret_ids.has(secret_id):
			found_secret_ids.append(secret_id)
	active_difficulty = clampi(
		int(saved_run_state.get("difficulty", SettingsManager.difficulty)),
		SettingsManager.Difficulty.EASY,
		SettingsManager.Difficulty.NIGHTMARE
	)
	campaign_stage = maxi(0, int(saved_run_state.get("campaign_stage", campaign_stage)))
	hub_selected_mission_path = str(saved_run_state.get("hub_selected_mission_path", ""))
	hub_selected_mission_label = str(saved_run_state.get("hub_selected_mission_label", ""))
	current_level_path = level_path
	return true


func _migrate_save_state(version: int) -> void:
	# v3 zaten kullanılabilir flat player state tutuyordu. v4 yalnızca metadata ekler.
	if version < 4:
		var resume_player_state: Dictionary = {}
		for key in ["health", "armor", "stamina", "keys", "position", "rotation_y", "weapon_state", "night_vision_owned", "night_vision_enabled", "is_crouching"]:
			if saved_run_state.has(key):
				resume_player_state[key] = saved_run_state[key]
		saved_run_state["resume_player_state"] = resume_player_state
		saved_run_state["resume_mode"] = "level"
		saved_run_state["save_reason"] = "migrated_v3"
		saved_run_state["saved_unix_time"] = Time.get_unix_time_from_system()
		saved_run_state["save_version"] = SAVE_VERSION


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
