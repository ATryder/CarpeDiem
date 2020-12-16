shader_type spatial;
render_mode blend_mix,depth_draw_never,depth_test_disable,cull_back,unshaded,world_vertex_coords;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_offset;
uniform vec2 mask_scale;

uniform vec3 lift = vec3(1.0, 1.0, 1.0);
uniform vec3 gamma = vec3(1.0, 1.0, 1.0);
uniform vec3 gain = vec3(1.0, 1.0, 1.0);

uniform vec4 fog : hint_color;

uniform vec4 col1 : hint_color;
uniform vec4 col2 : hint_color;
uniform float pos1 : hint_range(0, 1);
uniform float pos2 : hint_range(0, 1);

varying vec3 worldvert;

void vertex() {
	worldvert = VERTEX;
}

void fragment() {
	float rim = 1.0 - max(dot(normalize(-VERTEX), NORMAL), 0.0);
	float mult = clamp(pow(rim, 0.76), 0.0, 1.0);
	
	vec3 col = vec3(mix(col1.r, col2.r, mult));
    
    vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	
	if (mask.r < 0.001) {
		discard;
	} else {
    	vec3 cb = pow(gain * (col + (lift - 1.0) * (1.0 - col)), 1.0 / gamma);
    	ALBEDO = mix(col * fog.rgb, cb, mask.g);
		ALPHA = mask.r;
	}
}
