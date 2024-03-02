@tool
extends EditorPlugin

var button: Button

func _enter_tree():
	button = Button.new()
	button.text = "HI"
	add_control_to_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)

func _exit_tree():
	if button != null:
		remove_control_from_container(EditorPlugin.CONTAINER_SPATIAL_EDITOR_MENU, button)
		button = null

func _handles(object: Object) -> bool:
	print("? ", object.is_class("BrushMesh"))
	return object.is_class("BrushMesh")

func _edit(object):
	prints("EDIT", object)
	if object != null:
		button.show()
	else:
		button.hide()

func _make_visible(visible):
	print("VIS ", visible)
	pass
