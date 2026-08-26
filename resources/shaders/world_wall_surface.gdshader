shader_type spatial;

// Eksen hizalı modüler duvarlar için tek texture örneklemeli world projection.
// Her WorldPiece kendi UV'sini başlatmak yerine aynı metre ızgarasını paylaşır;
// böylece modül birleşimlerinde desen ölçeği ve fazı kesilmez.
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float tile_size_m : hint_range(0.25, 12.0, 0.05) = 4.0;
uniform float metallic_value : hint_range(0.0, 1.0) = 0.04;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.86;
uniform float specular_value : hint_range(0.0, 1.0) = 0.28;
uniform vec4 albedo_tint : source_color = vec4(1.0);

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize(MODEL_NORMAL_MATRIX * NORMAL);
}

void fragment() {
	float safe_tile_size = max(tile_size_m, 0.01);
	vec3 dominant_axis = abs(normalize(world_normal));
	vec2 world_uv;

	if (dominant_axis.y >= dominant_axis.x && dominant_axis.y >= dominant_axis.z) {
		world_uv = world_position.xz / safe_tile_size;
	} else if (dominant_axis.x >= dominant_axis.z) {
		world_uv = world_position.zy / safe_tile_size;
	} else {
		world_uv = world_position.xy / safe_tile_size;
	}

	vec4 surface = texture(albedo_texture, world_uv) * albedo_tint;
	ALBEDO = surface.rgb;
	METALLIC = metallic_value;
	ROUGHNESS = roughness_value;
	SPECULAR = specular_value;
}
