shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, repeat_enable, filter_nearest;
uniform float dt;

void fragment() {
	vec3 color = texture(screen, SCREEN_UV).rgb;
	COLOR.rgb = mix(vec3(63.0 / 255.0, 31.0 / 255.0, 64.0 / 255.0), color, dt);
}