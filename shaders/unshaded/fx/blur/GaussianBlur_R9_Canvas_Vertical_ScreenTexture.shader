shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float blurScale = 1.0;

void fragment() {
	vec4 sum = vec4(0.0);
	vec2 pixelSize = SCREEN_PIXEL_SIZE * blurScale;
	
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 4.0*pixelSize.y)) * 0.000229;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 3.0*pixelSize.y)) * 0.005977;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 2.0*pixelSize.y)) * 0.060598;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - pixelSize.y)) * 0.241732;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y)) * 0.382928;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + pixelSize.y)) * 0.241732;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 2.0*pixelSize.y)) * 0.060598;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 3.0*pixelSize.y)) * 0.005977;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 4.0*pixelSize.y)) * 0.000229;
	
	COLOR = sum;
}