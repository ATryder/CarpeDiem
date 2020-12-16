shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float blurScale = 1.0;

void fragment() {
	vec4 sum = vec4(0.0);
	vec2 pixelSize = TEXTURE_PIXEL_SIZE * blurScale;
	
	sum += texture(TEXTURE, vec2(UV.x - 4.0*pixelSize.x, UV.y)) * 0.000229;
	sum += texture(TEXTURE, vec2(UV.x - 3.0*pixelSize.x, UV.y)) * 0.005977;
	sum += texture(TEXTURE, vec2(UV.x - 2.0*pixelSize.x, UV.y)) * 0.060598;
	sum += texture(TEXTURE, vec2(UV.x - pixelSize.x, UV.y)) * 0.241732;
	sum += texture(TEXTURE, vec2(UV.x, UV.y)) * 0.382928;
	sum += texture(TEXTURE, vec2(UV.x + pixelSize.x, UV.y)) * 0.241732;
	sum += texture(TEXTURE, vec2(UV.x + 2.0*pixelSize.x, UV.y)) * 0.060598;
	sum += texture(TEXTURE, vec2(UV.x + 3.0*pixelSize.x, UV.y)) * 0.005977;
	sum += texture(TEXTURE, vec2(UV.x + 4.0*pixelSize.x, UV.y)) * 0.000229;
	
	COLOR = sum;
}