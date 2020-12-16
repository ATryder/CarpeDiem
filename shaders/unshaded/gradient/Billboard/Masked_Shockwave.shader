shader_type spatial;
render_mode blend_add,depth_draw_never,cull_back,unshaded,skip_vertex_transform;

uniform bool reverse = false;
uniform float radius = 0.5;
uniform vec2 center = vec2(0.5, 0.5);

uniform vec4 col1 : hint_color;
uniform vec4 col2 : hint_color;
uniform vec4 col3 : hint_color;
uniform vec4 col4 : hint_color;
uniform vec4 col5 : hint_color;
uniform vec4 col6 : hint_color;

uniform float pos1 : hint_range(0, 1);
uniform float pos2 : hint_range(0, 1);
uniform float pos3 : hint_range(0, 1);
uniform float pos4 : hint_range(0, 1);
uniform float pos5 : hint_range(0, 1);

varying float vPos1;
varying float vPos2;
varying float vPos3;
varying float vPos4;
varying float vPos5;

uniform sampler2D mask_tex : hint_white;
uniform vec2 mask_offset;
uniform vec2 mask_scale;

varying vec3 worldvert;

void vertex() {
	//worldvert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	mat4 mat_world = mat4(normalize(CAMERA_MATRIX[0])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[1])*length(WORLD_MATRIX[0]),normalize(CAMERA_MATRIX[2])*length(WORLD_MATRIX[2]),WORLD_MATRIX[3]);
	mat_world = mat_world * mat4( vec4(cos(INSTANCE_CUSTOM.x),-sin(INSTANCE_CUSTOM.x),0.0,0.0), vec4(sin(INSTANCE_CUSTOM.x),cos(INSTANCE_CUSTOM.x),0.0,0.0),vec4(0.0,0.0,1.0,0.0),vec4(0.0,0.0,0.0,1.0));
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat_world;
	
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
	NORMAL = (MODELVIEW_MATRIX * vec4(VERTEX, 0.0)).xyz;
	
	worldvert = (CAMERA_MATRIX * vec4(VERTEX, 1.0)).xyz;
	
	float range = mix(pos1 * (1.0 - INSTANCE_CUSTOM.y), pos1 * INSTANCE_CUSTOM.y, step(0.5, float(reverse)));
	vPos1 = pos1 - range;
	vPos2 = pos2 - range;
	vPos3 = pos3 - range;
	vPos4 = pos4 - range;
	vPos5 = pos5 - range;
}


void fragment() {
	float x = UV.x - center.x;
    float y = UV.y - center.y;
    float r = sqrt((x*x) + (y*y));
    r = r * (1.0 / radius);
	
	float perc = min(max(r - vPos1, 0.0) / (vPos2 - vPos1), 1.0);
    vec4 col = mix(col1, col2, perc);
	
	perc = min(max(r - vPos2, 0.0) / (vPos3 - vPos2), 1.0);
    col = mix(col, col3, perc);
	
	perc = min(max(r - vPos3, 0.0) / (vPos4 - vPos3), 1.0);
    col = mix(col, col4, perc);
	
	perc = min(max(r - vPos4, 0.0) / (vPos5 - vPos4), 1.0);
    col = mix(col, col5, perc);
	
	perc = min(max(r - vPos5, 0.0) / (1.0 - vPos5), 1.0);
    col = mix(col, col6, perc) * COLOR;
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	col.a *= mask.g;
	
	if (col.a < 0.001) {
		discard;
	} else {
		ALBEDO.rgb = col.rgb;
		ALPHA = col.a;
	}
}
