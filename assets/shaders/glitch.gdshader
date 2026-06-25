shader_type canvas_item;

uniform sampler2D screen : hint_screen_texture, repeat_enable, filter_nearest;
uniform float scale;
uniform float time;

float random(float x) {
    return (
        sin(x) +
        0.4 * sin(3.0 * x) +
        0.2 * sin(5.0 * x)
    ) / 1.6;
}

const float offset = 0.015;
const float bands[11] = {
	0.0, 
    0.115, 
    0.287, 
    0.391, 
    0.442, 
    0.518, 
    0.639, 
    0.721, 
    0.804, 
    0.893, 
    0.957
};
const vec2 aberation = vec2(1.0 / 800.0, 1.0 / 448.0);

void fragment() {
	float rand = random(float(int(floor(time * 8.0)) % 100));
	float rand01 = (rand + 1.0) / 2.0;
	int range = int(round(rand01 * 17.0));
	vec2 offset_uv = vec2(0.0, 0.0);
	if (SCREEN_UV.y > bands[range] && SCREEN_UV.y < bands[range + 1]) {
		offset_uv.x = rand * offset * scale;
	}
	float r = texture(screen, SCREEN_UV + offset_uv + aberation * floor(rand01 * 1.25) * scale).r;
	float g = texture(screen, SCREEN_UV + offset_uv).g;
	float b = texture(screen, SCREEN_UV + offset_uv - aberation * floor(rand01 * 1.25) * scale).b;
	
	COLOR.rgb = vec3(r, g, b);
}
