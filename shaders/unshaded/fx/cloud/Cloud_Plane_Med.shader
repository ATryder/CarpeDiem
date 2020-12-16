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
uniform highp float frequency = 1.0;

uniform float pixelOffset = 12.0;
uniform float texPixelOffset = 12.0;
uniform vec2 texelSize;
uniform float paddingWidth = 0.0001;
uniform float paddingHeight = 0.0001;

uniform vec4 fogUnmapped : hint_color;
uniform vec4 fogMapped : hint_color;

varying highp vec3 worldVert;

vec3 mod289_v3(highp vec3 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec2 mod289_v2(highp vec2 x) {
    return x - floor(x * (1.0 / 289.0)) * 289.0;
}

vec3 permute(highp vec3 x) {
    return mod289_v3(((x*34.0)+1.0)*x);
}

float simplex2d(highp vec2 point, highp float freq) {
	highp vec2 v = point * freq;
    highp vec4 C = vec4(0.211324865405187,  // (3.0-sqrt(3.0))/6.0
                  0.366025403784439,  // 0.5*(sqrt(3.0)-1.0)
                 -0.577350269189626,  // -1.0 + 2.0 * C.x
                  0.024390243902439); // 1.0 / 41.0
    // First corner
    highp vec2 i  = floor(v + dot(v, C.yy) );
    highp vec2 x0 = v -   i + dot(i, C.xx);

    // Other corners
    highp vec2 i1;
    //i1.x = step( x0.y, x0.x ); // x0.x > x0.y ? 1.0 : 0.0
    //i1.y = 1.0 - i1.x;
    i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
    // x0 = x0 - 0.0 + 0.0 * C.xx ;
    // x1 = x0 - i1 + 1.0 * C.xx ;
    // x2 = x0 - 1.0 + 2.0 * C.xx ;
    highp vec4 x12 = vec4(x0.xy, x0.xy) + vec4(C.xx, C.zz);
    x12.xy -= i1;

    // Permutations
    i = mod289_v2(i); // Avoid truncation effects in permutation
    highp vec3 p = permute( permute( i.y + vec3(0.0, i1.y, 1.0 ))
	    + i.x + vec3(0.0, i1.x, 1.0 ));

    highp vec3 m = max(0.5 - vec3(dot(x0,x0), dot(x12.xy,x12.xy), dot(x12.zw,x12.zw)), vec3(0.0));
    m = m*m ;
    m = m*m ;

    // Gradients: 41 points uniformly over a line, mapped onto a diamond.
    // The ring size 17*17 = 289 is close to a multiple of 41 (41*7 = 287)

    highp vec3 x = 2.0 * fract(p * C.www) - 1.0;
    highp vec3 h = abs(x) - 0.5;
    highp vec3 ox = floor(x + 0.5);
    highp vec3 a0 = x - ox;

    // Normalise gradients implicitly by scaling m
    // Approximation of: m *= inversesqrt( a0*a0 + h*h );
    m *= 1.79284291400159 - 0.85373472095314 * ( a0*a0 + h*h );

    // Compute final noise value at P
    highp vec3 g;
    g.x  = a0.x  * x0.x  + h.x  * x0.y;
    g.yz = a0.yz * x12.xz + h.yz * x12.yw;
    return 130.0 * dot(m, g);
}

void vertex() {
	worldVert = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	highp float value = simplex2d(worldVert.xz + offset, frequency) * 0.5 + 0.5;
	value -= 0.5;
	highp vec2 displace = vec2(value) * pixelOffset;
	value = texture(displace_tex, (UV + (offset * timeScale)) * uv_scale).r;
	value -= 0.5;
	displace += vec2(value) * texPixelOffset;
	displace *= texelSize;
	vec2 coord = UV + displace;
	
	vec4 col = texture(tex, coord);
	vec3 mask = texture(mask_tex, vec2(UV.x, 1.0 - UV.y)).rgb;
	
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
