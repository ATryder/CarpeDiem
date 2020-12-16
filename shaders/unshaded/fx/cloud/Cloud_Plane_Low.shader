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
uniform vec2 offset;
uniform float timeScale;
uniform vec2 uv_scale;

uniform float pixelOffset = 12;
uniform vec2 texelSize;
uniform float paddingWidth = 0.0001;
uniform float paddingHeight = 0.0001;

uniform vec4 fogUnmapped : hint_color;
uniform vec4 fogMapped : hint_color;

void fragment() {
	float value = texture(displace_tex, (UV + (offset * timeScale)) * uv_scale).r;
	value -= 0.5;
	vec2 displace = vec2(value) * pixelOffset;
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
