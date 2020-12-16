shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform sampler2D TEXTURE2 : hint_black;
uniform bool reverse = false;

uniform vec4 color : hint_color;
uniform float colorSize = 0.0;
uniform float leadingFade = 0.0;
uniform float trailingFade = 0.0;
uniform float numBlades = 1.0;
uniform float bladeLength = 0.6;
uniform float perc = 0.0;

uniform float offset : hint_range(0.0, 1.0) = 1.0;
uniform float angle = 0.0;

varying float uvRange;
varying vec2 suv;

void vertex() {
	float offsetMag = clamp(offset, 0.0, 1.0);
	uvRange = mix(offsetMag, 1.0 - offsetMag, step(offsetMag, 0.5));
	
	vec2 uv = vec2(UV.x - 0.5, UV.y - 0.5);
	float s = sin(angle);
    float c = cos(angle);
    uv = vec2((c * uv.x) - (s * uv.y), (s * uv.x) + (c * uv.y));
    uv += vec2(0.5, 0.5 - offset);
	suv = uv;
}

void fragment() {
	float rev = float(!reverse);
	vec4 t = texture(TEXTURE, UV);
	vec4 t2 = texture (TEXTURE2, UV);
	vec4 tex = mix(t, t2, rev);
	vec4 tex2 = mix(t2, t, rev);
	vec4 edgeCol = mix(tex, vec4(color.rgb, color.a * step(0.001, min(tex.a + tex2.a, 1.0))), color.a);
	float y = abs(suv.y);
	float bladeHeight = uvRange / numBlades;
	float currentBlade = floor(y / bladeHeight);
	float track = ((y - (bladeHeight * currentBlade)) / bladeHeight) * bladeLength;
	track = (currentBlade / numBlades) * (1.0 - bladeLength) + track;
	
	float tFade = max(leadingFade, 0.0001);
	float lFade = max(trailingFade, 0.0001);
	float cSize = colorSize;
	float p = (1.0 - perc) * (1.0 + lFade + tFade + cSize);
	float pos = p - track;
	vec4 col = mix(tex2, edgeCol, clamp(pos, 0.0, lFade) / lFade);
	col = mix(col, tex, clamp(pos - lFade - cSize, 0.0, tFade) / tFade);
	
	if (col.a < 0.001) {
		discard;
	} else {
		COLOR = col;
	}
}