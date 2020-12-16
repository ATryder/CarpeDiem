shader_type spatial;
render_mode blend_add,depth_draw_never,depth_test_disable,cull_back,unshaded;
//
// Description : Array and textureless GLSL 2D/3D/4D simplex 
//               noise functions.
//      Author : Ian McEwan, Ashima Arts.
//  Maintainer : stegu
//     Lastmod : 20110822 (ijm)
//     License : Copyright (C) 2011 Ashima Arts. All rights reserved.
//               Distributed under the MIT License. See LICENSE file.
//               https://github.com/ashima/webgl-noise
//               https://github.com/stegu/webgl-noise
// 

uniform sampler2D mask_tex : hint_white;

uniform sampler2D tex;
uniform sampler2D displace_tex;
uniform vec2 uv_scale;
uniform float timeScale;
uniform vec2 offset;
uniform highp float time = 0.0;
uniform highp float frequency = 1.0;

uniform float pixelOffset = 12.0;
uniform float texPixelOffset = 12.0;
uniform vec2 texelSize;
uniform float paddingWidth = 0.0001;
uniform float paddingHeight = 0.0001;

uniform vec4 fogUnmapped : hint_color;
uniform vec4 fogMapped : hint_color;

varying highp vec3 worldVert;

vec4 mod289_v4(highp vec4 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0; }

float mod289(highp float x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0; }

vec4 permute_v4(highp vec4 x) {
    return mod289_v4(((x*34.0)+1.0)*x);
}

float permute(highp float x) {
    return mod289(((x*34.0)+1.0)*x);
}

