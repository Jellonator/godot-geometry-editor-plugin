@tool
extends EditorNode3DGizmoPlugin

var active_gizmo: EditorNode3DGizmo

func _get_gizmo_name():
	return "Brush Editor"

func _init():
	create_material("main", Color(1, 0, 0))
	create_handle_material("handle_selected", false, preload("res://addons/gelatin_editor/icon/handle_selected.svg"))
	create_handle_material("handle_unselected", false, preload("res://addons/gelatin_editor/icon/handle_unselected.svg"))

func _has_gizmo(node: Node):
	print(node)
	if not node is MeshInstance3D:
		return false
	if not node.mesh:
		return false
	return is_instance_of(node.mesh, BrushMesh)

func _create_gizmo(for_node_3d: Node3D):
	var gizmo := EditorNode3DGizmo.new()
	return gizmo

func __get_brush_mesh(gizmo: EditorNode3DGizmo) -> BrushMesh:
	if gizmo.get_node_3d() == null or not gizmo.get_node_3d() is MeshInstance3D:
		return null
	var node: MeshInstance3D = gizmo.get_node_3d()
	if node.mesh == null or not is_instance_of(node.mesh, BrushMesh):
		return null
	return node.mesh

func __get_brush_data(gizmo: EditorNode3DGizmo) -> BrushData:
	var mesh: BrushMesh = __get_brush_mesh(gizmo)
	if mesh == null:
		return null
	return mesh.mesh_data

func __get_brush_data_helper(gizmo: EditorNode3DGizmo) -> BrushDataHelper:
	var mesh: BrushMesh = __get_brush_mesh(gizmo)
	if mesh == null:
		return null
	if mesh._helper == null:
		mesh._helper = BrushDataHelper.new(mesh.mesh_data)
	return mesh._helper

func __get_vertex_global_position(gizmo: EditorNode3DGizmo, id: int) -> Vector3:
	var node: MeshInstance3D = gizmo.get_node_3d()
	var brush := __get_brush_data_helper(gizmo)
	return node.global_transform * brush.get_vertex(id).position

func _redraw(gizmo: EditorNode3DGizmo):
	active_gizmo = gizmo
	gizmo.clear()
	var brush := __get_brush_data_helper(gizmo)
	if brush == null:
		return
	var handle_ids: PackedInt32Array = brush.get_vertex_ids()
	var selected_positions := PackedVector3Array()
	var unselected_positions := PackedVector3Array()
	var selected_ids := gizmo.get_subgizmo_selection()
	var unselected_ids := PackedInt32Array()
	for id in handle_ids:
		if gizmo.get_subgizmo_selection().has(id):
			selected_positions.append(brush.get_vertex(id).position)
		else:
			unselected_ids.append(id)
			unselected_positions.append(brush.get_vertex(id).position)
	if unselected_ids.size() > 0:
		gizmo.add_handles(unselected_positions, get_material("handle_unselected", gizmo), unselected_ids, true, true)
	if selected_ids.size() > 0:
		gizmo.add_handles(selected_positions, get_material("handle_selected", gizmo), selected_ids, true, false)
	gizmo.add_lines(brush.get_gizmo_lines(), get_material("main", gizmo))

func _subgizmos_intersect_frustum(gizmo: EditorNode3DGizmo, camera: Camera3D, frustum_planes: Array[Plane]) -> PackedInt32Array:
	var ret_ids := PackedInt32Array()
	var brush := __get_brush_data_helper(gizmo)
	if brush == null:
		return ret_ids
	var handle_ids: PackedInt32Array = brush.get_vertex_ids()
	for id in handle_ids:
		var pos := __get_vertex_global_position(gizmo, id)
		var include := true
		for plane in frustum_planes:
			if plane.is_point_over(pos):
				include = false
		if include:
			ret_ids.push_back(id)
	print("FRUSTUM ", ret_ids)
	return ret_ids

func _subgizmos_intersect_ray(gizmo: EditorNode3DGizmo, camera: Camera3D, screen_pos: Vector2) -> int:
	var ret_id := -1
	var ret_distance: float = 1e10
	var brush := __get_brush_data_helper(gizmo)
	if brush == null:
		return -1
	var handle_ids: PackedInt32Array = brush.get_vertex_ids()
	for id in handle_ids:
		var pos := __get_vertex_global_position(gizmo, id)
		if camera.unproject_position(pos).distance_to(screen_pos) < 10:
			ret_id = id
	return ret_id

func _get_subgizmo_transform(gizmo: EditorNode3DGizmo, subgizmo_id: int) -> Transform3D:
	if subgizmo_id < 0:
		return gizmo.get_node_3d().global_transform
	var brush := __get_brush_data_helper(gizmo)
	if brush == null:
		return Transform3D()
	return Transform3D(Basis(), brush.get_vertex(subgizmo_id).position)

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool):
	return str(handle_id)

func _set_subgizmo_transform(gizmo: EditorNode3DGizmo, subgizmo_id: int, transform: Transform3D):
	var brush := __get_brush_data_helper(gizmo)
	if brush == null:
		return
	brush.get_vertex(subgizmo_id).position = transform.origin
	__commit_to_brush(gizmo)

func __commit_to_brush(gizmo: EditorNode3DGizmo):
	__get_brush_data_helper(gizmo).commit_to_brush(__get_brush_data(gizmo))

func _commit_subgizmos(gizmo: EditorNode3DGizmo, ids: PackedInt32Array, restores: Array[Transform3D], cancel: bool):
	if cancel:
		for i in range(ids.size()):
			_set_subgizmo_transform(gizmo, ids[i], restores[i])
	else:
		pass # TODO

func _on_delete():
	if active_gizmo == null:
		return
	for id in active_gizmo.get_subgizmo_selection():
		__get_brush_data_helper(active_gizmo).delete_vertex(id)
	active_gizmo.get_node_3d().clear_subgizmo_selection()
	__commit_to_brush(active_gizmo)

func _on_fill():
	if active_gizmo == null:
		return
	var ids := active_gizmo.get_subgizmo_selection()
	if ids.size() < 3:
		return
	__get_brush_data_helper(active_gizmo).make_face(0, ids)
	__commit_to_brush(active_gizmo)

#func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool):
	#var mesh := __get_brush_data(gizmo)
	#return mesh.get_vertex_position(handle_id)
#
#var _original_position
#
#func _commit_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool, restore: Variant, cancel: bool):
	#var mesh := __get_brush_data(gizmo)
	#if cancel:
		#mesh.set_vertex_position(id, restore)
	#_original_position = null
#
#func _set_handle(gizmo: EditorNode3DGizmo, id: int, secondary: bool, camera: Camera3D, point: Vector2):
	#var mesh := __get_brush_data(gizmo)
	#var prev_pos := mesh.get_vertex_position(id)
	#if _original_position != null:
		#prev_pos = _original_position
	#else:
		#_original_position = prev_pos
	#var depth := camera.global_position.distance_to(prev_pos)
	#mesh.set_vertex_position(id, camera.project_ray_normal(point) * depth + camera.project_ray_origin(point))
