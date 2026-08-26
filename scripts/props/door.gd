class_name VexDoor
extends Node3D

signal lock_state_changed(is_locked: bool)

enum DoorState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING,
}

enum DoorOpeningMode {
	UP,
	SPLIT_SIDE,
}

@export_category("Kapı")
@export var display_name := "GÜVENLİK KAPISI"
@export var locked := false
@export var required_key: StringName = &"blue"
@export var required_keys: Array[StringName] = []
@export var required_key_label := ""
@export var objective_on_unlock := ""
@export var required_enemy_ids: Array[StringName] = []
@export var objective_on_combat_clear := ""
@export var permanently_locked := false
@export var permanent_lock_message := "POWER OFFLINE"
@export var campaign_unlock_stage := -1

@export_category("Açılma Hareketi")
@export_enum("Yukarı", "İki Yana") var opening_mode: int = DoorOpeningMode.UP
@export var opening_offset_up := Vector3(0.0, 4.2, 0.0)
@export var opening_offset_left := Vector3(0.0, 0.0, -2.12)
@export var opening_offset_right := Vector3(0.0, 0.0, 2.12)
@export_range(0.1, 3.0, 0.05) var opening_time := 0.75
@export var auto_close := true
@export_range(1.0, 15.0, 0.5) var auto_close_delay := 4.0
@export var automatic_open := false

@export_category("Güvenli Kapanma")
@export_flags_3d_physics var safety_collision_mask := 2 | 4
@export_range(0.05, 1.0, 0.05) var safety_recheck_time := 0.2
@export_range(0.1, 2.0, 0.1) var safety_clear_time := 0.5
@export_range(0.01, 0.5, 0.01) var minimum_motion_time := 0.05

var door_panel: AnimatableBody3D
var door_panel_right: AnimatableBody3D
var safety_sensor: Area3D
var proximity_sensor: Area3D
var door_occluder: OccluderInstance3D
var perception_blocker: StaticBody3D
var shadow_blocker: MeshInstance3D
var is_open := false
var is_moving := false

var _state: DoorState = DoorState.CLOSED
var _closed_panel_position := Vector3.ZERO
var _closed_right_panel_position := Vector3.ZERO
var _motion_tween: Tween
var _motion_generation := 0
var _auto_close_generation := 0
var _runtime_locked := false
var _combat_lock_was_active := false
var _auto_close_available := false
var _open_audio: AudioStreamPlayer3D
var _denied_audio: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("interactable")
	if campaign_unlock_stage >= 0 and GameState.campaign_stage >= campaign_unlock_stage:
		permanently_locked = false
		locked = false
	_runtime_locked = locked
	_combat_lock_was_active = _has_active_combat_lock()
	_emit_lock_state()
	if not GameState.enemy_defeated.is_connected(_on_enemy_defeated):
		GameState.enemy_defeated.connect(_on_enemy_defeated)
	_auto_close_available = auto_close
	door_panel = get_node_or_null("DoorPanel") as AnimatableBody3D
	door_panel_right = get_node_or_null("DoorPanelRight") as AnimatableBody3D
	safety_sensor = get_node_or_null("SafetySensor") as Area3D
	proximity_sensor = get_node_or_null("ProximitySensor") as Area3D
	door_occluder = get_node_or_null("DoorOccluder") as OccluderInstance3D
	perception_blocker = get_node_or_null("PerceptionBlocker") as StaticBody3D
	shadow_blocker = get_node_or_null("DoorShadowBlocker") as MeshInstance3D
	_open_audio = get_node_or_null("OpenAudio") as AudioStreamPlayer3D
	_denied_audio = get_node_or_null("DeniedAudio") as AudioStreamPlayer3D

	if door_panel == null:
		push_warning("%s: DoorPanel bulunamadı; kapı devre dışı bırakıldı." % get_path())
		_auto_close_available = false
		set_physics_process(false)
		return

	_closed_panel_position = door_panel.position
	if door_panel_right != null:
		_closed_right_panel_position = door_panel_right.position
	if opening_mode == DoorOpeningMode.SPLIT_SIDE and door_panel_right == null:
		push_warning(
			"%s: İki yana açılma için DoorPanelRight bulunamadı; kapı devre dışı."
			% get_path()
		)
		_auto_close_available = false
		set_physics_process(false)
		return
	_sync_occluder_visibility()

	if safety_sensor == null:
		# Sensör olmadan kapıyı kapatmak oyuncuyu veya düşmanı ezebilir.
		# Bu nedenle çalışma anında düğüm üretmek yerine otomatik kapanmayı
		# güvenli biçimde devre dışı bırakıyoruz. Tam kapı sahnesinde sensör hazırdır.
		push_warning("%s: SafetySensor bulunamadı; otomatik kapanma kapatıldı." % get_path())
		_auto_close_available = false
		set_physics_process(false)
		return

	safety_sensor.collision_layer = 0
	safety_sensor.collision_mask = safety_collision_mask
	safety_sensor.monitorable = false
	if not safety_sensor.body_entered.is_connected(_on_safety_body_entered):
		safety_sensor.body_entered.connect(_on_safety_body_entered)
	if proximity_sensor != null and not proximity_sensor.body_entered.is_connected(_on_proximity_body_entered):
		proximity_sensor.body_entered.connect(_on_proximity_body_entered)
	# Yalnızca kapanma hareketi sırasında güvenlik sorgusu gerekir.
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	# Sinyalin kaçırılmasına karşı ikinci güvenlik denetimi.
	if _state == DoorState.CLOSING and _is_doorway_blocked():
		_begin_opening()


