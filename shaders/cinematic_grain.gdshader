shader_type canvas_item;
render_mode unshaded, blend_mix;
// Very light transparent grain plus a subtle dark vignette.
// Does not sample the screen, which avoids an expensive framebuffer copy.
uniform sampler2D grain_tile : repeat_enable, filter_nearest;
uniform float grain_strength : hint_range(0.0, 0.20) = 0.052;
uniform float vignette_strength : hint_range(0.0, 0.30) = 0.10;
void fragment() {
    float tick = floor(TIME * 11.0);
    vec2 shift = vec2(fract(tick * 0.127), fract(tick * 0.371));
    float n = texture(grain_tile, UV * vec2(7.0, 4.2) + shift).r - 0.5;
    float grains = abs(n) * grain_strength * 1.5;
    float edge_distance = length((UV - vec2(0.5)) * vec2(1.25, 1.0));
    float edge = smoothstep(0.34, 0.76, edge_distance) * vignette_strength;
    float opacity = min(0.24, grains + edge);
    float bright = max(n, 0.0) * grain_strength * 1.5;
    vec3 tint = vec3(bright / max(opacity, 0.0001));
    COLOR = vec4(tint, opacity);
}
