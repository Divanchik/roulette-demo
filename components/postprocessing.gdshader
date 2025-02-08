shader_type canvas_item;
uniform sampler2D gradient;
uniform int color_amount;
uniform sampler2D SCREEN_TEXTURE: hint_screen_texture, filter_nearest, repeat_disable;

void fragment() {
	vec3 clr = texture(SCREEN_TEXTURE, SCREEN_UV).rgb;
	vec3 gray = vec3(0.299 * clr.r + 0.587 * clr.g + 0.114 * clr.b);
	vec3 quantity = vec3(float(color_amount-1));
	vec3 clr1 = floor(fma(gray, quantity, vec3(0.5))) / quantity;
	COLOR.rgb = texture(gradient, clr1.rg).rgb;
}
