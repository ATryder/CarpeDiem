shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_back;

uniform sampler2D tex : hint_black;
uniform vec2 offset = vec2(0.0, 0.0);
uniform vec4 color : hint_color;

void fragment() {
	vec4 col = texture(tex, UV - offset) * color;
	col.a *= UV2.y;
	
	if (col.a <= 0.003) {
		discard;
	} else {
		ALBEDO = col.rgb;
		ALPHA = col.a;
	}
}