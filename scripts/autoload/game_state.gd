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
signal enemy_defeated(enemy_id: StringName)
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
const SAVE_VERSION := 5
const CAMPAIGN_SAVE_ENABLED := true
const CHECKPOINTS_ENABLED := false

var player: Node = null
var hud: CanvasLayer = null
var objective := "OBJECTIVE_FIND_EXIT"
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
	# New campaigns also get a safe boundary immediately. If the player exits
	# before finishing VEX-01, Continue simply restarts VEX-01 from its entrance.
	save_campaign_progress(current_level_path, {}, "new_game")
	get_tree().change_scene_to_file(current_level_path)


func continue_game() -> void:
	# VEX keeps no mid-level checkpoints. Continue resumes the last safe campaign
	# boundary (hub or mission entrance) and never restores world/position state.
	if not _load_campaign_save():
		start_new_game()
		return
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	loading_saved_state = false
	pending_next_level_path = ""
	_reset_level_counters()
	current_level_path = str(saved_run_state.get("current_level_path", LEVEL_01_PATH))
	if not ResourceLoader.exists(current_level_path):
		start_new_game()
		return
	pending_player_restore_state = (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)
	current_level_start_state = pending_player_restore_state.duplicate(true)
	run_started_msec = Time.get_ticks_msec()
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
	# Compatibility alias: checkpoints do not exist in VEX.
	restart_level(false)


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
	return CAMPAIGN_SAVE_ENABLED and (FileAccess.file_exists(SAVE_PATH) or FileAccess.file_exists(SAVE_BACKUP_PATH))


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
	# Restart state lives only in memory. Death always restarts this level from
	# its entrance; no mid-level state is written to disk.
	call_deferred("_capture_level_start_state")


func _capture_level_start_state() -> void:
	if player == null or not is_instance_valid(player) or not player.has_method("capture_run_state"):
		return
	current_level_start_state = player.call("capture_run_state").duplicate(true)


func set_objective(text: String) -> void:
	objective = text
	objective_changed.emit(objective)


func notify(text: String) -> void:
	notification_requested.emit(tr(text))


func notify_pickup(text: String, category: StringName) -> void:
	pickup_notification_requested.emit(tr(text), category)


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
	enemy_defeated.emit(enemy_id)


func was_enemy_defeated(enemy_id: StringName) -> bool:
	return enemy_id != &"" and defeated_enemy_ids.has(enemy_id)


func register_pickup_collected(pickup_id: StringName) -> void:
	if pickup_id == &"" or collected_pickup_ids.has(pickup_id):
		return
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
	notify("SECRET_FOUND")


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


func save_checkpoint(_reason: String = "checkpoint") -> bool:
	# Kept for API compatibility only. Mid-level checkpoint saves are disabled.
	return false


func save_campaign_progress(
	resume_path: String = "",
	player_state: Dictionary = {},
	reason: String = "campaign"
) -> bool:
	if not CAMPAIGN_SAVE_ENABLED:
		return false
	var safe_path := resume_path if not resume_path.is_empty() else current_level_path
	if safe_path.is_empty() or not ResourceLoader.exists(safe_path):
		return false
	var safe_player_state := player_state.duplicate(true)
	if safe_player_state.is_empty() and player != null and is_instance_valid(player) and player.has_method("capture_run_state"):
		safe_player_state = player.call("capture_run_state")
	safe_player_state = _sanitize_campaign_player_state(safe_player_state)
	var state := {
		"save_version": SAVE_VERSION,
		"save_reason": reason,
		"saved_unix_time": Time.get_unix_time_from_system(),
		"current_level_path": safe_path,
		"resume_mode": "campaign_boundary",
		"resume_player_state": safe_player_state,
		"difficulty": active_difficulty,
		"campaign_stage": campaign_stage,
		"hub_selected_mission_path": hub_selected_mission_path,
		"hub_selected_mission_label": hub_selected_mission_label,
	}
	var config := ConfigFile.new()
	for key: String in state.keys():
		config.set_value("campaign", key, state[key])
	return _write_save_config(config)


func save_current_safe_progress(reason: String = "safe_point") -> bool:
	var scene := get_tree().current_scene
	if scene == null:
		return false
	var scene_path := scene.scene_file_path
	# Only Bastion is a free-form safe point. Mission saves are written at deploy
	# or completion so changing ammo/health mid-level never becomes a checkpoint.
	if scene_path != BASTION_7_PATH:
		return false
	return save_campaign_progress(BASTION_7_PATH, {}, reason)


func _sanitize_campaign_player_state(state: Dictionary) -> Dictionary:
	var safe := state.duplicate(true)
	# Mission-local state is never persisted.
	safe.erase("position")
	safe.erase("rotation_y")
	safe["keys"] = []
	safe["is_crouching"] = false
	safe["night_vision_enabled"] = false
	return safe


