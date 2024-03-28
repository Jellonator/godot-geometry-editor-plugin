@tool
extends EditorPlugin

const BrushGizmoPlugin := preload("res://addons/gelatin_editor/brush_gizmo_plugin.gd")

var button: Button
var brush_gizmo = BrushGizmoPlugin.new()

func _enter_tree():
	add_node_3d_gizmo_plugin(brush_gizmo)
	add_custom_type("BrushMesh", "Mesh", preload("brush_mesh.gd"), preload("res://icon.svg"))
	# DELETE
	button = Button.new()
	button.text = "Delete"
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	button.pressed.connect(brush_gizmo._on_delete)
	# FILL
	button = Button.new()
	button.text = "Fill"
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	button.pressed.connect(brush_gizmo._on_fill)
	# EXTRUDE
	button = Button.new()
	button.text = "Extrude"
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
	button.pressed.connect(brush_gizmo._on_extrude)

func _exit_tree():
	if button != null:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
		button = null
	remove_node_3d_gizmo_plugin(brush_gizmo)
	remove_custom_type("BrushMesh")

func _handles(object: Object) -> bool:
	return is_instance_of(object, BrushMesh)

func _edit(object):
	if object != null:
		button.show()
	else:
		button.hide()

func _make_visible(visible):
	print("VIS ", visible)
	pass
