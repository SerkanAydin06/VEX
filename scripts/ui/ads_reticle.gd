class_name VexAdsReticle
extends Control

@export_category("ADS Nişangah")
@export var cross_color := Color(0.93, 0.98, 1.0, 0.96)
@export var optic_dot_color := Color(1.0, 0.08, 0.04, 1.0)
@export var shadow_color := Color(0.015, 0.02, 0.025, 0.92)
@export var hit_color := Color(1.0, 0.12, 0.08, 1.0)
@export var headshot_color := Color(1.0, 0.72, 0.10, 1.0)
@export_range(2.0, 8.0, 0.25) var cross_half_length := 4.0
@export_range(0.75, 3.0, 0.25) var cross_thickness := 1.25
@export_range(1.0, 4.0, 0.1) var dot_radius := 1.8
@export_range(1.5, 6.0, 0.1) var dot_outline_radius := 3.0
@export_range(0.05, 1.0, 0.01) var feedback_duration := 0.24

var _feedback_remaining := 0.0
var _headshot_feedback := false
var _reticle_style := "small_cross"
var _display_color := Color(0.93, 0.98, 1.0, 0.96)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameState.hit_confirmed.connect(_on_hit_confirmed)
	GameState.headshot_confirmed.connect(_on_headshot_confirmed)
	_sync_visibility()
	queue_redraw()


func _process(delta: float) -> void:
	if _feedback_remaining > 0.0:
		_feedback_remaining = maxf(0.0, _feedback_remaining - delta)
		if _feedback_remaining <= 0.0:
			_headshot_feedback = false
			_display_color = _base_style_color()
			queue_redraw()
	_sync_visibility()


func _draw() -> void:
	var center := size * 0.5
	if _reticle_style == "red_dot":
		draw_circle(center, dot_outline_radius, shadow_color)
		draw_circle(center, dot_radius, _display_color)
		return

	var horizontal_from := Vector2(center.x - cross_half_length, center.y)
	var horizontal_to := Vector2(center.x + cross_half_length, center.y)
	var vertical_from := Vector2(center.x, center.y - cross_half_length)
	var vertical_to := Vector2(center.x, center.y + cross_half_length)
	var shadow_thickness := cross_thickness + 2.0
	draw_line(horizontal_from, horizontal_to, shadow_color, shadow_thickness, true)
	draw_line(vertical_from, vertical_to, shadow_color, shadow_thickness, true)
	draw_line(horizontal_from, horizontal_to, _display_color, cross_thickness, true)
	draw_line(vertical_from, vertical_to, _display_color, cross_thickness, true)


func _sync_visibility() -> void:
	var player := GameState.player as VexPlayer
	if player != null and is_instance_valid(player):
		_sync_style(player)
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


func _sync_style(player: VexPlayer) -> void:
	var next_style := "small_cross"
	var controller := player.get_node_or_null("WeaponController") as VexWeaponController
	if controller != null and controller.has_method("get_current_weapon"):
		var definition := controller.call("get_current_weapon") as WeaponDefinition
		if definition != null:
			next_style = definition.hud_ads_reticle_style
	if next_style == _reticle_style:
		return
	_reticle_style = next_style
	if _feedback_remaining <= 0.0:
		_display_color = _base_style_color()
	queue_redraw()


func _base_style_color() -> Color:
	return optic_dot_color if _reticle_style == "red_dot" else cross_color


func _on_hit_confirmed() -> void:
	if _headshot_feedback and _feedback_remaining > 0.0:
		return
	_feedback_remaining = feedback_duration
	_display_color = hit_color
	queue_redraw()


func _on_headshot_confirmed() -> void:
	_headshot_feedback = true
	_feedback_remaining = feedback_duration * 1.25
	_display_color = headshot_color
	queue_redraw()
