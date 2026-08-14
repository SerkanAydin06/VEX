shader_type spatial;
render_mode unshaded;

uniform float static_intensity : hint_range(0.0, 1.0) = 0.8;
uniform float static_speed : hint_range(1.0, 100.0) = 40.0;
uniform float scanline_count : hint_range(0.0, 500.0) = 150.0;
uniform float scanline_intensity : hint_range(0.0, 1.0) = 0.2;

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	float time_step = floor(TIME * static_speed);
	float noise = random(UV + vec2(time_step * 0.05, time_step * 0.1));
	float scanline = sin(UV.y * scanline_count * 3.14159) * 0.5 + 0.5;
	vec3 static_color = vec3(noise);
	static_color -= scanline* scanline_intensity;
	ALBEDO = clamp(static_color, 0.0, 1.0);
	EMISSION = ALBEDO * static_intensity;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
