@tool
extends EditorPlugin

const BrushGizmo := preload("res://addons/gelatin_editor/brush_gizmo.gd")

var button: Button
var brush_gizmo = BrushGizmo.new()

func _enter_tree():
	button = Button.new()
	button.text = "HI"
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	add_node_3d_gizmo_plugin(brush_gizmo)
	add_custom_type("BrushMesh", "Mesh", preload("brush_mesh.gd"), preload("res://icon.svg"))

func _exit_tree():
	if button != null:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
		button = null
	remove_node_3d_gizmo_plugin(brush_gizmo)
	remove_custom_type("BrushMesh")

func _handles(object: Object) -> bool:
	print(object.get_class())
	print("? ", is_instance_of(object, BrushMesh))
	return is_instance_of(object, BrushMesh)

func _edit(object):
	prints("EDIT", object)
	if object != null:
		button.show()
	else:
		button.hide()

func _make_visible(visible):
	print("VIS ", visible)
	pass