vec4 taylorInvSqrt_v4(highp vec4 r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

float taylorInvSqrt(highp float r) {
    return 1.79284291400159 - 0.85373472095314 * r;
}

vec4 grad4(highp float j, highp vec4 ip) {
    highp vec4 ones = vec4(1.0, 1.0, 1.0, -1.0);
    highp vec4 p,s;

    p.xyz = floor( fract (vec3(j) * ip.xyz) * 7.0) * ip.z - 1.0;
    p.w = 1.5 - dot(abs(p.xyz), ones.xyz);
    s = vec4(lessThan(p, vec4(0.0)));
    p.xyz = p.xyz + (s.xyz*2.0 - 1.0) * s.www; 

    return p;
}

float simplex4d(highp vec4 point, highp float freq) {
	highp vec4 v = point * freq;
    // (sqrt(5) - 1)/4 = F4, used once below
    highp float F4 = 0.309016994374947451;
    
    highp vec4  C = vec4( 0.138196601125011,  // (5 - sqrt(5))/20  G4
                        0.276393202250021,  // 2 * G4
                        0.414589803375032,  // 3 * G4
                       -0.447213595499958); // -1 + 4 * G4

    // First corner
    highp vec4 i  = floor(v + dot(v, vec4(F4)) );
    highp vec4 x0 = v -   i + dot(i, C.xxxx);

    // Other corners

    // Rank sorting originally contributed by Bill Licea-Kane, AMD (formerly ATI)
    highp vec4 i0;
    highp vec3 isX = step( x0.yzw, x0.xxx );
    highp vec3 isYZ = step( x0.zww, x0.yyz );
    //  i0.x = dot( isX, vec3( 1.0 ) );
    i0.x = isX.x + isX.y + isX.z;
    i0.yzw = 1.0 - isX;
    //  i0.y += dot( isYZ.xy, vec2( 1.0 ) );
    i0.y += isYZ.x + isYZ.y;
    i0.zw += 1.0 - isYZ.xy;
    i0.z += isYZ.z;
    i0.w += 1.0 - isYZ.z;

    // i0 now contains the unique values 0,1,2,3 in each channel
    highp vec4 i3 = clamp( i0, 0.0, 1.0 );
    highp vec4 i2 = clamp( i0-1.0, 0.0, 1.0 );
    highp vec4 i1 = clamp( i0-2.0, 0.0, 1.0 );

    //  x0 = x0 - 0.0 + 0.0 * C.xxxx
    //  x1 = x0 - i1  + 1.0 * C.xxxx
    //  x2 = x0 - i2  + 2.0 * C.xxxx
    //  x3 = x0 - i3  + 3.0 * C.xxxx
    //  x4 = x0 - 1.0 + 4.0 * C.xxxx
    highp vec4 x1 = x0 - i1 + C.xxxx;
    highp vec4 x2 = x0 - i2 + C.yyyy;
    highp vec4 x3 = x0 - i3 + C.zzzz;
    highp vec4 x4 = x0 + C.wwww;

    // Permutations
    i = mod289_v4(i); 
    highp float j0 = permute( permute( permute( permute(i.w) + i.z) + i.y) + i.x);
    highp vec4 j1 = permute_v4( permute_v4( permute_v4( permute_v4 (
             i.w + vec4(i1.w, i2.w, i3.w, 1.0 ))
           + i.z + vec4(i1.z, i2.z, i3.z, 1.0 ))
           + i.y + vec4(i1.y, i2.y, i3.y, 1.0 ))
           + i.x + vec4(i1.x, i2.x, i3.x, 1.0 ));

    // Gradients: 7x7x6 points over a cube, mapped onto a 4-cross polytope
    // 7*7*6 = 294, which is close to the ring size 17*17 = 289.
    highp vec4 ip = vec4(1.0/294.0, 1.0/49.0, 1.0/7.0, 0.0) ;

    highp vec4 p0 = grad4(j0,   ip);
    highp vec4 p1 = grad4(j1.x, ip);
    highp vec4 p2 = grad4(j1.y, ip);
    highp vec4 p3 = grad4(j1.z, ip);
    highp vec4 p4 = grad4(j1.w, ip);

    // Normalise gradients
    highp vec4 norm = taylorInvSqrt_v4(vec4(dot(p0,p0), dot(p1,p1), dot(p2, p2), dot(p3,p3)));
    p0 *= norm.x;
    p1 *= norm.y;
    p2 *= norm.z;
    p3 *= norm.w;
    p4 *= taylorInvSqrt(dot(p4,p4));

    // Mix contributions from the five corners
    highp vec3 m0 = max(0.6 - vec3(dot(x0,x0), dot(x1,x1), dot(x2,x2)), vec3(0.0));
    highp vec2 m1 = max(0.6 - vec2(dot(x3,x3), dot(x4,x4)            ), vec2(0.0));
    m0 = m0 * m0;
    m1 = m1 * m1;
    return 49.0 * ( dot(m0*m0, vec3( dot( p0, x0 ), dot( p1, x1 ), dot( p2, x2 )))
               + dot(m1*m1, vec2( dot( p3, x3 ), dot( p4, x4 ) ) ) ) ;

}

void vertex() {
	worldVert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	highp float value = simplex4d(vec4(worldVert + vec3(offset, 0.0), time), frequency) * 0.5 + 0.5;
	value -= 0.5;
	highp vec2 displace = vec2(value) * pixelOffset;
	value = texture(displace_tex, (UV + (offset * timeScale)) * uv_scale).r;
	value -= 0.5;
	displace += vec2(value) * texPixelOffset;
	displace *= texelSize;
	vec2 coord = UV + displace;
	
	vec4 col = texture(tex, coord);
	vec3 mask = texture(mask_tex, vec2(UV.x, 1.0 - UV.y)).rgb;
	col.a *= mask.r;
	
	/*if (col.a <= 0.001) {
		discard;
	} else {
		vec3 bw = vec3((col.r + col.g + col.b) / 3.0) + vec3(0.1);
		ALBEDO = mix(bw * vec3(0.221, 0.953, 1.0), col.rgb, mask.g);
		ALPHA = col.a;
	}*/
	
	vec4 unmapped = fogUnmapped;
	unmapped.a = clamp(UV.x / paddingWidth, 0.0, 1.0);
	unmapped.a *= clamp((1.0 - UV.x) / paddingWidth, 0.0, 1.0);
	unmapped.a *= clamp(UV.y / paddingHeight, 0.0, 1.0);
	unmapped.a *= clamp((1.0 - UV.y) / paddingHeight, 0.0, 1.0);
	
	vec4 bw = vec4(vec3((col.r + col.g + col.b) / 3.0) + vec3(0.1), 1.0) * fogMapped;
	bw = mix(unmapped, bw, mask.r);
	col = mix(bw, col, mask.g);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}
