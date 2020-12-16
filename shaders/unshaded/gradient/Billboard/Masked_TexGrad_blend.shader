shader_type spatial;
render_mode unshaded,blend_mix,depth_draw_never,cull_back,skip_vertex_transform;

uniform sampler2D tex : hint_white;
uniform vec4 col1 : hint_color;
uniform vec4 col2 : hint_color;
uniform vec4 col3 : hint_color;

uniform float pos1;
uniform float pos2;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_scale;
uniform vec2 mask_offset;

varying vec3 worldvert;

void vertex() {
	//worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);
	mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x),0.0,0.0), vec4(sin(INSTANCE_CUSTOM.x),cos(INSTANCE_CUSTOM.x),0.0,0.0),vec4(0.0,0.0,1.0,0.0),vec4(0.0,0.0,0.0,1.0));
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
	
	worldvert = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec4 t = texture(tex, UV);
	float perc = 1.0 - t.r;
	vec4 col = mix(col1, col2, max(max(perc - pos1, 0.0) / max(pos2 - pos1, 0.001), 0.0));
	col = mix(col, col3, max(max(perc - pos2, 0.0) / max(1.0 - pos2, 0.001), 0.0));
	col.a *= t.a;
	col *= COLOR;
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	col.a *= mask.g;
	
	if (col.a < 0.001) {
		discard;
	} else {
		ALBEDO.rgb = col.rgb;
		ALPHA = col.a;
	}
}
