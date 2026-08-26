shader_type spatial;

uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tile_size_m = 5.0;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.2;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.8;
uniform float specular_value : hint_range(0.0, 1.0) = 0.3;
uniform vec4 albedo_tint : source_color = vec4(1.0);

varying vec3 world_position;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float safe_tile_size = max(tile_size_m, 0.01);
	vec2 world_uv = world_position.xz / safe_tile_size;
	vec4 surface = texture(albedo_texture, world_uv) * albedo_tint;
	ALBEDO = surface.rgb;
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
}
