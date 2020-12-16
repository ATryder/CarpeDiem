shader_type spatial;
render_mode blend_add,depth_draw_opaque,cull_back,unshaded;

uniform float radius = 0.5;
uniform vec2 center = vec2(0.5, 0.5);

uniform vec4 col1 : hint_color;
uniform vec4 col2 : hint_color;
uniform vec4 col3 : hint_color;

uniform float pos1 : hint_range(0, 1);
uniform float pos2 : hint_range(0, 1);

uniform vec3 lift;
uniform vec3 gamma;
uniform vec3 gain;

uniform vec4 fog : hint_color;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_offset;
uniform vec2 mask_scale;

varying vec3 worldvert;

void vertex() {
	worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}


void fragment() {
	float x = UV.x - center.x;
    float y = UV.y - center.y;
    float r = sqrt((x*x) + (y*y));
    r = r * (1.0 / radius);
	
	float perc = min(max(r - pos1, 0.0) / (pos2 - pos1), 1.0);
    vec4 col = mix(col1, col2, perc);
    
    perc = min(max(r - pos2, 0.0) / (1.0 - pos2), 1.0);
    col = mix(col, col3, perc);
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	col.a *= mask.r;
	
	if (col.a < 0.001) {
		discard;
	} else {
		vec3 cb = pow(gain * (col.rgb + (lift - 1.0) * (1.0 - col.rgb)), 1.0 / gamma);
		ALBEDO.rgb = mix(col.rgb * fog.rgb, cb, mask.g);
		ALPHA = col.a;
	}
}