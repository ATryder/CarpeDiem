shader_type canvas_item;
render_mode blend_add,unshaded;

uniform float threshold;
uniform float amount;

void fragment() {
	vec4 col = texture(TEXTURE, vec2(UV.x, UV.y));
	
	if ((col.a + col.b + col.r) / 3.0 < threshold) {
		COLOR = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		COLOR = vec4(col.rgb * amount, 1.0);
	}
}