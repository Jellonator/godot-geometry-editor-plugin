shader_type spatial;
render_mode unshaded, vertex_lighting;

void fragment() {
	ALBEDO.rgb = (NORMAL + vec3(1.0)) / vec3(2.0);
}
