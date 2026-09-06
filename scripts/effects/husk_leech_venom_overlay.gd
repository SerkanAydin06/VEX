class_name VexHuskLeechVenomOverlay
extends CanvasLayer

const FULL_VFX_SHEET = preload("res://assets/enemies/husk_leech/husk_leech_full_vfx_spritesheet.png")
const FRAME_SIZE := Vector2i(1280, 720)
const FRAME_COUNT := 4
const FIRST_PHASE_FRAME_COUNT := 2
const FIRST_PHASE_DURATION := 3.0
const SECOND_PHASE_DURATION := 2.0
const TOTAL_FRAME_DURATION := FIRST_PHASE_DURATION + SECOND_PHASE_DURATION
const FADE_DURATION := 0.5
const NODE_NAME := "HuskLeechVenomOverlay"

var _shade_rect: ColorRect = null
var _texture_rect: TextureRect = null
var _atlas: AtlasTexture = null
var _remaining := 0.0
var _effect_duration := TOTAL_FRAME_DURATION
var _frame_elapsed := 0.0
var _frame_index := 0
var _peak_alpha := 0.95


static func apply_to(target: Node, duration: float, peak_alpha: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	var existing := target.get_node_or_null(NODE_NAME)
	if existing is VexHuskLeechVenomOverlay:
		(existing as VexHuskLeechVenomOverlay).refresh_effect(duration, peak_alpha)
		return
	var overlay := VexHuskLeechVenomOverlay.new()
	overlay.name = NODE_NAME
	target.add_child(overlay)
	overlay.refresh_effect(duration, peak_alpha)


func _ready() -> void:
	layer = 96

	_shade_rect = ColorRect.new()
	_shade_rect.name = "PoisonShade"
	_shade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_shade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shade_rect.color = Color(0.015, 0.025, 0.012, 0.16)
	add_child(_shade_rect)

	_atlas = AtlasTexture.new()
	_atlas.atlas = FULL_VFX_SHEET

	_texture_rect = TextureRect.new()
	_texture_rect.name = "PoisonDecal"
	_texture_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_texture_rect.texture = _atlas
	add_child(_texture_rect)

	_apply_frame()
	set_process(false)


func refresh_effect(duration: float, peak_alpha: float) -> void:
	_effect_duration = maxf(duration, 0.5)
	_remaining = _effect_duration
	_peak_alpha = clampf(peak_alpha, 0.2, 1.0)
	_frame_elapsed = 0.0
	_frame_index = 0
	if not is_node_ready():
		return
	_apply_frame()
	_texture_rect.modulate.a = _peak_alpha
	_shade_rect.modulate.a = 1.0
	set_process(true)


func _process(delta: float) -> void:
	_remaining = maxf(0.0, _remaining - delta)
	_frame_elapsed += delta

	while _frame_index < FRAME_COUNT - 1:
		var frame_duration := _frame_duration(_frame_index)
		if _frame_elapsed < frame_duration:
			break
		_frame_elapsed -= frame_duration
		_frame_index += 1
		_apply_frame()

	var runtime_fade_duration := minf(FADE_DURATION, _effect_duration * 0.1)
	var fade := 1.0
	if _remaining < runtime_fade_duration:
		fade = clampf(_remaining / maxf(runtime_fade_duration, 0.01), 0.0, 1.0)
	_texture_rect.modulate.a = _peak_alpha * fade
	_shade_rect.modulate.a = fade

	if _remaining <= 0.0:
		queue_free()


func _frame_duration(frame_index: int) -> float:
	if frame_index < FIRST_PHASE_FRAME_COUNT:
		return (
			_effect_duration
			* (FIRST_PHASE_DURATION / TOTAL_FRAME_DURATION)
			/ float(FIRST_PHASE_FRAME_COUNT)
		)
	return (
		_effect_duration
		* (SECOND_PHASE_DURATION / TOTAL_FRAME_DURATION)
		/ float(FRAME_COUNT - FIRST_PHASE_FRAME_COUNT)
	)


func _apply_frame() -> void:
	if _atlas == null:
		return
	_atlas.region = Rect2(
		float(_frame_index * FRAME_SIZE.x),
		0.0,
		float(FRAME_SIZE.x),
		float(FRAME_SIZE.y)
	)
