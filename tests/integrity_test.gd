extends Node

const INVALID_SAVE_FIXTURE := "res://tests/fixtures/save_invalid_version.cfg"
const VALID_BACKUP_FIXTURE := "res://tests/fixtures/save_valid_backup.cfg"

const CREATURE_SCENES := [
	"res://scenes/actors/redviper.tscn",
	"res://scenes/actors/badredviper.tscn",
	"res://scenes/actors/cinderhound.tscn",
	"res://scenes/actors/ravager.tscn",
	"res://scenes/actors/basalt_juggernaut.tscn",
	"res://scenes/actors/veilmaw.tscn",
	"res://scenes/actors/voidweaver.tscn",
	"res://scenes/actors/furnice_carrier.tscn",
	"res://scenes/actors/crucible_warden.tscn",
	"res://scenes/actors/briar_skulker.tscn",
	"res://scenes/actors/gorehorn.tscn",
	"res://scenes/actors/cinder_spitter.tscn",
	"res://scenes/actors/coil_lancer.tscn",
	"res://scenes/actors/vaskari_bulwark.tscn",
]

const COMMON_CREATURE_INSPECTOR_PROPERTIES := [
	&"path_target_change_distance", &"runtime_grid_step", &"runtime_grid_max_nodes",
	&"runtime_grid_search_margin", &"sight_collision_mask", &"aggro_on_damage",
	&"damage_pursuit_commit_time", &"loud_noise_alert_threshold",
	&"headshot_reference_height",
]

const RANGED_CREATURE_INSPECTOR_PROPERTIES := [
	&"ranged_visibility_sampling_enabled", &"cover_reposition_enabled",
	&"ranged_cover_visibility_threshold", &"ranged_cover_reposition_distance",
	&"attack_preferred_distance", &"attack_minimum_distance",
	&"attack_recovery_strafe_scale", &"attack_retreat_speed_scale",
	&"chase_path_refresh_interval", &"local_detour_duration",
]

const REQUIRED_RESOURCES := [
	"res://scenes/player/player.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/levels/level_01.tscn",
	"res://scenes/levels/level_02.tscn",
	"res://scenes/levels/level_03.tscn",
	"res://scenes/levels/tutorial_trigger.tscn",
	"res://scenes/levels/level_01_training_overlay.tscn",
	"res://scripts/levels/level_01_training_flow.gd",
	"res://scenes/props/door_side_slide.tscn",
	"res://scenes/world/door_status_light.tscn",
	"res://scenes/hub/bastion_7.tscn",
	"res://resources/weapons/p01.tres",
	"res://resources/weapons/p07.tres",
	"res://resources/weapons/p14.tres",
	"res://resources/weapons/p20.tres",
	"res://resources/weapons/sg04.tres",
	"res://resources/weapons/sg09.tres",
	"res://resources/weapons/sg15.tres",
	"res://resources/weapons/vx47.tres",
	"res://resources/weapons/mp90.tres",
	"res://translations/vex.csv",
	"res://translations/vex.tr.translation",
	"res://translations/vex.en.translation",
]

var failures: Array[String] = []


func _ready() -> void:
	_check_required_resources()
	_check_level_01()
	_check_level_02()
	_check_level_03()
	_check_bastion_7()
	_check_training_overlay()
	_check_automap_contract()
	_check_door_contract()
	_check_heat_hud_contract()
	_check_weapon_contracts()
	_check_input_map()
	_check_localization_contract()
	_check_save_recovery_contract()
	_check_creature_inspector_contract()

	if failures.is_empty():
		print("VEX integrity test başarılı: güncel level, tutorial, automap, kapı ve silah sözleşmeleri temiz.")
		get_tree().quit(0)
	else:
		for message in failures:
			push_error(message)
		push_error("VEX integrity test başarısız: %d hata." % failures.size())
		get_tree().quit(1)


func _check_required_resources() -> void:
	for path: String in REQUIRED_RESOURCES:
		if not ResourceLoader.exists(path):
			failures.append("Eksik kaynak: %s" % path)


func _instantiate(path: String) -> Node:
	var packed := load(path) as PackedScene
	if packed == null:
		failures.append("Sahne yüklenemedi: %s" % path)
		return null
	var instance := packed.instantiate()
	if instance == null:
		failures.append("Sahne instantiate edilemedi: %s" % path)
	return instance


