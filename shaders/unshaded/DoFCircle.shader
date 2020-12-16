shader_type spatial;
render_mode blend_mix,depth_draw_never,cull_back,unshaded;

uniform float alpha = 0.8;
uniform float radius = 0.5;
uniform vec2 center = vec2(0.5, 0.5);

uniform float blur : hint_range(0, 1);

void fragment() {
	float x = UV.x - center.x;
    float y = UV.y - center.y;
    float r = sqrt((x*x) + (y*y));
    r = r * (1.0 / radius);
	
	float perc = min(max(1.0 - r, 0.0) / max(blur * COLOR.a, 0.0001), 0.99);
	
	if (perc < 0.001) {
		discard;
	} else {
		ALBEDO.rgb = COLOR.rgb;
		ALPHA = perc * alpha;
	}
}
