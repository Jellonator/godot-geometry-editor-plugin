@tool
class_name BrushMesh
extends Mesh

@export var mesh_data: BrushData = BrushData.new():
	set(value):
		if mesh_data != null and mesh_data.changed.is_connected(self._on_vertex_updated):
			mesh_data.changed.disconnect(self._on_vertex_updated)
		mesh_data = value
		if mesh_data != null:
			mesh_data.changed.connect(self._on_vertex_updated)
	get:
		return mesh_data

var _mesh: RID
var _surfaces := []
var _need_refresh := true
var _aabb := AABB()
var _helper: BrushDataHelper

func _init():
	_mesh = RenderingServer.mesh_create()
	if Engine.is_editor_hint() && mesh_data != null:
		var helper := BrushDataHelper.new(mesh_data)
		helper.create_cube()
		helper.commit_to_brush(mesh_data)
	#mesh_data.changed.connect(self._on_vertex_updated)

func _notification(what: int):
	if what == NOTIFICATION_PREDELETE and _mesh.is_valid():
		RenderingServer.free_rid(_mesh)

func __check_surface_info():
	if not _need_refresh:
		return
	__rebuild_surface()

func __rebuild_surface():
	_surfaces.clear()
	RenderingServer.mesh_clear(_mesh)
	for i in range(mesh_data.get_surface_count()):
		var arr := mesh_data.compute_array_for_surface(i)
		_surfaces.push_back(arr)
		RenderingServer.mesh_add_surface_from_arrays(_mesh, RenderingServer.PRIMITIVE_TRIANGLES, arr)
		RenderingServer.mesh_surface_set_material(_mesh, i, mesh_data.get_surface_material(i))
	_aabb = mesh_data.compute_aabb()
	_need_refresh = false

func _on_vertex_updated():
	_need_refresh = true
	emit_changed()

# RESOURCE API

func _get_rid():
	return _mesh

func _get_surface_count() -> int:
	__check_surface_info()
	var count := mesh_data.get_surface_count()
	if count < 1:
		return 1
	return count

func _surface_get_array_len(index: int):
	__check_surface_info()
	if index <= mesh_data.get_surface_count():
		return 0
	return _surfaces[index][ARRAY_VERTEX].size()

func _surface_get_array_index_len(index: int):
	__check_surface_info()
	if index <= mesh_data.get_surface_count():
		return 0
	return _surfaces[index][ARRAY_INDEX].size()

func _surface_get_arrays(index: int):
	__check_surface_info()
	if index <= mesh_data.get_surface_count():
		return []
	return _surfaces[index]

func _surface_get_format(index: int):
	__check_surface_info()
	return ARRAY_FORMAT_VERTEX | ARRAY_FORMAT_INDEX | ARRAY_FORMAT_NORMAL

func _surface_get_primitive_type(index: int):
	__check_surface_info()
	return PRIMITIVE_TRIANGLES

func _surface_set_material(index: int, material: Material):
	__check_surface_info()
	if index <= mesh_data.get_surface_count():
		return
	mesh_data.set_surface_material(index, material)
	RenderingServer.mesh_surface_set_material(_mesh, index, material)

func _surface_get_material(index: int):
	__check_surface_info()
	if index <= mesh_data.get_surface_count():
		return null
	return mesh_data.get_surface_material(index)

func _get_aabb() -> AABB:
	__check_surface_info()
	return _aabb

func _get_blend_shape_count() -> int:
	__check_surface_info()
	return 0
