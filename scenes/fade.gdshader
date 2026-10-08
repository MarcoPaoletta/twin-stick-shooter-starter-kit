shader_type spatial;
// Level material with "see-through" walls: surfaces that sit between the camera and
// the player dissolve with a dither pattern, so walls never hide the character.
// Replaces the StandardMaterial3D of the prototype kit (same texture, same roughness).

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness_value : hint_range(0.0, 1.0) = 0.4;
uniform float inner_radius = 1.8;
uniform float outer_radius = 3.4;
uniform float keep_near_target = 1.8;

global uniform vec3 fade_cam_pos;
global uniform vec3 fade_target_pos;
global uniform float fade_enabled;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	ALBEDO = texture(albedo_tex, UV).rgb;
	ROUGHNESS = roughness_value;

	if (fade_enabled > 0.01) {
		vec3 seg = fade_target_pos - fade_cam_pos;
		float len = max(length(seg), 0.001);
		vec3 dir = seg / len;
		vec3 rel = world_pos - fade_cam_pos;
		float t = dot(rel, dir);
		float dist = length(rel - dir * t);
		// only surfaces in front of the player (towards the camera)
		float in_front = smoothstep(len - keep_near_target, len - keep_near_target - 1.5, t);
		// walls and ceilings fade; surfaces that face up (floors) never do
		float not_floor = 1.0 - smoothstep(0.55, 0.8, world_normal.y);
		float amount = (1.0 - smoothstep(inner_radius, outer_radius, dist)) * in_front * not_floor * fade_enabled;
		float noise = fract(52.9829189 * fract(dot(FRAGCOORD.xy, vec2(0.06711056, 0.00583715))));
		if (amount > noise * 0.999 + 0.0005) {
			discard;
		}
	}
}
