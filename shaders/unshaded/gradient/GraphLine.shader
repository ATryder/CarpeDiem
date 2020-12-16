shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform vec4 color : hint_color;
uniform float perc = 0.0;

void fragment() {
	float p = perc * 1.2;
	vec4 col = vec4(1.0, 1.0, 1.0, clamp((p - UV.x) / 0.005, 0.0, 1.0));
	col.rgb = mix(col.rgb, color.rgb, clamp(((p - 0.005) - UV.x) / 0.195, 0.0, 1.0));
	
	COLOR = col;
}
