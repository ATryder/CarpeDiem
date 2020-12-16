shader_type spatial;
render_mode blend_mix,depth_draw_always,cull_back,diffuse_burley,specular_schlick_ggx;

uniform vec4 albedo : hint_color;
uniform sampler2D texture_albedo : hint_albedo;
uniform float metallic : hint_range(0,1);
uniform float roughness : hint_range(0,1);
uniform float point_size : hint_range(0,128);
uniform sampler2D texture_metalness_roughness : hint_white;
uniform sampler2D texture_normal : hint_normal;
uniform float normal_scale : hint_range(-16,16);
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform vec4 albedo_paint : hint_color;
uniform float specular_paint;
uniform float metallic_paint : hint_range(0,1);
uniform float roughness_paint : hint_range(0,1);

uniform float specular_glass : hint_range(0,1);
uniform float metallic_glass : hint_range(0,1);
uniform float roughness_glass : hint_range(0,1);
uniform vec4 glass_rim : hint_color;
uniform vec4 glass_mid : hint_color;
uniform vec4 glass_inner : hint_color;
uniform float mid_pos : hint_range(0,1);
uniform float inner_pos : hint_range(0,1);

uniform sampler2D splat : hint_black;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_offset;
uniform vec2 mask_scale;
uniform float alpha_mod = 0.0;
uniform float is_ghost = 0.0;

varying vec3 worldvert;

void vertex() {
	UV2 = UV2*uv2_scale.xy+uv2_offset.xy;
	//worldvert = VERTEX;
	worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}




void fragment() {
	float mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).g;
	ALPHA = min(mask + alpha_mod + is_ghost, 1.0);
	
	if (ALPHA <= 0.003) {
		discard;
	} else {
		vec2 base_uv = UV;
		vec3 splat_tex = texture(splat, base_uv).rgb;
		vec3 mr = texture(texture_metalness_roughness, base_uv).rgb;
		
		vec4 albedo_tex = texture(texture_albedo,base_uv);
		vec3 ALBEDO_BASE = albedo.rgb * albedo_tex.rgb;
		float metallic_tex = mr.r;
		float METALLIC_BASE = metallic_tex * metallic;
		float roughness_tex = mr.g;
		float ROUGHNESS_BASE = roughness_tex * roughness;
		float SPECULAR_BASE = mr.b;
		vec3 norm = texture(texture_normal, base_uv).rgb;
		NORMALMAP = norm;
		NORMALMAP_DEPTH = 1.0;
		
		mat3 tbn = mat3(TANGENT, BINORMAL, NORMAL);
		vec3 nm = (vec3(norm.rg, 1.0) * 2.0) - 1.0;
		nm = tbn * nm;
		float rim = max(dot(normalize(-VERTEX), nm), 0.0);
		float perc = min(rim / mid_pos, 1.0);
		vec3 ALBEDO_GLASS = mix(glass_rim.rgb, glass_mid.rgb, perc);
		perc = min(max(rim - mid_pos, 0.0) / (inner_pos - mid_pos), 1.0);
		ALBEDO_GLASS = mix(ALBEDO_GLASS, glass_inner.rgb, perc);
		
		ALBEDO_BASE = (ALBEDO_BASE * (1.0 - splat_tex.g)) + (albedo_paint.rgb * splat_tex.g);
		METALLIC_BASE = (METALLIC_BASE * (1.0 - splat_tex.g)) + (metallic_paint * splat_tex.g);
		ROUGHNESS_BASE = (ROUGHNESS_BASE * (1.0 - splat_tex.g)) + (roughness_paint * splat_tex.g);
		SPECULAR_BASE = (SPECULAR_BASE * (1.0 - splat_tex.g)) + (specular_paint * splat_tex.g);
		
		ALBEDO_BASE = (ALBEDO_BASE * (1.0 - splat_tex.r)) + (ALBEDO_GLASS * splat_tex.r);
		METALLIC = (METALLIC_BASE * (1.0 - splat_tex.r)) + (metallic_glass * splat_tex.r);
		ROUGHNESS = (ROUGHNESS_BASE * (1.0 - splat_tex.r)) + (roughness_glass * splat_tex.r);
		SPECULAR = (SPECULAR_BASE * (1.0 - splat_tex.r)) + (specular_glass * splat_tex.r);
		ALBEDO = mix(ALBEDO_BASE, vec3(ALBEDO_BASE.r + ALBEDO_BASE.g + ALBEDO_BASE.b) / 3.0, is_ghost);
	}
}
