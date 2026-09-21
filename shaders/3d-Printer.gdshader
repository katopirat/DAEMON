shader_type spatial;

uniform float nozzle_world_y = 0.0;
uniform bool reveal_complete = false;

varying float world_y;

void vertex() {
	world_y = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

void fragment() {
	if (!reveal_complete && world_y > nozzle_world_y) {
		discard;
	}
	ALBEDO = vec3(0.85, 0.83, 0.8);
}