func get_interaction_text(player: Node) -> String:
	if automatic_open:
		return ""
	if door_panel == null or _state != DoorState.CLOSED:
		return ""
	if permanently_locked:
		return tr("INTERACT_LOCKED") % [tr(display_name), tr(permanent_lock_message)]
	if _has_active_combat_lock():
		return tr("INTERACT_COMBAT_LOCKED") % tr(display_name)
	if _runtime_locked and not _player_has_required_keys(player):
		return tr("INTERACT_REQUIRED") % [tr(display_name), _get_required_key_label()]
	return tr("INTERACT_OPEN") % tr(display_name)


func interact(player: Node) -> void:
	if automatic_open:
		return
	if door_panel == null or _state != DoorState.CLOSED:
		return
	if permanently_locked:
		if _denied_audio != null and _denied_audio.stream != null:
			_denied_audio.play()
		GameState.notify(tr("DOOR_LOCKED_MESSAGE") % [tr(display_name), tr(permanent_lock_message)])
		return
	if _has_active_combat_lock():
		if _denied_audio != null and _denied_audio.stream != null:
			_denied_audio.play()
		GameState.notify(tr("DOOR_COMBAT_LOCKED"))
		return
	if _runtime_locked:
		if not _player_has_required_keys(player):
			if _denied_audio != null and _denied_audio.stream != null:
				_denied_audio.play()
			GameState.notify(tr("DOOR_LOCKED_REQUIRED") % _get_required_key_label())
			return
		_runtime_locked = false
		_emit_lock_state()
		GameState.notify(tr("DOOR_OPENED") % tr(display_name))
		if not objective_on_unlock.is_empty():
			GameState.set_objective(objective_on_unlock)
	_begin_opening()


func _player_has_required_keys(player: Node) -> bool:
	if player == null or not player.has_method("has_key"):
		return false
	for key_id: StringName in _get_required_keys():
		if not bool(player.call("has_key", key_id)):
			return false
	return true


func _get_required_keys() -> Array[StringName]:
	if not required_keys.is_empty():
		return required_keys
	var keys: Array[StringName] = []
	if required_key != &"":
		keys.append(required_key)
	return keys


func _get_required_key_label() -> String:
	if not required_key_label.is_empty():
		return tr(required_key_label)
	var labels: Array[String] = []
	for key_id: StringName in _get_required_keys():
		match key_id:
			&"blue":
				labels.append(tr("KEY_BLUE"))
			&"red":
				labels.append(tr("KEY_RED"))
			&"yellow":
				labels.append(tr("KEY_YELLOW"))
			_:
				labels.append(String(key_id).to_upper())
	return " + ".join(labels)


func set_campaign_unlocked(unlocked: bool) -> void:
	if campaign_unlock_stage < 0:
		return
	permanently_locked = not unlocked
	_runtime_locked = false if unlocked else locked
	_emit_lock_state()
	if unlocked and automatic_open and proximity_sensor != null and proximity_sensor.is_inside_tree():
		for body: Node3D in proximity_sensor.get_overlapping_bodies():
			if body == GameState.player:
				force_open()
				break


