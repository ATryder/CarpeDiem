shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 albedo_paint : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform sampler2D texture_combined : hint_black;
uniform sampler2D texture_glassmask : hint_black;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_strength : hint_range(0, 2) = 1.0;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_offset;
uniform vec2 mask_scale;

uniform vec4 fog : hint_color;

uniform float alpha_mod = 0.0;
uniform float is_ghost = 0.0;

varying vec3 worldvert;

void vertex() {
	worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 albedo = texture(texture_albedo, UV);
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	float ghost = is_ghost * mask.r;
	ALPHA = albedo.a * max(max(mask.g, ghost), alpha_mod);
	
	if (ALPHA <= 0.003) {
		discard;
	} else {
		vec4 combined = texture(texture_combined, UV);
		
		float glass = step(texture(texture_glassmask, UV).r, 0.5);
		vec4 glass_col = clamp(albedo_paint, vec4(0.25), vec4(0.65));
		
		albedo = mix(albedo, albedo_paint, combined.b);
		albedo = mix(albedo, glass_col, glass) * color;
		
		SPECULAR = glass;
		METALLIC = combined.r;
		ROUGHNESS = combined.g;
		NORMALMAP = texture(texture_normal, UV).rgb;
		NORMALMAP_DEPTH = normal_strength;
		
		vec4 bw = vec4(vec3(albedo.r + albedo.g + albedo.b) / 3.0, 1.0) * fog;
		ALBEDO = mix(bw.rgb, albedo.rgb, mask.g);
	}
}
