shader_type particles;
render_mode billboard;

uniform float min_speed;
uniform float max_speed;
uniform float min_length : hint_range(0, 1);
uniform float max_length : hint_range(0, 1);
uniform float scale;
uniform float hue_variation;
uniform float scale_random;
uniform float hue_variation_random;
uniform float emission_sphere_radius;
uniform vec4 color_value : hint_color;
uniform sampler2D color_ramp;


float rand_from_seed(inout uint seed) {
	int k;
	int s = int(seed);
	if (s == 0)
	s = 305420679;
	k = s / 127773;
	s = 16807 * (s - k * 127773) - 2836 * k;
	if (s < 0)
		s += 2147483647;
	seed = uint(s);
	return float(seed % uint(65536))/65535.0;
}

float rand_from_seed_m1_p1(inout uint seed) {
	return rand_from_seed(seed)*2.0-1.0;
}

uint hash(uint x) {
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = ((x >> uint(16)) ^ x) * uint(73244475);
	x = (x >> uint(16)) ^ x;
	return x;
}

float rand_range(in float low, in float high, in uint seed) {
	return low + ((high - low) * rand_from_seed(seed));
}

/*float bezier(in float startPoint, in float startControl, in float endControl, in float endPoint, in float t) {
	return pow(1.0 - t, 3.0) * startPoint + 3.0 * pow(1.0 - t, 2.0) * t * startControl + 3.0 * (1.0 - t) * pow(t, 2) * endControl + pow(t, 3) * endPoint;
}*/

/*vec3 vsmooth(in vec3 startVec, in vec3 endVec, in float t) {
	vec3 outVec = vec3(0.0);
	outVec.x = bezier(startVec.x, startVec.x + ((endVec.x - startVec.x) * 0.05), startVec.x + ((endVec.x - startVec.x) * 0.95), endVec.x, t);
	outVec.y = bezier(startVec.y, startVec.y + ((endVec.y - startVec.y) * 0.05), startVec.y + ((endVec.y - startVec.y) * 0.95), endVec.y, t);
	outVec.z = bezier(startVec.z, startVec.z + ((endVec.z - startVec.z) * 0.05), startVec.z + ((endVec.z - startVec.z) * 0.95), endVec.z, t);
	return outVec;
}*/

void vertex() {
	uint alt_seed = hash(NUMBER+uint(1)+RANDOM_SEED);
	//float angle_rand = rand_from_seed(alt_seed);
	float scale_rand = rand_from_seed(alt_seed);
	float hue_rot_rand = rand_from_seed(alt_seed);
	//float anim_offset_rand = rand_from_seed(alt_seed);
	float pi = 3.14159;
	//float degree_to_rad = pi / 180.0;

	if (RESTART) {
		CUSTOM.x = 0.0;
		CUSTOM.y = 0.0;
		CUSTOM.z = rand_range(min_length, max_length, alt_seed);
		CUSTOM.w = 0.0;
		
		uint r = RANDOM_SEED + NUMBER + alt_seed;
		float ang = rand_from_seed_m1_p1(r) * pi;
		float s = sin(ang);
		float c = cos(ang);
		float speed = rand_range(min_speed, max_speed, RANDOM_SEED + NUMBER);
		VELOCITY = vec3(-s * speed, 0.0, c * speed) * max(DELTA, 0.0625);
		
		TRANSFORM[3].xyz = normalize(vec3(rand_from_seed(alt_seed) * 2.0 - 1.0, rand_from_seed(alt_seed) * 2.0-1.0, rand_from_seed(alt_seed) * 2.0-1.0 ))*emission_sphere_radius;
		VELOCITY = (EMISSION_TRANSFORM * vec4(VELOCITY,0.0)).xyz;
		TRANSFORM = EMISSION_TRANSFORM * TRANSFORM;
		
	} else {
		CUSTOM.x += DELTA/LIFETIME;
		CUSTOM.y += DELTA/LIFETIME;
		if (CUSTOM.y >= CUSTOM.z) {
			CUSTOM.y -= floor(CUSTOM.y / CUSTOM.z) * CUSTOM.z;
			CUSTOM.w += 1.0;
			CUSTOM.z = rand_range(min_length, max_length, alt_seed + uint(CUSTOM.w));
		}
		
		float modLength = CUSTOM.z;
		uint turn = uint(CUSTOM.w);
		float modPerc = CUSTOM.y / modLength;
		
		uint r = RANDOM_SEED + turn + NUMBER + alt_seed;
		float ang = rand_from_seed_m1_p1(r) * pi;
		float s = sin(ang);
		float c = cos(ang);
		float speed = rand_range(min_speed, max_speed, RANDOM_SEED + turn + NUMBER);
		vec3 prevVel = vec3(-s * speed, 0.0, c * speed);
		
		r = RANDOM_SEED + turn + NUMBER + uint(1) + alt_seed;
		ang = rand_from_seed_m1_p1(r) * pi;
		s = sin(ang);
		c = cos(ang);
		speed = rand_range(min_speed, max_speed, RANDOM_SEED + turn + NUMBER + uint(1));
		vec3 nextVel = vec3(-s * speed, 0.0, c * speed);
		
		//VELOCITY = vsmooth(prevVel, nextVel, modPerc) * DELTA;
		VELOCITY = mix(prevVel, nextVel, modPerc) * max(DELTA, 0.0625);
	}
	float tex_scale = 1.0;
	float tex_hue_variation = 0.0;
	float hue_rot_angle = (hue_variation+tex_hue_variation)*pi*2.0*mix(1.0,hue_rot_rand*2.0-1.0,hue_variation_random);
	float hue_rot_c = cos(hue_rot_angle);
	float hue_rot_s = sin(hue_rot_angle);
	mat4 hue_rot_mat = mat4( vec4(0.299,  0.587,  0.114, 0.0),
			vec4(0.299,  0.587,  0.114, 0.0),
			vec4(0.299,  0.587,  0.114, 0.0),
			vec4(0.000,  0.000,  0.000, 1.0)) +
		mat4( vec4(0.701, -0.587, -0.114, 0.0),
			vec4(-0.299,  0.413, -0.114, 0.0),
			vec4(-0.300, -0.588,  0.886, 0.0),
			vec4(0.000,  0.000,  0.000, 0.0)) * hue_rot_c +
		mat4( vec4(0.168,  0.330, -0.497, 0.0),
			vec4(-0.328,  0.035,  0.292, 0.0),
			vec4(1.250, -1.050, -0.203, 0.0),
			vec4(0.000,  0.000,  0.000, 0.0)) * hue_rot_s;
	COLOR = textureLod(color_ramp, vec2(CUSTOM.x, 0.0), 0.0) * hue_rot_mat;

	TRANSFORM[0].xyz = normalize(TRANSFORM[0].xyz);
	TRANSFORM[1].xyz = normalize(TRANSFORM[1].xyz);
	TRANSFORM[2].xyz = normalize(TRANSFORM[2].xyz);
	float base_scale = mix(scale*tex_scale,1.0,scale_random*scale_rand);
	if (base_scale==0.0) base_scale=0.000001;
	TRANSFORM[0].xyz *= base_scale;
	TRANSFORM[1].xyz *= base_scale;
	TRANSFORM[2].xyz *= base_scale;
}