func force_open() -> void:
	_runtime_locked = false
	_emit_lock_state()
	if door_panel != null and _state != DoorState.OPEN and _state != DoorState.OPENING:
		_begin_opening()


func is_access_locked() -> bool:
	return permanently_locked or _runtime_locked or _has_active_combat_lock()


func _has_active_combat_lock() -> bool:
	for enemy_id: StringName in required_enemy_ids:
		if enemy_id != &"" and not GameState.was_enemy_defeated(enemy_id):
			return true
	return false


func _on_enemy_defeated(_enemy_id: StringName) -> void:
	if not _combat_lock_was_active or _has_active_combat_lock():
		return
	_combat_lock_was_active = false
	_emit_lock_state()
	GameState.notify("DOOR_COMBAT_CLEARED")
	if not objective_on_combat_clear.is_empty():
		GameState.set_objective(objective_on_combat_clear)


func _emit_lock_state() -> void:
	lock_state_changed.emit(is_access_locked())


func _begin_opening() -> void:
	if door_panel == null or _state == DoorState.OPEN or _state == DoorState.OPENING:
		return

	_motion_generation += 1
	_auto_close_generation += 1
	var motion_generation := _motion_generation
	var close_generation := _auto_close_generation
	_cancel_motion()
	_set_state(DoorState.OPENING)
	set_physics_process(false)

	if _open_audio != null and _open_audio.stream != null:
		_open_audio.play()

	var distance_ratio := _get_open_distance_ratio()
	var duration := maxf(minimum_motion_time, opening_time * distance_ratio)
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if _is_split_side_door():
		_motion_tween.set_parallel(true)
		_motion_tween.tween_property(
			door_panel,
			"position",
			_closed_panel_position + opening_offset_left,
			duration
		)
		_motion_tween.tween_property(
			door_panel_right,
			"position",
			_closed_right_panel_position + opening_offset_right,
			duration
		)
	else:
		_motion_tween.tween_property(
			door_panel,
			"position",
			_closed_panel_position + opening_offset_up,
			duration
		)
	_motion_tween.finished.connect(
		_on_opening_finished.bind(motion_generation, close_generation)
	)


func _on_opening_finished(motion_generation: int, close_generation: int) -> void:
	if not is_inside_tree() or motion_generation != _motion_generation:
		return
	_motion_tween = null
	_set_state(DoorState.OPEN)
	if _auto_close_available and safety_sensor != null:
		_auto_close_sequence(close_generation)


func _auto_close_sequence(close_generation: int) -> void:
	await get_tree().create_timer(auto_close_delay).timeout
	while _can_auto_close(close_generation):
		if _is_doorway_blocked():
			await get_tree().create_timer(safety_recheck_time).timeout
			continue

		# Alanın yalnızca tek fizik karesi için boşalması kapanmayı başlatmasın.
		await get_tree().create_timer(safety_clear_time).timeout
		if not _can_auto_close(close_generation):
			return
		if _is_doorway_blocked():
			continue

		_begin_closing()
		return


func _begin_closing() -> void:
	if door_panel == null or _state != DoorState.OPEN:
		return
	if _is_doorway_blocked():
		return

	_motion_generation += 1
	var motion_generation := _motion_generation
	_cancel_motion()
	_set_state(DoorState.CLOSING)
	set_physics_process(true)

	var distance_ratio := _get_close_distance_ratio()
	var duration := maxf(minimum_motion_time, opening_time * distance_ratio)
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	if _is_split_side_door():
		_motion_tween.set_parallel(true)
		_motion_tween.tween_property(
			door_panel,
			"position",
			_closed_panel_position,
			duration
		)
		_motion_tween.tween_property(
			door_panel_right,
			"position",
			_closed_right_panel_position,
			duration
		)
	else:
		_motion_tween.tween_property(
			door_panel,
			"position",
			_closed_panel_position,
			duration
		)
	_motion_tween.finished.connect(_on_closing_finished.bind(motion_generation))


