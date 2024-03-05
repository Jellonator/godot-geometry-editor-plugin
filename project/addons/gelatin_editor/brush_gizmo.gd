extends EditorNode3DGizmoPlugin

func _get_gizmo_name():
	return "Brush Editor"

func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")

func _has_gizmo(node: Node):
	print(node)
	if not node is MeshInstance3D:
		return false
	if not node.mesh:
		return false
	return is_instance_of(node.mesh, BrushMesh)

func __get_brush_mesh(gizmo: EditorNode3DGizmo) -> BrushMesh:
	if gizmo.get_node_3d() == null or not gizmo.get_node_3d() is MeshInstance3D:
		return null
	var node: MeshInstance3D = gizmo.get_node_3d()
	if node.mesh == null or not is_instance_of(node.mesh, BrushMesh):
		return null
	return node.mesh

func __get_brush_data(gizmo: EditorNode3DGizmo) -> BrushData:
	var mesh = __get_brush_mesh(gizmo)
	if mesh == null:
		return null
	return mesh.mesh_data

func _redraw(gizmo: EditorNode3DGizmo):
	gizmo.clear()
	var mesh := __get_brush_data(gizmo)
	var handle_ids: PackedInt32Array = mesh.get_vertex_ids()
	var handle_positions := PackedVector3Array()
	for id in handle_ids:
		handle_positions.append(mesh.get_vertex_position(id))
	gizmo.add_handles(handle_positions, get_material("handles", gizmo), handle_ids)

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool):
	return str(handle_id)

func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool):
	var mesh := __get_brush_data(gizmo)
	return mesh.get_vertex_position(handle_id)

var _original_position

func _commit_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool, restore: Variant, cancel: bool):
	var mesh := __get_brush_data(gizmo)
	if cancel:
		mesh.set_vertex_position(id, restore)
	_original_position = null

func _set_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool, camera: Camera3D, point: Vector2):
	var mesh := __get_brush_data(gizmo)
	var prev_pos := mesh.get_vertex_position(id)
	if _original_position != null:
		prev_pos = _original_position
	else:
		_original_position = prev_pos
	var depth := camera.global_position.distance_to(prev_pos)
	mesh.set_vertex_position(id, camera.project_ray_normal(point) * depth + camera.project_ray_origin(point))
	# TODO: figure out why signals aren't working :(
	__get_brush_mesh(gizmo)._on_vertex_updated(id)
