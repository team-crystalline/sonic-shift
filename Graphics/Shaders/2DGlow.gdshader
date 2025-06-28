shader_type canvas_item;

uniform vec4 glow_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float glow_intensity : hint_range(0.0, 10.0) = 1.0;
uniform float glow_width : hint_range(1.0, 20.0) = 5.0;

void fragment() {
    vec4 original_texture = texture(TEXTURE, UV);

    // Create silhouette
    float silhouette_alpha = 0.0;
    for(float x = -1.0; x <= 1.0; x += 1.0) {
        for(float y = -1.0; y <= 1.0; y += 1.0) {
            vec2 offset = vec2(x, y) * TEXTURE_PIXEL_SIZE * glow_width;
            silhouette_alpha += step(0.1, texture(TEXTURE, UV + offset).a);
        }
    }

    // Normalize and clamp silhouette alpha
    silhouette_alpha = clamp(silhouette_alpha / 9.0, 0.0, 1.0);

    // Create glow silhouette
    vec4 glow = vec4(glow_color.rgb, silhouette_alpha * glow_intensity);

    // Blend original texture
    COLOR = original_texture.a > 0.0 ? original_texture : glow;
}
