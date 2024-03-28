@tool
class_name BrushDataHelper
extends RefCounted

## Cache Data

class VertexData:
	var id: int = -1
	var position: Vector3 = Vector3.ZERO
	var edge_cache := {}
	func _init(p_id: int, p: Vector3):
		id = p_id
		position = p
	func get_linked_faces(data: BrushDataHelper) -> Array[int]:
		var ret: Array[int] = []
		for faceid in data.faces:
			var face := data.get_face(faceid)
			for i in range(face.loop_first, face.loop_first + face.loop_count):
				if data.get_loop(i).vertex == id:
					ret.push_back(faceid)
					break
		return ret
class EdgeData:
	var id: int = -1
	var vertex1: int = -1
	var vertex2: int = -1
	var loop_cache := {}
	func _init(p_id: int, v1: int, v2: int):
		id = p_id
		vertex1 = v1
		vertex2 = v2
	func update_vertex1(data: BrushDataHelper, new_vert_id: int):
		for loopid in loop_cache:
			var loop := data.get_loop(loopid)
			if loop.vertex == vertex1:
				loop.vertex = new_vert_id
		data.get_vertex(vertex1).edge_cache.erase(id)
		data.get_vertex(new_vert_id).edge_cache[id] = id
		vertex1 = new_vert_id
	func update_vertex2(data: BrushDataHelper, new_vert_id: int):
		for loopid in loop_cache:
			var loop := data.get_loop(loopid)
			if loop.vertex == vertex2:
				loop.vertex = new_vert_id
		data.get_vertex(vertex2).edge_cache.erase(id)
		data.get_vertex(new_vert_id).edge_cache[id] = id
		vertex2 = new_vert_id

class LoopData:
	var id: int = -1
	var face_cache := {}
	var vertex: int = -1
	var edge: int = -1
	func _init(p_id: int, v: int, e: int):
		id = p_id
		vertex = v
		edge = e
	func get_start_vertex_id() -> int:
		return vertex
	func get_end_vertex_id(edges: Dictionary) -> int:
		if vertex == edges[edge].vertex1:
			return edges[edge].vertex2
		else:
			return edges[edge].vertex1
	func replace(data: BrushDataHelper, new_vert: int, new_edge: int):
		data.get_edge(edge).loop_cache.erase(id)
		edge = new_edge
		vertex = new_vert
		data.get_edge(edge).loop_cache[id] = id
	func get_matching_vertex_order(data: BrushDataHelper, vertices: PackedInt32Array) -> PackedInt32Array:
		var i := vertices.find(vertex)
		if i == -1:
			return vertices
		var next_i := (i + 1) % vertices.size();
		if vertices[next_i] == get_end_vertex_id(data.edges):
			vertices.reverse()
		return vertices

class SurfaceData:
	var id: int = -1
	var face_cache := {}
	var material: Material
	func _init(p_id: int, m: Material):
		id = p_id
		material = m

class FaceData:
	var id: int = -1
	var surface: int = 0
	var loop_first: int = -1
	var loop_count: int = 0
	func _init(p_id: int, first: int, count: int, surf: int = 0):
		id = p_id
		surface = surf
		loop_first = first
		loop_count = count

var vertices: Dictionary = {}
var edges: Dictionary = {}
var loops: Dictionary = {}
var surfaces: Dictionary = {}
var faces: Dictionary = {}

var _next_vert_id := 0
var _next_edge_id := 0
var _next_loop_id := 0
var _next_surface_id := 0
var _next_face_id := 0

func _init(brush: BrushData = null):
	init_from_brush(brush)

