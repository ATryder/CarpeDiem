shader_type spatial;
render_mode blend_mix,depth_draw_never,cull_back,unshaded;

uniform vec4 color1 : hint_color;
uniform vec4 color2 : hint_color;
uniform vec4 color3 : hint_color;
uniform vec4 color4 : hint_color;

uniform float pos1 : hint_range(0, 1);
uniform float pos2 : hint_range(0, 1);

void fragment() {
	vec4 col = mix(color1, color2, clamp(UV2.x / pos1, 0.0, 1.0));
	col = mix(col, color3, clamp((UV2.x - pos1) / (pos2 - pos1), 0.0, 1.0));
	col = mix(col, color4, clamp((UV2.x - pos2) / (1.0 - pos2), 0.0, 1.0));
	
	ALBEDO.rgb = col.rgb;
	ALPHA = col.a;
}