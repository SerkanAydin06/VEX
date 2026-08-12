shader_type canvas_item;
render_mode unshaded;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float gain : hint_range(1.0, 6.0) = 3.4;
uniform float green_strength : hint_range(0.0, 1.0) = 0.94;
uniform float noise_strength : hint_range(0.0, 0.12) = 0.035;
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.38;

float random_value(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 source = texture(screen_texture, SCREEN_UV);

	float luminance = dot(
		source.rgb,
		vec3(0.299, 0.587, 0.114)
	);

	// Karanlık bölgeleri yükselt fakat parlak ışıkları tamamen patlatma.
	float boosted = 1.0 - exp(-max(luminance, 0.0) * gain);
	boosted = clamp(boosted + 0.055, 0.0, 1.0);

	float noise = (
		random_value(
			floor(SCREEN_UV * vec2(640.0, 360.0))
			+ vec2(TIME * 37.0, TIME * 19.0)
		) - 0.5
	) * noise_strength;

	float scanline = 0.975 + 0.025 * sin(SCREEN_UV.y * 1000.0);

	vec2 centered = SCREEN_UV * 2.0 - 1.0;
	float edge = smoothstep(
		0.42,
		1.18,
		length(centered * vec2(0.78, 1.0))
	);
	float vignette = 1.0 - edge * vignette_strength;

	vec3 night_color = vec3(
		boosted * 0.07,
		boosted * 1.12,
		boosted * 0.16
	);

	night_color *= scanline * vignette;
	night_color += vec3(noise * 0.25, noise, noise * 0.28);

	vec3 final_color = mix(
		source.rgb * 1.12,
		night_color,
		green_strength
	);

	COLOR = vec4(clamp(final_color, vec3(0.0), vec3(1.0)), 1.0);
}
