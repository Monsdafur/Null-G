shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, repeat_enable, filter_nearest;
uniform sampler2D noise : repeat_enable, filter_nearest;
uniform bool enabled;
uniform vec2 direction;
uniform vec2 distortion_scale;
uniform float speed;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	if (enabled) {
		float t = TIME * speed;
		float offset = texture(noise, (SCREEN_UV * distortion_scale) + vec2(t)).r;
		offset = (offset - 0.5) * 2.0;
		vec4 background_color = texture(screen, SCREEN_UV + direction * offset * 0.005);
		float brightness = dot(background_color.rgb, vec3(0.2126, 0.7152, 0.0722));
		background_color.rgb = brightness > 0.25 ? vec3(111.0 / 255.0, 79.0 / 255.0, 111.0 / 255.0) : vec3(63.0 / 255.0, 31.0 / 255.0, 63.0 / 255.0);
		if (tex_color.a < 0.1) {
			discard;
		}
		vec3 blended_rgb = mix(background_color.rgb, tex_color.rgb, tex_color.a);
	    COLOR = vec4(blended_rgb, 1.0);
	}
	else {
	    COLOR = tex_color;
	}
}