func _on_closing_finished(motion_generation: int) -> void:
	if not is_inside_tree() or motion_generation != _motion_generation:
		return
	_motion_tween = null
	_set_state(DoorState.CLOSED)
	set_physics_process(false)


func _on_proximity_body_entered(body: Node3D) -> void:
	if not automatic_open or body == null or body != GameState.player:
		return
	if permanently_locked or _runtime_locked:
		return
	if _state == DoorState.CLOSED or _state == DoorState.CLOSING:
		_begin_opening()


func _on_safety_body_entered(_body: Node3D) -> void:
	if _state == DoorState.CLOSING:
		_begin_opening()


func _is_doorway_blocked() -> bool:
	# Sensör yoksa veya henüz sahnede değilse kapı güvenli tarafta kalır.
	if safety_sensor == null or not safety_sensor.is_inside_tree():
		return true

	# Canlı oyuncu ve düşman gövdeleri sensör tarafından doğrudan algılanır.
	# Ölü düşmanların çarpışması kapalıdır; cesetler kapıyı sonsuza dek açık
	# tutmaz ve her kapı her kare bütün enemy grubunu taramaz.
	if not safety_sensor.get_overlapping_bodies().is_empty():
		return true
	if automatic_open and proximity_sensor != null and proximity_sensor.is_inside_tree():
		for body: Node3D in proximity_sensor.get_overlapping_bodies():
			if body == GameState.player:
				return true
	return false


func _can_auto_close(close_generation: int) -> bool:
	return (
		is_inside_tree()
		and _auto_close_available
		and safety_sensor != null
		and _state == DoorState.OPEN
		and close_generation == _auto_close_generation
	)


func _set_state(new_state: DoorState) -> void:
	_state = new_state
	is_open = _state == DoorState.OPEN
	is_moving = _state == DoorState.OPENING or _state == DoorState.CLOSING
	_sync_occluder_visibility()


func _sync_occluder_visibility() -> void:
	var fully_closed := _state == DoorState.CLOSED
	if door_occluder != null:
		# Hareketli oklüder kullanılmaz: açılma başlar başlamaz devre dışı kalır,
		# kapı tam kapanınca sabit konumunda yeniden etkinleşir.
		door_occluder.visible = fully_closed
	if perception_blocker != null:
		# İki hareketli panelin birleşim çizgisinde mikroskobik bir fizik boşluğu
		# kalabilirdi. Kapı tam kapalıyken tek parça world-layer blocker, AI
		# görüş raylarının ve oyuncu fiziğinin bu aralıktan geçmesini kesin keser.
		perception_blocker.collision_layer = 1 if fully_closed else 0
	if shadow_blocker != null:
		# SHADOWS_ONLY mesh; yalnız kapı tam kapalıyken direkt ışığı keser.
		shadow_blocker.visible = fully_closed


func _is_split_side_door() -> bool:
	return (
		opening_mode == DoorOpeningMode.SPLIT_SIDE
		and door_panel_right != null
	)


func _get_open_distance_ratio() -> float:
	if _is_split_side_door():
		var left_target := _closed_panel_position + opening_offset_left
		var right_target := _closed_right_panel_position + opening_offset_right
		var traveled := maxf(
			door_panel.position.distance_to(left_target),
			door_panel_right.position.distance_to(right_target)
		)
		return clampf(traveled / maxf(maxf(opening_offset_left.length(), opening_offset_right.length()), 0.001), 0.0, 1.0)
	var target_position := _closed_panel_position + opening_offset_up
	return clampf(
		door_panel.position.distance_to(target_position) / maxf(opening_offset_up.length(), 0.001),
		0.0,
		1.0
	)


func _get_close_distance_ratio() -> float:
	if _is_split_side_door():
		var traveled := maxf(
			door_panel.position.distance_to(_closed_panel_position),
			door_panel_right.position.distance_to(_closed_right_panel_position)
		)
		return clampf(traveled / maxf(maxf(opening_offset_left.length(), opening_offset_right.length()), 0.001), 0.0, 1.0)
	return clampf(
		door_panel.position.distance_to(_closed_panel_position) / maxf(opening_offset_up.length(), 0.001),
		0.0,
		1.0
	)


func _cancel_motion() -> void:
	if _motion_tween != null:
		_motion_tween.kill()
		_motion_tween = null
