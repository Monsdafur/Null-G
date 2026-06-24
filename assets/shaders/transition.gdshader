shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, repeat_enable, filter_nearest;
uniform float dt;

void fragment() {
	vec3 color;

	if (abs(SCREEN_UV.x - 0.5) < dt * 0.5) {
		color = mix(texture(screen, SCREEN_UV).rgb, vec3(1.0), 1.0 - dt);
	}
	else {
		color = vec3(0.0, 0.0, 0.0);
	}

	COLOR.rgb = color;
}