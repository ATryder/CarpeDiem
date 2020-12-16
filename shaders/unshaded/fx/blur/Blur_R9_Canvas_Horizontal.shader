shader_type canvas_item;
render_mode blend_mix,unshaded;

uniform float blurScale = 1.0;

void fragment() {
	vec4 sum = vec4(0.0);
	vec2 pixelSize = TEXTURE_PIXEL_SIZE * blurScale;
	
	sum += texture(TEXTURE, vec2(UV.x - 4.0*pixelSize.x, UV.y)) * 0.06;
	sum += texture(TEXTURE, vec2(UV.x - 3.0*pixelSize.x, UV.y)) * 0.09;
	sum += texture(TEXTURE, vec2(UV.x - 2.0*pixelSize.x, UV.y)) * 0.12;
	sum += texture(TEXTURE, vec2(UV.x - pixelSize.x, UV.y)) * 0.15;
	sum += texture(TEXTURE, vec2(UV.x, UV.y)) * 0.16;
	sum += texture(TEXTURE, vec2(UV.x + pixelSize.x, UV.y)) * 0.15;
	sum += texture(TEXTURE, vec2(UV.x + 2.0*pixelSize.x, UV.y)) * 0.12;
	sum += texture(TEXTURE, vec2(UV.x + 3.0*pixelSize.x, UV.y)) * 0.09;
	sum += texture(TEXTURE, vec2(UV.x + 4.0*pixelSize.x, UV.y)) * 0.06;
	
	COLOR = vec4(sum.rgb, 1.0);
}