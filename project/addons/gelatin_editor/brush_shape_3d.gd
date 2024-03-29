@tool
class_name BrushShape3D
extends ConcavePolygonShape3D

@export var mesh_data: BrushData = BrushData.new():
	set(value):
		if mesh_data != null and mesh_data.changed.is_connected(self._update_faces_and_emit):
			mesh_data.changed.disconnect(self._update_faces_and_emit)
		mesh_data = value
		if mesh_data != null:
			mesh_data.changed.connect(self._update_faces_and_emit)
		_update_faces_and_emit()
	get:
		return mesh_data

func _init():
	_update_faces()

func _update_faces_and_emit():
	_update_faces()
	emit_changed()

func _update_faces():
	if mesh_data == null:
		set_faces(PackedVector3Array())
	else:
		set_faces(mesh_data.create_triangle_mesh())
