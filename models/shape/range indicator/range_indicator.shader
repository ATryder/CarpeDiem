shader_type spatial;
render_mode blend_mix,depth_draw_never,depth_test_disable,cull_back,unshaded;

uniform bool reverse = false;

uniform float offset = 0.0;
uniform float radius = 0.0;
uniform float radius2 = 0.0;
uniform float fadeLength = 3.0;
uniform vec2 alphaRange = vec2(0.63, 1.0);

uniform vec4 col1 : hint_color;
uniform vec4 col2 : hint_color;
uniform vec4 col3 : hint_color;
uniform vec4 col4 : hint_color;

uniform vec2 minimum = vec2(0, 0);
uniform vec2 extent = vec2(0.01, 0.01);
uniform vec2 minimum2 = vec2(0, 0);
uniform vec2 extent2 = vec2(0.01, 0.01);

void fragment() {
	float uvx = UV2.x + offset;
	uvx = mix(uvx, uvx - floor(uvx), step(1.0, uvx));
	float alphaGrad = mix(uvx / 0.5, 1.0 - ((uvx - 0.5) / 0.5), step(0.5, uvx));
	alphaGrad = mix(alphaRange.x, alphaRange.y, alphaGrad);
	
	float x = UV.x;
    float y = UV.y;
    float r = sqrt((x*x) + (y*y));
    float perc = min(max(r - (radius - fadeLength), 0.0) / max(radius - (radius - fadeLength), 0.001), 1.0);
	alphaGrad = mix(0.0, alphaGrad, 1.0 - perc);
	
	perc = min(max(r - (radius2 - fadeLength), 0.0) / max(radius2 - (radius2 - fadeLength), 0.001), 1.0);
	alphaGrad = mix(0.0, alphaGrad, perc);
	
	vec2 uvGrad = (UV - minimum) / extent;
	uvGrad.y = 1.0 - uvGrad.y;
	vec4 gradCol = vec4(mix(col1, col2, uvGrad.x));
	
	uvGrad = (UV - minimum2) / extent2;
	uvGrad.y = 1.0 - uvGrad.y;
	vec4 gradCol2 = vec4(mix(col3, col4, uvGrad.x));
	gradCol = vec4(mix(gradCol, gradCol2, COLOR.r));
	
	ALBEDO = gradCol.rgb;
	ALPHA = gradCol.a * alphaGrad;
}
