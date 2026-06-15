@tool
extends HBoxContainer

@export var persistance_handler:EditorPersistanceHandler
@export var path_button:Button
@export var file_explorer:FileDialog

func _ready() -> void:
	persistance_handler.register_value("settings", 
			"settings", 
			"game_path",
			"")

func _on_file_dialog_file_selected(path: String) -> void:
	path_button.text = path
	persistance_handler.set_value("settings", 
			"settings", 
			"game_path",
			path)


func _on_path_button_pressed() -> void:
	file_explorer.visible = true
