shader_type spatial;
render_mode unshaded,blend_add,depth_draw_never,cull_back;

uniform sampler2D tex : hint_white;
uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_scale;
uniform vec2 mask_offset;

uniform float alpha_mod = 0.0;
uniform float alpha = 1.0;

varying vec3 worldvert;

void vertex() {
	worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 col = texture(tex, UV);
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	col.a *= max(mask.g, alpha_mod) * alpha;
	
	if (col.a < 0.001) {
		discard;
	} else {
		ALBEDO.rgb = col.rgb;
		ALPHA = col.a;
	}
}
