@tool
extends EditorNode3DGizmoPlugin

var active_gizmo: EditorNode3DGizmo

func _get_gizmo_name():
	return "Brush Editor"

func _init():
	create_material("edge_selected", Color(1, 0.5, 0))
	create_material("edge_unselected", Color(0.2, 0.2, 0.2, 0.5))
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
		if selected_ids.has(id):
			selected_positions.append(brush.get_vertex(id).position)
		else:
			unselected_ids.append(id)
			unselected_positions.append(brush.get_vertex(id).position)
	if unselected_ids.size() > 0:
		gizmo.add_handles(unselected_positions, get_material("handle_unselected", gizmo), unselected_ids, true, true)
	if selected_ids.size() > 0:
		gizmo.add_handles(selected_positions, get_material("handle_selected", gizmo), selected_ids, true, false)
	var selected_edges := PackedVector3Array()
	var unselected_edges := PackedVector3Array()
	for e in brush.edges.values():
		if selected_ids.has(e.vertex1) and selected_ids.has(e.vertex2):
			selected_edges.push_back(brush.vertices[e.vertex1].position)
			selected_edges.push_back(brush.vertices[e.vertex2].position)
		else:
			unselected_edges.push_back(brush.vertices[e.vertex1].position)
			unselected_edges.push_back(brush.vertices[e.vertex2].position)
	if selected_edges.size() > 0:
		gizmo.add_lines(selected_edges, get_material("edge_selected", gizmo), true)
	if unselected_edges.size() > 0:
		gizmo.add_lines(unselected_edges, get_material("edge_unselected", gizmo), true)

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
	if ids.size() == 2:
		__get_brush_data_helper(active_gizmo).make_edge(ids[0], ids[1])
		__commit_to_brush(active_gizmo)
	elif ids.size() > 2:
		__get_brush_data_helper(active_gizmo).make_face(0, ids)
		__commit_to_brush(active_gizmo)

func _on_extrude():
	if active_gizmo == null:
		return
	var helper := __get_brush_data_helper(active_gizmo)
	var selected_vert_ids := active_gizmo.get_subgizmo_selection()
	var selected_face_ids: Array[int] = []
	# Get selected faces (all vertices of face are selected)
	for fid in helper.faces:
		var face := helper.get_face(fid)
		var c_sel := 0
		var c_unsel := 0
		for lid in range(face.loop_first, face.loop_first + face.loop_count):
			var loop := helper.get_loop(lid)
			if selected_vert_ids.has(loop.vertex):
				c_sel += 1
			else:
				c_unsel += 1
		if c_sel > 0 and c_unsel == 0:
			selected_face_ids.push_back(fid)
	# Duplicate shared vertices (aka, vertices which have at least one face that isn't selected)
	var duplicated_vert_id_map := {}
	for vid in selected_vert_ids:
		#var connected_vertex_ids := helper.get_connected_vertices(vid)
		var connected_face_ids := helper.get_vertex(vid).get_linked_faces(helper)
		prints("CONN", vid, connected_face_ids, connected_face_ids.map(func(i: int): return not selected_face_ids.has(i)))
		if connected_face_ids.is_empty() or connected_face_ids.any(func(i: int): return not selected_face_ids.has(i)):
			# TODO: move to separate duplicate method
			var newvid := helper.make_vertex(helper.get_vertex(vid).position)
			duplicated_vert_id_map[vid] = newvid
	# Duplicate edges between original vertices
	# That is, we want to duplicate the 'ring' around selected faces
	var duplicated_edge_id_map := {}
	var edge_postprocess_list: Array[int] = []
	for edge_id in helper.edges.keys():
		var edge := helper.get_edge(edge_id)
		if selected_vert_ids.has(edge.vertex1) and selected_vert_ids.has(edge.vertex2):
			# only duplicate if edge is linked to non-selected face (or isn't linked to any faces)
			# Otherwise, update edge
			var has_unselected_linked_face := false
			var has_face := false
			for loop in edge.loop_cache:
				for face in helper.get_loop(loop).face_cache:
					has_face = true
					if not selected_face_ids.has(face):
						has_unselected_linked_face = true
			if duplicated_vert_id_map.has(edge.vertex1) and duplicated_vert_id_map.has(edge.vertex2) and(not has_face or has_unselected_linked_face):
				duplicated_edge_id_map[edge_id] = helper.make_edge(duplicated_vert_id_map[edge.vertex1], duplicated_vert_id_map[edge.vertex2])
			else:
				edge_postprocess_list.push_back(edge_id)
	for edge_id in edge_postprocess_list:
		var edge := helper.get_edge(edge_id)
		if duplicated_vert_id_map.has(edge.vertex1):
			edge.update_vertex1(helper, duplicated_vert_id_map[edge.vertex1])
		if duplicated_vert_id_map.has(edge.vertex2):
			edge.update_vertex2(helper, duplicated_vert_id_map[edge.vertex2])
	# Create edges between original and duplicated vertices
	for vid1 in duplicated_vert_id_map:
		var vid2: int = duplicated_vert_id_map[vid1]
		helper.make_edge(vid1, vid2)
	# Update selected faces to point to new vertices.
	for fid in selected_face_ids:
		var face := helper.get_face(fid)
		for lid in range(face.loop_first, face.loop_first + face.loop_count):
			var loop := helper.get_loop(lid)
			if duplicated_vert_id_map.has(loop.vertex):
				var eid := loop.edge
				if duplicated_edge_id_map.has(eid):
					eid = duplicated_edge_id_map[eid]
				loop.replace(helper, duplicated_vert_id_map[loop.vertex], eid)
	# Create faces (quads) between original and duplicated vertices
	for edge_id in duplicated_edge_id_map:
		var edge1 := helper.get_edge(edge_id)
		var edge2 := helper.get_edge(duplicated_edge_id_map[edge_id])
		var vx := PackedInt32Array([edge1.vertex1, edge2.vertex1, edge2.vertex2, edge1.vertex2])
		# match existing loops, if possible
		if edge1.loop_cache.size() == 1:
			vx = helper.get_loop(edge1.loop_cache.keys()[0]).get_matching_vertex_order(helper, vx)
		elif edge2.loop_cache.size() == 1:
			vx = helper.get_loop(edge1.loop_cache.keys()[0]).get_matching_vertex_order(helper, vx)
		helper.make_face(0, vx)
	# Select new IDs
	# TODO: update when proper set_subgizmo_selection gets merged
	print("DUP ", duplicated_vert_id_map)
	print("SEL ", selected_vert_ids)
	
	# just swap vertices for now to fix selection IDs
	for i in duplicated_vert_id_map:
		helper.swap_vertex_ids(i, duplicated_vert_id_map[i])
	
	__commit_to_brush(active_gizmo)
	#var sel = PackedInt32Array()
	#for i in selected_vert_ids:
		#if duplicated_vert_id_map.has(i):
			#sel.push_back(duplicated_vert_id_map[i])
		#else:
			#sel.push_back(i)
	#if sel.size() > 0:
		#active_gizmo.get_node_3d().set_subgizmo_selection(active_gizmo, sel[0], Transform3D())

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
