class_name VexDoor
extends Node3D

enum DoorState {
	CLOSED,
	OPENING,
	OPEN,
	CLOSING,
}

@export_category("Kapı")
@export var display_name := "GÜVENLİK KAPISI"
@export var locked := false
@export var required_key: StringName = &"blue"
@export var required_keys: Array[StringName] = []
@export var required_key_label := ""
@export var objective_on_unlock := ""
@export_range(1.0, 8.0, 0.1) var opening_height := 4.2
@export_range(0.1, 3.0, 0.05) var opening_time := 0.75
@export var auto_close := true
@export_range(1.0, 15.0, 0.5) var auto_close_delay := 4.0

@export_category("Güvenli Kapanma")
@export_range(0.05, 1.0, 0.05) var safety_recheck_time := 0.2
@export_range(0.1, 2.0, 0.1) var safety_clear_time := 0.5

var door_panel: AnimatableBody3D
var safety_sensor: Area3D
var door_occluder: OccluderInstance3D
var is_open := false
var is_moving := false

var _state: DoorState = DoorState.CLOSED
var _closed_panel_position := Vector3.ZERO
var _motion_tween: Tween
var _motion_generation := 0
var _auto_close_generation := 0
var _open_audio: AudioStreamPlayer3D
var _denied_audio: AudioStreamPlayer3D


func _ready() -> void:
	add_to_group("interactable")
	door_panel = get_node_or_null("DoorPanel") as AnimatableBody3D
	safety_sensor = get_node_or_null("SafetySensor") as Area3D
	door_occluder = get_node_or_null("DoorOccluder") as OccluderInstance3D
	_open_audio = get_node_or_null("OpenAudio") as AudioStreamPlayer3D
	_denied_audio = get_node_or_null("DeniedAudio") as AudioStreamPlayer3D

	if door_panel == null:
		push_warning("%s: DoorPanel bulunamadı; kapı devre dışı bırakıldı." % get_path())
		auto_close = false
		set_physics_process(false)
		return

	_closed_panel_position = door_panel.position
	_sync_occluder_visibility()

	if safety_sensor == null:
		# Sensör olmadan kapıyı kapatmak oyuncuyu veya düşmanı ezebilir.
		# Bu nedenle çalışma anında düğüm üretmek yerine otomatik kapanmayı
		# güvenli biçimde devre dışı bırakıyoruz. Tam kapı sahnesinde sensör hazırdır.
		push_warning("%s: SafetySensor bulunamadı; otomatik kapanma kapatıldı." % get_path())
		auto_close = false
		set_physics_process(false)
		return

	safety_sensor.collision_layer = 0
	safety_sensor.collision_mask = 2 | 4
	safety_sensor.monitorable = false
	if not safety_sensor.body_entered.is_connected(_on_safety_body_entered):
		safety_sensor.body_entered.connect(_on_safety_body_entered)
	# Yalnızca kapanma hareketi sırasında güvenlik sorgusu gerekir.
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	# Sinyalin kaçırılmasına karşı ikinci güvenlik denetimi.
	if _state == DoorState.CLOSING and _is_doorway_blocked():
		_begin_opening()


func get_interaction_text(player: Node) -> String:
	if door_panel == null or _state != DoorState.CLOSED:
		return ""
	if locked and not _player_has_required_keys(player):
		return "[E] %s — %s GEREKLİ" % [display_name, _get_required_key_label()]
	return "[E] %s AÇ" % display_name


func interact(player: Node) -> void:
	if door_panel == null or _state != DoorState.CLOSED:
		return
	if locked:
		if not _player_has_required_keys(player):
			if _denied_audio != null and _denied_audio.stream != null:
				_denied_audio.play()
			GameState.notify("KAPI KİLİTLİ — %s GEREKLİ" % _get_required_key_label())
			return
		locked = false
		GameState.notify("%s AÇILDI" % display_name)
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
		return required_key_label
	var labels: Array[String] = []
	for key_id: StringName in _get_required_keys():
		match key_id:
			&"blue":
				labels.append("MAVİ ERİŞİM ANAHTARI")
			&"red":
				labels.append("KIRMIZI ERİŞİM ANAHTARI")
			_:
				labels.append(String(key_id).to_upper())
	return " + ".join(labels)


func force_open() -> void:
	locked = false
	if door_panel != null and _state != DoorState.OPEN and _state != DoorState.OPENING:
		_begin_opening()


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

	var target_position := _closed_panel_position + Vector3.UP * opening_height
	var distance_ratio := clampf(
		door_panel.position.distance_to(target_position) / maxf(opening_height, 0.001),
		0.0,
		1.0
	)
	var duration := maxf(0.05, opening_time * distance_ratio)
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(door_panel, "position", target_position, duration)
	_motion_tween.finished.connect(
		_on_opening_finished.bind(motion_generation, close_generation)
	)


func _on_opening_finished(motion_generation: int, close_generation: int) -> void:
	if not is_inside_tree() or motion_generation != _motion_generation:
		return
	_motion_tween = null
	_set_state(DoorState.OPEN)
	if auto_close and safety_sensor != null:
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

	var distance_ratio := clampf(
		door_panel.position.distance_to(_closed_panel_position) / maxf(opening_height, 0.001),
		0.0,
		1.0
	)
	var duration := maxf(0.05, opening_time * distance_ratio)
	_motion_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	_motion_tween.tween_property(door_panel, "position", _closed_panel_position, duration)
	_motion_tween.finished.connect(_on_closing_finished.bind(motion_generation))


func _on_closing_finished(motion_generation: int) -> void:
	if not is_inside_tree() or motion_generation != _motion_generation:
		return
	_motion_tween = null
	_set_state(DoorState.CLOSED)
	set_physics_process(false)


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
	return not safety_sensor.get_overlapping_bodies().is_empty()


func _can_auto_close(close_generation: int) -> bool:
	return (
		is_inside_tree()
		and auto_close
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
	if door_occluder != null:
		# Hareketli oklüder kullanılmaz: açılma başlar başlamaz devre dışı kalır,
		# kapı tam kapanınca sabit konumunda yeniden etkinleşir.
		door_occluder.visible = _state == DoorState.CLOSED


func _cancel_motion() -> void:
	if _motion_tween != null:
		_motion_tween.kill()
		_motion_tween = null