func init_from_brush(brush: BrushData = null):
	edges.clear()
	vertices.clear()
	loops.clear()
	surfaces.clear()
	faces.clear()
	# VERTICES
	for i in range(brush.vertex_positions.size()):
		vertices[i] = VertexData.new(i, brush.vertex_positions[i])
	for i in range(brush.edge_vertex_id1.size()):
		edges[i] = EdgeData.new(i, brush.edge_vertex_id1[i], brush.edge_vertex_id2[i])
		vertices[brush.edge_vertex_id1[i]].edge_cache[i] = i
		vertices[brush.edge_vertex_id2[i]].edge_cache[i] = i
	for i in range(brush.loop_vertex_id.size()):
		loops[i] = LoopData.new(i, brush.loop_vertex_id[i], brush.loop_edge_id[i])
		edges[brush.loop_edge_id[i]].loop_cache[i] = i
	for i in range(brush.surface_materials.size()):
		surfaces[i] = SurfaceData.new(i, brush.surface_materials[i])
	for i in range(brush.face_loop_start_id.size()):
		faces[i] = FaceData.new(i, brush.face_loop_start_id[i], brush.face_loop_count[i], brush.face_surface_id[i])
		for j in range(brush.face_loop_count[i]):
			loops[brush.face_loop_start_id[i] + j].face_cache[i] = i
		surfaces[brush.face_surface_id[i]].face_cache[i] = i
	if brush == null:
		_next_vert_id = 0
		_next_edge_id = 0
		_next_loop_id = 0
		_next_surface_id = 0
		_next_face_id = 0
	else:
		_next_vert_id = brush.vertex_positions.size()
		_next_edge_id = brush.edge_vertex_id1.size()
		_next_loop_id = brush.loop_vertex_id.size()
		_next_surface_id = brush.surface_materials.size()
		_next_face_id = brush.face_surface_id.size()

func commit_to_brush(brush: BrushData):
	var vert_id_map := {}
	var edge_id_map := {}
	var loop_id_map := {}
	var face_id_map := {}
	var surface_id_map := {}
	var vertex_pos := PackedVector3Array()
	var edge_vert1 := PackedInt32Array()
	var edge_vert2 := PackedInt32Array()
	var loop_vert := PackedInt32Array()
	var loop_edge := PackedInt32Array()
	var face_start := PackedInt32Array()
	var face_count := PackedInt32Array()
	var face_surface := PackedInt32Array()
	var surf_material: Array[Material] = []
	for i in vertices:
		vert_id_map[i] = vertex_pos.size()
		vertex_pos.push_back(vertices[i].position)
	for i in edges:
		edge_id_map[i] = edge_vert1.size()
		edge_vert1.push_back(vert_id_map[edges[i].vertex1])
		edge_vert2.push_back(vert_id_map[edges[i].vertex2])
	var loop_ids := loops.keys()
	loop_ids.sort_custom(func (a: int, b: int): return a < b)
	for i in loop_ids:
		loop_id_map[i] = loop_vert.size()
		loop_vert.push_back(vert_id_map[loops[i].vertex])
		loop_edge.push_back(edge_id_map[loops[i].edge])
	for i in surfaces:
		surface_id_map[i] = surf_material.size()
		surf_material.push_back(surfaces[i].material)
	for i in faces:
		face_id_map[i] = face_start.size()
		face_start.push_back(loop_id_map[faces[i].loop_first])
		face_count.push_back(faces[i].loop_count)
		face_surface.push_back(surface_id_map[faces[i].surface])
	brush.vertex_positions = vertex_pos
	brush.edge_vertex_id1 = edge_vert1
	brush.edge_vertex_id2 = edge_vert2
	brush.loop_edge_id = loop_edge
	brush.loop_vertex_id = loop_vert
	brush.face_loop_start_id = face_start
	brush.face_loop_count = face_count
	brush.face_surface_id = face_surface
	brush.surface_materials = surf_material
	brush.emit_changed()

## API

func get_vertex(v: int) -> VertexData:
	return vertices[v]

func get_edge(e: int) -> EdgeData:
	return edges[e]

func get_loop(l: int) -> LoopData:
	return loops[l]

func get_face(f: int) -> FaceData:
	return faces[f]

func get_surface(s: int) -> SurfaceData:
	return surfaces[s]

func make_vertex(point: Vector3) -> int:
	var index := _next_vert_id
	_next_vert_id += 1
	vertices[index] = VertexData.new(index, point)
	return index

func make_edge(v1: int, v2: int) -> int:
	var index := _next_edge_id
	_next_edge_id += 1
	edges[index] = EdgeData.new(index, v1, v2)
	vertices[v1].edge_cache[index] = index
	vertices[v2].edge_cache[index] = index
	return index

func get_edge_between(v1: int, v2: int) -> int:
	for e in vertices[v1].edge_cache:
		if edges[e].vertex1 == v2 or edges[e].vertex2 == v2:
			return e
	return -1

func get_or_make_edge_between(v1: int, v2: int) -> int:
	var e := get_edge_between(v1, v2)
	if e == -1:
		return make_edge(v1, v2)
	else:
		return e

