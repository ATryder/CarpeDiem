shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform sampler2D TEXTURE2 : hint_black;
uniform bool reverse = false;

uniform vec4 color : hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform sampler2D grid : hint_white;

uniform float offset : hint_range(0.0, 1.0) = 0.0;
uniform float colorSize = 0.0;
uniform float leadingFade = 0.0;
uniform float trailingFade = 0.0;
uniform float squareLength = 0.6;
uniform float rows = 1.0;
uniform float perc = 0.0;

uniform float angle = 0.0;

varying vec2 suv;
varying float uvRange;

void vertex() {
	float offsetMag = abs(offset);
	uvRange = mix(offsetMag, 1.0 - offsetMag, step(offsetMag, 0.5));
	
	vec2 uv = vec2(UV.x - 0.5, UV.y - 0.5);
	float s = sin(angle);
    float c = cos(angle);
    uv = vec2((c * uv.x) - (s * uv.y), (s * uv.x) + (c * uv.y));
    uv += vec2(0.5, 0.5 - offset);
	suv = uv;
}

void fragment() {
	float rev = float(reverse);
	vec4 t = texture(TEXTURE, UV);
	vec4 t2 = texture (TEXTURE2, UV);
	vec4 tex = mix(t, t2, rev);
	vec4 tex2 = mix(t2, t, rev);
	vec4 edgeCol = mix(tex, vec4(color.rgb, color.a * step(0.001, min(tex.a + tex2.a, 1.0))), color.a);
	float y = abs(suv.y);
	float rowHeight = uvRange / rows;
	float currentRow = floor(y / rowHeight);
	
	
	float track = ((y - (rowHeight * currentRow)) / rowHeight) * squareLength;
	//track = (currentRow / rows) * (1.0 - squareLength) + track;
	track = texture(grid, suv).a * (1.0 - squareLength) + track;
	
	float p = perc * (1.0 + leadingFade + colorSize + trailingFade);
	float pos = p - track;
	float lFade = max(leadingFade, 0.0001);
	vec4 col = mix(tex2, edgeCol, clamp(pos, 0.0, lFade) / lFade);
	float tFade = max(trailingFade, 0.0001);
	col = mix(col, tex, clamp(pos - leadingFade - colorSize, 0.0, tFade) / tFade);
	
	if (col.a < 0.001) {
		discard;
	} else {
		COLOR = col;
	}
}
