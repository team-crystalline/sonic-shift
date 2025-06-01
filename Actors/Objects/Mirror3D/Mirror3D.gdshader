shader_type spatial;
render_mode unshaded; // Mirror texture is already shaded
render_mode cull_disabled; // Show both sides of mirror

uniform vec4 color : source_color;
uniform sampler2D mirror_texture_linear : source_color, filter_linear_mipmap;
uniform sampler2D mirror_texture_nearest : source_color, filter_nearest_mipmap;
uniform bool use_mirror_texture_linear = true;
uniform sampler2D distortion_texture : source_color, filter_linear_mipmap;
uniform float distortion_strength : hint_range(0, 100, 0.01);
uniform float blur_amount : hint_range(0, 0.1, 0.0001) = 0.005;

void vertex() {
	// Flip mirror horizontally
	UV.x = 1.0 - UV.x;
}

void fragment() {
	// Get correct UV for both sides
	vec2 uv = FRONT_FACING ? UV : vec2(1.0 - UV.x, UV.y);

	// Get distortion from texture
	float distortion_offset = texture(distortion_texture, uv).r;
	// Center distortion offset (map to [-1, 1] region)
	distortion_offset = (distortion_offset * 2.0) - 1.0;
	// Distort UV
	vec2 distorted_uv = uv + (distortion_offset * distortion_strength / VIEWPORT_SIZE);

	// Sample viewport texture at distorted position with blur
	vec4 mirror_sample = vec4(0.0);
	if (use_mirror_texture_linear) {
		mirror_sample += texture(mirror_texture_linear, distorted_uv + vec2(-blur_amount, -blur_amount));
		mirror_sample += texture(mirror_texture_linear, distorted_uv + vec2(blur_amount, -blur_amount));
		mirror_sample += texture(mirror_texture_linear, distorted_uv + vec2(-blur_amount, blur_amount));
		mirror_sample += texture(mirror_texture_linear, distorted_uv + vec2(blur_amount, blur_amount));
		mirror_sample += texture(mirror_texture_linear, distorted_uv);
		mirror_sample /= 5.0;
	} else {
		mirror_sample += texture(mirror_texture_nearest, distorted_uv + vec2(-blur_amount, -blur_amount));
		mirror_sample += texture(mirror_texture_nearest, distorted_uv + vec2(blur_amount, -blur_amount));
		mirror_sample += texture(mirror_texture_nearest, distorted_uv + vec2(-blur_amount, blur_amount));
		mirror_sample += texture(mirror_texture_nearest, distorted_uv + vec2(blur_amount, blur_amount));
		mirror_sample += texture(mirror_texture_nearest, distorted_uv);
		mirror_sample /= 5.0;
	}

	// Mix sample and color modulate
	ALBEDO = mirror_sample.rgb * color.rgb;
	ALPHA = mirror_sample.a * color.a;
}
