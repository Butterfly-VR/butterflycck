@tool
extends EditorPlugin

const MAINPANEL = preload("res://addons/butterflycck/uploader/uploader.tscn")

var main_panel_instance

func _enter_tree() -> void:
	main_panel_instance = MAINPANEL.instantiate()
	EditorInterface.get_editor_main_screen().add_child(main_panel_instance)
	_make_visible(false)


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
