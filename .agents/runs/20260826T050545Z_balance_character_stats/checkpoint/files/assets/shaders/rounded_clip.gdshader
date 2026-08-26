shader_type canvas_item;

uniform vec2 rect_size = vec2(132.0, 94.0);
uniform float radius_px = 13.0;

void fragment() {
	vec4 source = texture(TEXTURE, UV) * COLOR;
	vec2 pixel = UV * rect_size;
	vec2 edge = min(pixel, rect_size - pixel);
	vec2 corner = max(vec2(radius_px) - edge, vec2(0.0));
	float distance_to_corner = length(corner);
	float alpha = clamp(radius_px - distance_to_corner + 0.75, 0.0, 1.0);
	source.a *= alpha;
	COLOR = source;
}