func __make_loop(vertex: int, edge: int) -> int:
	var index := _next_loop_id
	_next_loop_id += 1
	loops[index] = LoopData.new(index, vertex, edge)
	edges[edge].loop_cache[index] = index
	return index

func __make_face(surface: int, loop_start: int, loop_count: int) -> int:
	var index := _next_face_id
	_next_face_id += 1
	faces[index] = FaceData.new(index, loop_start, loop_count, surface)
	surfaces[surface].face_cache[index] = index
	for i in range(loop_count):
		loops[loop_start + i].face_cache[index] = index
	return index

func make_face(surface: int, vertices: PackedInt32Array) -> int:
	if vertices.size() < 3:
		return -1
	var prev_id := vertices[vertices.size() - 1]
	var loop_start_id := _next_loop_id
	for cur_id in vertices:
		var edge := get_edge_between(prev_id, cur_id)
		if edge < 0:
			edge = make_edge(prev_id, cur_id)
		__make_loop(prev_id, edge)
		prev_id = cur_id
	return __make_face(surface, loop_start_id, vertices.size())

func delete_face(id):
	print("DELETE FACE ", id)
	var face := get_face(id)
	for i in range(face.loop_first, face.loop_first + face.loop_count):
		print("DELETE LOOP ", i)
		var loop := get_loop(i)
		get_edge(loop.edge).loop_cache.erase(i)
		loops.erase(i)
	get_surface(face.surface).face_cache.erase(id)
	faces.erase(id)

func delete_edge(id: int):
	var edge := get_edge(id)
	var face_list := {}
	for l in edge.loop_cache:
		for f in get_loop(l).face_cache:
			face_list[f] = f
	prints("DELETE EDGE", id, face_list)
	for f in face_list:
		delete_face(f)
	get_vertex(edge.vertex1).edge_cache.erase(id)
	get_vertex(edge.vertex2).edge_cache.erase(id)
	edges.erase(id)

func delete_vertex(id: int):
	# delete related edges
	var edge_list := get_vertex(id).edge_cache.duplicate()
	prints("DELETE VERT", id, edge_list)
	for edge in edge_list:
		delete_edge(edge)
	vertices.erase(id)

func get_connected_vertices(vertex_id: int) -> Array[int]:
	var ret: Array[int] = []
	# NOTE: assuming only one edge can exist between two given vertices
	for eid in get_vertex(vertex_id).edge_cache:
		var edge := get_edge(eid)
		if edge.vertex1 == vertex_id:
			ret.push_back(edge.vertex2)
		elif edge.vertex2 == vertex_id:
			ret.push_back(edge.vertex1)
	return ret

## Editor functions

func get_vertex_ids() -> PackedInt32Array:
	var ret := PackedInt32Array()
	for i in vertices.keys():
		ret.push_back(i)
	return ret

func get_gizmo_lines() -> PackedVector3Array:
	var ret := PackedVector3Array()
	for e in edges.values():
		ret.push_back(vertices[e.vertex1].position)
		ret.push_back(vertices[e.vertex2].position)
	return ret

func create_cube():
	var s := 0.5
	var verts := [0,0,0,0,0,0,0,0,0]
	verts[0] = make_vertex(Vector3(-s, -s, -s));
	verts[1] = make_vertex(Vector3(-s, -s, +s));
	verts[2] = make_vertex(Vector3(-s, +s, -s));
	verts[3] = make_vertex(Vector3(-s, +s, +s));
	verts[4] = make_vertex(Vector3(+s, -s, -s));
	verts[5] = make_vertex(Vector3(+s, -s, +s));
	verts[6] = make_vertex(Vector3(+s, +s, -s));
	verts[7] = make_vertex(Vector3(+s, +s, +s));
	make_face(0, PackedInt32Array([verts[4], verts[5], verts[7], verts[6]]));
	make_face(0, PackedInt32Array([verts[0], verts[2], verts[3], verts[1]]));
	make_face(0, PackedInt32Array([verts[2], verts[6], verts[7], verts[3]]));
	make_face(0, PackedInt32Array([verts[0], verts[1], verts[5], verts[4]]));
	make_face(0, PackedInt32Array([verts[1], verts[3], verts[7], verts[5]]));
	make_face(0, PackedInt32Array([verts[0], verts[4], verts[6], verts[2]]));
