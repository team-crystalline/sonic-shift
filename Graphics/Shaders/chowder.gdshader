shader_type spatial;
render_mode unshaded;

uniform sampler2D texture_albedo;
uniform float scale = 1.0;

void fragment() {
    vec2 screen_uv = SCREEN_UV * scale;
    vec4 tex = texture(texture_albedo, screen_uv);
    ALBEDO = tex.rgb;
}

void vertex() {
    mat4 modified_model_view = VIEW_MATRIX * mat4(
        INV_VIEW_MATRIX[0],
        INV_VIEW_MATRIX[1],
        INV_VIEW_MATRIX[2],
        MODEL_MATRIX[3]
    );
    MODELVIEW_MATRIX = modified_model_view;
}