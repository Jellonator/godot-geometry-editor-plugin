shader_type spatial;
render_mode unshaded;

void fragment() {
	ALBEDO.rgb = (NORMAL * vec3(0.5)) + vec3(0.5);
}
