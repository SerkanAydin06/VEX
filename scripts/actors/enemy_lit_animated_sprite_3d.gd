class_name VexEnemyLitAnimatedSprite3D
extends AnimatedSprite3D

const LIT_SHADER: Shader = preload("res://shaders/enemy_sprite_lit.gdshader")

@export var visual_profile: VexEnemySpriteVisualProfile

var _lit_material: ShaderMaterial


func _ready() -> void:
	_lit_material = ShaderMaterial.new()
	_lit_material.shader = LIT_SHADER
	material_override = _lit_material
	frame_changed.connect(_sync_frame_texture)
	animation_changed.connect(_sync_frame_texture)
	sprite_frames_changed.connect(_sync_frame_texture)
	_apply_visual_profile()
	_sync_frame_texture()


func _sync_frame_texture() -> void:
	if _lit_material == null or sprite_frames == null:
		return
	if not sprite_frames.has_animation(animation):
		return
	var frame_count := sprite_frames.get_frame_count(animation)
	if frame_count <= 0:
		return
	var safe_frame := clampi(frame, 0, frame_count - 1)
	_lit_material.set_shader_parameter(
		&"albedo_texture",
		sprite_frames.get_frame_texture(animation, safe_frame)
	)


func _apply_visual_profile() -> void:
	if _lit_material == null:
		return
	var profile := visual_profile
	if profile == null:
		profile = VexEnemySpriteVisualProfile.new()
	_lit_material.set_shader_parameter(&"normal_strength", profile.normal_strength)
	_lit_material.set_shader_parameter(&"cavity_strength", profile.cavity_strength)
	_lit_material.set_shader_parameter(&"edge_darkening", profile.edge_darkening)
	_lit_material.set_shader_parameter(&"roughness_value", profile.roughness)
	_lit_material.set_shader_parameter(&"specular_value", profile.specular)
	_lit_material.set_shader_parameter(&"rim_strength", profile.rim_strength)
	_lit_material.set_shader_parameter(&"rim_tint_value", profile.rim_tint)
	_lit_material.set_shader_parameter(&"ambient_lift", profile.ambient_lift)
	_lit_material.set_shader_parameter(&"contrast", profile.contrast)
	_lit_material.set_shader_parameter(&"saturation", profile.saturation)
	_lit_material.set_shader_parameter(
		&"bright_emission_strength",
		profile.bright_emission_strength
	)
	_lit_material.set_shader_parameter(
		&"bright_emission_threshold",
		profile.bright_emission_threshold
	)
	_lit_material.set_shader_parameter(&"emission_tint", profile.emission_tint)
