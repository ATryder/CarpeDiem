shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float threshold;
uniform float amount;

void fragment() {
	vec4 col = texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, 1.0 - SCREEN_UV.y));
	
	if ((col.a + col.b + col.r) / 3.0 < threshold) {
		COLOR = col
	} else {
		COLOR = col + (col * amount);
	}
}