func _write_save_config(config: ConfigFile) -> bool:
	var temp_error := config.save(SAVE_TEMP_PATH)
	if temp_error != OK:
		push_error("VEX geçici kayıt dosyası yazılamadı. Hata kodu: %s" % temp_error)
		return false
	if FileAccess.file_exists(SAVE_BACKUP_PATH):
		DirAccess.remove_absolute(SAVE_BACKUP_PATH)
	if FileAccess.file_exists(SAVE_PATH):
		var backup_error := DirAccess.rename_absolute(SAVE_PATH, SAVE_BACKUP_PATH)
		if backup_error != OK:
			push_warning("VEX eski kayıt yedeklenemedi. Hata kodu: %s" % backup_error)
	var rename_error := DirAccess.rename_absolute(SAVE_TEMP_PATH, SAVE_PATH)
	if rename_error != OK:
		if not FileAccess.file_exists(SAVE_PATH) and FileAccess.file_exists(SAVE_BACKUP_PATH):
			DirAccess.rename_absolute(SAVE_BACKUP_PATH, SAVE_PATH)
		push_error("VEX kayıt dosyası etkinleştirilemedi. Hata kodu: %s" % rename_error)
		return false
	return true


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
		current_level_path = next_level_path
	else:
		pending_player_restore_state = {}

	if next_level_path != "":
		save_campaign_progress(next_level_path, pending_player_restore_state, "level_complete")

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
		notify("HUB_NO_NEW_OPERATION")
		return false
	hub_selected_mission_path = mission_path
	hub_selected_mission_label = mission_label
	hub_mission_changed.emit(hub_selected_mission_path, hub_selected_mission_label)
	notify(tr("HUB_OPERATION_SELECTED") % tr(hub_selected_mission_label))
	set_objective("HUB_OBJECTIVE_DEPLOY")
	return true


func has_hub_selected_mission() -> bool:
	return not hub_selected_mission_path.is_empty()


func get_hub_selected_mission_label() -> String:
	return hub_selected_mission_label


func deploy_selected_hub_mission() -> bool:
	if hub_selected_mission_path.is_empty():
		notify("HUB_SELECT_OPERATION_FIRST")
		set_objective("HUB_OBJECTIVE_USE_TERMINAL")
		return false
	if player != null and is_instance_valid(player):
		var weapon_controller := player.get_node_or_null("WeaponController")
		if (
			weapon_controller != null
			and weapon_controller.has_method("has_carried_weapon")
			and not bool(weapon_controller.call("has_carried_weapon"))
		):
			notify("HUB_LOADOUT_REQUIRED")
			set_objective("HUB_OBJECTIVE_VISIT_ARMORY")
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
	save_campaign_progress(current_level_path, carry_state, "mission_deploy")
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


func _load_campaign_save() -> bool:
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

	var section := "campaign" if config.has_section("campaign") else "run"
	for key: String in config.get_section_keys(section):
		saved_run_state[key] = config.get_value(section, key)

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

	# Campaign saves intentionally discard mission-local world state.
	_reset_level_counters()
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
	if version < 4:
		var resume_player_state: Dictionary = {}
		for key in ["health", "armor", "stamina", "keys", "position", "rotation_y", "weapon_state", "night_vision_owned", "night_vision_enabled", "is_crouching"]:
			if saved_run_state.has(key):
				resume_player_state[key] = saved_run_state[key]
		saved_run_state["resume_player_state"] = resume_player_state
	if version < 5:
		var player_state := (saved_run_state.get("resume_player_state", {}) as Dictionary).duplicate(true)
		player_state = _sanitize_campaign_player_state(player_state)
		if player_state.has("weapon_state"):
			player_state["weapon_state"] = _migrate_weapon_state_ids(player_state["weapon_state"] as Dictionary)
		saved_run_state["resume_player_state"] = player_state
		saved_run_state["resume_mode"] = "campaign_boundary"
		saved_run_state["save_reason"] = "migrated_v%d" % version
		saved_run_state["saved_unix_time"] = Time.get_unix_time_from_system()
		saved_run_state["save_version"] = SAVE_VERSION


func _migrate_weapon_state_ids(state: Dictionary) -> Dictionary:
	var migrated := state.duplicate(true)
	var aliases := {StringName("pistol"): &"p01", StringName("shotgun"): &"sg04", StringName("ak47"): &"vx47"}
	for list_key in ["unlocked_weapons", "acquired_weapons"]:
		var output: Array[StringName] = []
		for value in migrated.get(list_key, []) as Array:
			var old_id := StringName(str(value))
			var new_id: StringName = aliases.get(old_id, old_id)
			if not output.has(new_id):
				output.append(new_id)
		migrated[list_key] = output
	for dict_key in ["magazines", "upgrade_levels"]:
		var source := (migrated.get(dict_key, {}) as Dictionary).duplicate(true)
		for old_id: StringName in aliases:
			var new_id: StringName = aliases[old_id]
			if source.has(old_id):
				source[new_id] = source[old_id]
			elif source.has(str(old_id)):
				source[new_id] = source[str(old_id)]
			source.erase(old_id)
			source.erase(str(old_id))
		migrated[dict_key] = source
	var current_id := StringName(str(migrated.get("current_weapon_id", &"p01")))
	migrated["current_weapon_id"] = aliases.get(current_id, current_id)
	return migrated


func _reset_level_counters() -> void:
	player = null
	hud = null
	objective = "OBJECTIVE_FIND_EXIT"
	kills = 0
	total_enemies = 0
	secrets = 0
	total_secrets = 1
	defeated_enemy_ids.clear()
	collected_pickup_ids.clear()
	found_secret_ids.clear()
