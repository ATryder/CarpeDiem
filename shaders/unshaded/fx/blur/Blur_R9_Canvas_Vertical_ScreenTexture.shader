shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float blurScale = 1.0;

void fragment() {
	vec4 sum = vec4(0.0);
	vec2 pixelSize = SCREEN_PIXEL_SIZE * blurScale;
	
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 4.0*pixelSize.y)) * 0.06;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 3.0*pixelSize.y)) * 0.09;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - 2.0*pixelSize.y)) * 0.12;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y - pixelSize.y)) * 0.15;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y)) * 0.16;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + pixelSize.y)) * 0.15;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 2.0*pixelSize.y)) * 0.12;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 3.0*pixelSize.y)) * 0.09;
	sum += texture(SCREEN_TEXTURE, vec2(SCREEN_UV.x, SCREEN_UV.y + 4.0*pixelSize.y)) * 0.06;
	
	COLOR = vec4(sum.rgb, 1.0);
}