func _count_named_children(root: Node, prefix: String) -> int:
	if root == null:
		return 0
	var count := 0
	for child: Node in root.get_children():
		if child.name.begins_with(prefix):
			count += 1
	return count


func _check_level_01() -> void:
	var level := _instantiate("res://scenes/levels/level_01.tscn")
	if level == null:
		return
	if str(level.get("map_revision")) != "VEX01-R28-37ROOM-13STEP":
		failures.append("VEX-01 37 oda revision sözleşmesi yanlış.")

	var geometry := level.get_node_or_null("Geometry")
	if _count_named_children(geometry, "Floor_R") != 37:
		failures.append("VEX-01 zemin modülü 37 değil.")

	level.queue_free()


func _check_level_02() -> void:
	var level := _instantiate("res://scenes/levels/level_02.tscn")
	if level == null:
		return
	level.queue_free()


func _check_level_03() -> void:
	var level := _instantiate("res://scenes/levels/level_03.tscn")
	if level == null:
		return
	level.queue_free()


func _check_bastion_7() -> void:
	var bastion := _instantiate("res://scenes/hub/bastion_7.tscn")
	if bastion == null:
		return
	bastion.queue_free()


func _check_training_overlay() -> void:
	var overlay := _instantiate("res://scenes/levels/level_01_training_overlay.tscn")
	if overlay == null:
		return
	overlay.queue_free()


func _check_automap_contract() -> void:
	var automap_script := load("res://scripts/ui/automap_view.gd") as Script
	if automap_script == null:
		failures.append("Automap script yüklenemedi.")


func _check_door_contract() -> void:
	var door := _instantiate("res://scenes/props/door_side_slide.tscn")
	if door == null:
		return
	door.queue_free()


func _check_heat_hud_contract() -> void:
	var hud := _instantiate("res://scenes/ui/hud.tscn")
	if hud == null:
		return
	hud.queue_free()


func _check_weapon_contracts() -> void:
	for path in [
		"res://resources/weapons/p01.tres",
		"res://resources/weapons/p07.tres",
		"res://resources/weapons/p14.tres",
		"res://resources/weapons/p20.tres",
		"res://resources/weapons/sg04.tres",
		"res://resources/weapons/sg09.tres",
		"res://resources/weapons/sg15.tres",
		"res://resources/weapons/vx47.tres",
		"res://resources/weapons/mp90.tres",
	]:
		if load(path) == null:
			failures.append("Silah kaynağı yüklenemedi: %s" % path)


func _check_input_map() -> void:
	for action in [&"move_forward", &"move_backward", &"move_left", &"move_right", &"attack"]:
		if not InputMap.has_action(action):
			failures.append("InputMap aksiyonu eksik: %s" % action)


func _check_localization_contract() -> void:
	for locale in ["tr", "en"]:
		if not TranslationServer.get_loaded_locales().has(locale):
			failures.append("Locale yüklenmedi: %s" % locale)


func _check_save_recovery_contract() -> void:
	if not FileAccess.file_exists(INVALID_SAVE_FIXTURE):
		failures.append("Bozuk kayıt fixture eksik.")
	if not FileAccess.file_exists(VALID_BACKUP_FIXTURE):
		failures.append("Geçerli yedek kayıt fixture eksik.")


func _check_creature_inspector_contract() -> void:
	for path: String in CREATURE_SCENES:
		var enemy := _instantiate(path)
		if enemy == null:
			continue
		for property_name: StringName in COMMON_CREATURE_INSPECTOR_PROPERTIES:
			if not _has_property(enemy, property_name):
				failures.append("Yaratık Inspector ayarı eksik: %s -> %s" % [path, property_name])
		if int(enemy.get("combat_role")) != EnemyCombatProfiles.Role.CLOSE:
			for property_name: StringName in RANGED_CREATURE_INSPECTOR_PROPERTIES:
				if not _has_property(enemy, property_name):
					failures.append("Menzilli yaratık Inspector ayarı eksik: %s -> %s" % [path, property_name])
		enemy.queue_free()


func _has_property(object: Object, property_name: StringName) -> bool:
	for property: Dictionary in object.get_property_list():
		if property.get("name", &"") == property_name:
			return true
	return false
