@tool
extends HBoxContainer

@export var token_input:LineEdit
@export var persistance_handler:PersistanceHandler

var description:String = "Required to upload content, you can get a token from the game client or server.
		If no token is set here you will be asked to log in the first time you upload something."
		

func _ready() -> void:
	token_input.text = persistance_handler.register_value("settings", 
			"settings", 
			"token", 
			UUID.new().to_string())

func _on_line_edit_text_submitted(new_text: String) -> void:
	if UUID.from_String(new_text) != UUID.new():
		persistance_handler.set_value("settings", 
			"settings", 
			"token", 
			new_text)
