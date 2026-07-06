shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, repeat_enable, filter_nearest;
uniform sampler2D noise : repeat_enable;

void fragment() {
	float t = TIME * 0.03;
	float offset = texture(noise, SCREEN_UV + vec2(t)).r;
	offset = (offset - 0.5) * 2.0;
	vec4 tex_color = texture(TEXTURE, UV);
	vec4 background_color = texture(screen, SCREEN_UV + vec2(-offset, offset) * 0.005);
	if (tex_color.a < 0.1) {
		discard;
	}
	vec3 blended_rgb = mix(background_color.rgb, tex_color.rgb, tex_color.a);
    COLOR = vec4(blended_rgb, 1.0);
}
