class_name VexAdsReticle
extends Control

@export_category("ADS Nişangah")
@export var default_color := Color(0.93, 0.98, 1.0, 0.96)
@export var hit_color := Color(1.0, 0.12, 0.08, 1.0)
@export var headshot_color := Color(1.0, 0.72, 0.10, 1.0)
@export_range(0.05, 1.0, 0.01) var feedback_duration := 0.24

var _feedback_remaining := 0.0
var _headshot_feedback := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate = default_color
	GameState.hit_confirmed.connect(_on_hit_confirmed)
	GameState.headshot_confirmed.connect(_on_headshot_confirmed)
	_sync_visibility()


func _process(delta: float) -> void:
	if _feedback_remaining > 0.0:
		_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
		if _feedback_remaining <= 0.0:
			_headshot_feedback = false
			modulate = default_color
	_sync_visibility()


func _sync_visibility() -> void:
	var player := GameState.player as VexPlayer
	if (
		player == null
		or not is_instance_valid(player)
		or player.is_dead
		or not player.is_aiming
		or get_tree().paused
	):
		visible = false
		return

	var hud_root := get_parent() as Control
	if hud_root != null:
		var map_overlay := hud_root.get_node_or_null("MapOverlay") as Control
		if map_overlay != null and map_overlay.visible:
			visible = false
			return
		var pause_menu := hud_root.get_node_or_null("PauseMenu") as Control
		if pause_menu != null and pause_menu.visible:
			visible = false
			return

	visible = true


func _on_hit_confirmed() -> void:
	if _headshot_feedback and _feedback_remaining > 0.0:
		return
	_feedback_remaining = feedback_duration
	modulate = hit_color


func _on_headshot_confirmed() -> void:
	_headshot_feedback = true
	_feedback_remaining = feedback_duration * 1.25
	modulate = headshot_color
