@tool
class_name BrushDataHelper
extends RefCounted

var brush: BrushData

## Cache Data

class VertexCache:
	var edges: PackedInt32Array = PackedInt32Array()
class EdgeCache:
	var loops: PackedInt32Array = PackedInt32Array()
class LoopCache:
	var faces: PackedInt32Array = PackedInt32Array()
class SurfaceCache:
	var faces: PackedInt32Array = PackedInt32Array()

var cache_by_vertex: Array[VertexCache] = []
var cache_by_edge: Array[EdgeCache] = []
var cache_by_loop: Array[LoopCache] = []
var cache_by_surface: Array[SurfaceCache] = []

func __refresh_caches():
	cache_by_edge.clear()
	cache_by_vertex.clear()
	cache_by_loop.clear()
	cache_by_surface.clear()
	for i in range(brush.vertex_positions.size()):
		cache_by_vertex.push_back(VertexCache.new())
	for i in range(brush.edge_vertex_id1.size()):
		cache_by_edge.push_back(EdgeCache.new())
		cache_by_vertex[brush.edge_vertex_id1[i]].edges.push_back(i)
		cache_by_vertex[brush.edge_vertex_id2[i]].edges.push_back(i)
	for i in range(brush.loop_vertex_id.size()):
		cache_by_loop.push_back(LoopCache.new())
		cache_by_edge[brush.loop_edge_id[i]].loops.push_back(i)
	for i in range(brush.surface_materials.size()):
		cache_by_surface.push_back(SurfaceCache.new())
	for i in range(brush.face_loop_start_id.size()):
		for j in range(brush.face_loop_count[i]):
			cache_by_loop[brush.face_loop_start_id[i] + j].faces.push_back(i)
		cache_by_surface[brush.face_surface_id[i]].faces.push_back(i)

func _init(p_brush: BrushData):
	brush = p_brush
	__refresh_caches()

## API

func get_vertex_position(v: int) -> Vector3:
	return brush.vertex_positions[v]

func set_vertex_position(v: int, pos: Vector3):
	brush.vertex_positions[v] = pos
	brush.vertex_updated.emit(v)

func make_vertex(point: Vector3) -> int:
	var index := brush.vertex_positions.size()
	var v := brush.vertex_positions
	v.push_back(point)
	brush.vertex_positions = v
	cache_by_vertex.push_back(VertexCache.new())
	return index

func make_edge(v1: int, v2: int) -> int:
	var index := brush.edge_vertex_id1.size()
	var edgevert1 := brush.edge_vertex_id1
	var edgevert2 := brush.edge_vertex_id2
	edgevert1.push_back(v1)
	edgevert2.push_back(v2)
	brush.edge_vertex_id1 = edgevert1
	brush.edge_vertex_id2 = edgevert2
	cache_by_edge.push_back(EdgeCache.new())
	cache_by_vertex[v1].edges.push_back(index)
	cache_by_vertex[v2].edges.push_back(index)
	return index

func get_edge_between(v1: int, v2: int) -> int:
	for e in cache_by_vertex[v1].edges:
		if brush.edge_vertex_id1[e] == v2 or brush.edge_vertex_id2[e] == v2:
			return e
	return -1

func __make_loop(vertex: int, edge: int) -> int:
	var index := brush.loop_edge_id.size()
	var loopedgeid := brush.loop_edge_id
	var loopvertid := brush.loop_vertex_id
	loopedgeid.push_back(edge)
	loopvertid.push_back(vertex)
	brush.loop_vertex_id = loopvertid
	brush.loop_edge_id = loopedgeid
	cache_by_loop.push_back(LoopCache.new())
	cache_by_edge[edge].loops.push_back(index)
	return index

func __make_face(surface: int, loop_start: int, loop_count: int) -> int:
	var index := brush.face_surface_id.size()
	var facesurfid := brush.face_surface_id
	var faceloopstart := brush.face_loop_start_id
	var faceloopcount := brush.face_loop_count
	facesurfid.push_back(surface)
	faceloopstart.push_back(loop_start)
	faceloopcount.push_back(loop_count)
	brush.face_surface_id = facesurfid
	brush.face_loop_start_id = faceloopstart
	brush.face_loop_count = faceloopcount
	cache_by_surface[surface].faces.push_back(index)
	for i in range(loop_count):
		cache_by_loop[loop_start + i].faces.push_back(index)
	return index

func make_face(surface: int, vertices: PackedInt32Array) -> int:
	if vertices.size() < 3:
		return -1
	var prev_id := vertices[vertices.size() - 1]
	var loop_start_id := brush.loop_vertex_id.size()
	for cur_id in vertices:
		var edge := get_edge_between(prev_id, cur_id)
		if edge < 0:
			edge = make_edge(prev_id, cur_id)
		__make_loop(prev_id, edge)
		prev_id = cur_id
	return __make_face(surface, loop_start_id, vertices.size())

## Editor functions

func get_vertex_ids() -> PackedInt32Array:
	var ret := PackedInt32Array()
	for i in range(brush.vertex_positions.size()):
		ret.push_back(i)
	return ret

func get_gizmo_lines() -> PackedVector3Array:
	var ret := PackedVector3Array()
	for i in range(brush.edge_vertex_id1.size()):
		ret.push_back(brush.vertex_positions[brush.edge_vertex_id1[i]])
		ret.push_back(brush.vertex_positions[brush.edge_vertex_id2[i]])
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
