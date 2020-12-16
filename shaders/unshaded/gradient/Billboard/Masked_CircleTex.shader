shader_type spatial;
render_mode blend_add,depth_draw_never,cull_back,unshaded,skip_vertex_transform;

uniform float radius = 0.5;
uniform vec2 center = vec2(0.5, 0.5);

uniform sampler2D tex : hint_albedo;

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
}


void fragment() {
	float x = UV.x - center.x;
    float y = UV.y - center.y;
    float r = sqrt((x*x) + (y*y));
    r = r * (1.0 / radius);
	
	vec4 col = texture(tex, vec2(r, 0.5)) * COLOR;
	
	vec3 mask = texture(mask_tex, (worldvert.xz * mask_scale) + mask_offset).rgb;
	col.a *= mask.g;
	
	if (col.a < 0.001) {
		discard;
	} else {
		ALBEDO.rgb = col.rgb;
		ALPHA = col.a;
	}
}
