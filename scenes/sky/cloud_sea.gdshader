shader_type spatial;
render_mode unshaded, cull_back;
// An endless sea of clouds far below the level. Cheap: one opaque plane, a little noise.

uniform vec3 deep_color : source_color = vec3(0.36, 0.62, 0.92);
uniform vec3 light_color : source_color = vec3(0.93, 0.97, 1.0);
uniform float scale = 0.018;
uniform float speed = 0.012;

varying vec3 world_pos;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash21(i), hash21(i + vec2(1.0, 0.0)), f.x),
			mix(hash21(i + vec2(0.0, 1.0)), hash21(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz * scale + vec2(TIME * speed, TIME * speed * 0.6);
	float n = vnoise(p) * 0.5 + vnoise(p * 2.1 + 7.0) * 0.3 + vnoise(p * 4.3 + 3.0) * 0.2;
	float c = smoothstep(0.35, 0.75, n);
	ALBEDO = mix(deep_color, light_color, c);
}
