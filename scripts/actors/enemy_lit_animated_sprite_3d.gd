class_name VexEnemySpriteLightingController
extends Node

const LIT_SHADER: Shader = preload("res://shaders/enemy_sprite_lit.gdshader")

var _target: AnimatedSprite3D
var _profile: VexEnemySpriteVisualProfile
var _lit_material: ShaderMaterial
var _configured := false


func setup(target: AnimatedSprite3D, profile: VexEnemySpriteVisualProfile) -> void:
	_target = target
	_profile = profile
	if is_node_ready():
		_configure()


func _ready() -> void:
	_configure()


func _configure() -> void:
	if _configured or _target == null or not is_instance_valid(_target):
		return
	_configured = true
	_lit_material = ShaderMaterial.new()
	_lit_material.shader = LIT_SHADER
	_target.material_override = _lit_material
	if not _target.frame_changed.is_connected(_sync_frame_texture):
		_target.frame_changed.connect(_sync_frame_texture)
	if not _target.animation_changed.is_connected(_sync_frame_texture):
		_target.animation_changed.connect(_sync_frame_texture)
	if not _target.sprite_frames_changed.is_connected(_sync_frame_texture):
		_target.sprite_frames_changed.connect(_sync_frame_texture)
	_apply_visual_profile()
	_sync_frame_texture()


func _sync_frame_texture() -> void:
	if _lit_material == null or _target == null or not is_instance_valid(_target):
		return
	if _target.sprite_frames == null:
		return
	if not _target.sprite_frames.has_animation(_target.animation):
		return
	var frame_count := _target.sprite_frames.get_frame_count(_target.animation)
	if frame_count <= 0:
		return
	var safe_frame := clampi(_target.frame, 0, frame_count - 1)
	var frame_texture := _target.sprite_frames.get_frame_texture(_target.animation, safe_frame)
	if frame_texture is AtlasTexture:
		var atlas_texture := frame_texture as AtlasTexture
		var atlas := atlas_texture.atlas
		if atlas == null:
			return
		var atlas_size := Vector2(atlas.get_size())
		if atlas_size.x <= 0.0 or atlas_size.y <= 0.0:
			return
		var region := atlas_texture.region
		var region_size := region.size
		if region_size.x <= 0.0:
			region_size.x = atlas_size.x
		if region_size.y <= 0.0:
			region_size.y = atlas_size.y
		_lit_material.set_shader_parameter(&"albedo_texture", atlas)
		_lit_material.set_shader_parameter(
			&"uv_rect",
			Vector4(
				region.position.x / atlas_size.x,
				region.position.y / atlas_size.y,
				region_size.x / atlas_size.x,
				region_size.y / atlas_size.y
			)
		)
		return
	_lit_material.set_shader_parameter(&"albedo_texture", frame_texture)
	_lit_material.set_shader_parameter(&"uv_rect", Vector4(0.0, 0.0, 1.0, 1.0))


func _apply_visual_profile() -> void:
	if _lit_material == null:
		return
	var profile := _profile
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
