@tool
extends EditorPlugin

const MAINPANEL = preload("res://addons/butterflycck/uploader/uploader.tscn")
const GIZMO_FOLDER:String = "res://addons/butterflycck/toolkit/gizmos/"

var main_panel_instance

func _enter_tree() -> void:
	add_to_group("ButterflyCCKPlugin")
	
	# setup uplaod panel
	main_panel_instance = MAINPANEL.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)
	
	# register gizmos
	if DirAccess.dir_exists_absolute(GIZMO_FOLDER):
		for file in DirAccess.get_files_at(GIZMO_FOLDER):
			if file.ends_with(".gd"):
				add_node_3d_gizmo_plugin(load(GIZMO_FOLDER + file).new())


func _exit_tree() -> void:
	main_panel_instance.queue_free()

func _has_main_screen():
	return true


func _make_visible(visible):
	main_panel_instance.visible = visible


func _get_plugin_name():
	return "Upload"


func _get_plugin_icon():
	return EditorInterface.get_editor_theme().get_icon("Node", "EditorIcons")
