shader_type sky;
// Stylised daytime sky: blue gradient, soft drifting-looking clouds, a sun glow.
// No TIME on purpose: an animated sky would force the radiance map to re-render every frame.

uniform vec3 top_color : source_color = vec3(0.10, 0.33, 0.78);
uniform vec3 mid_color : source_color = vec3(0.30, 0.62, 0.95);
uniform vec3 horizon_color : source_color = vec3(0.74, 0.89, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 cloud_shadow : source_color = vec3(0.62, 0.74, 0.92);
uniform vec3 sun_color : source_color = vec3(1.0, 0.97, 0.85);
uniform float cloud_cover : hint_range(0.0, 1.0) = 0.52;
uniform float cloud_softness : hint_range(0.01, 0.6) = 0.28;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

float vnoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 5; i++) {
		v += a * vnoise(p);
		p = p * 2.03 + vec2(17.0, 9.0);
		a *= 0.5;
	}
	return v;
}

void sky() {
	vec3 dir = EYEDIR;
	float h = dir.y;
	vec3 col = mix(horizon_color, mid_color, smoothstep(0.0, 0.25, h));
	col = mix(col, top_color, smoothstep(0.2, 0.9, h));
	if (h < 0.0) {
		col = mix(horizon_color, horizon_color * 0.92, clamp(-h * 3.0, 0.0, 1.0));
	}

	// Clouds projected on a plane above the viewer.
	if (h > 0.01) {
		vec2 uv = dir.xz / (h + 0.18) * 1.6;
		float n = fbm(uv);
		float c = smoothstep(1.0 - cloud_cover - cloud_softness, 1.0 - cloud_cover + cloud_softness, n);
		float lit = fbm(uv + vec2(0.06, 0.09));
		vec3 cc = mix(cloud_color, cloud_shadow, clamp((n - lit) * 3.5 + 0.25, 0.0, 1.0));
		c *= smoothstep(0.01, 0.2, h);
		col = mix(col, cc, c);
	}

	// Sun.
	float sun = max(dot(dir, normalize(vec3(-0.45, 0.62, -0.64))), 0.0);
	col += sun_color * (pow(sun, 700.0) * 3.0 + pow(sun, 18.0) * 0.22);
	COLOR = col;
}
