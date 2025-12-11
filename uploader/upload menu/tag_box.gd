@tool
extends PanelContainer
class_name TagBox

var tag_string:String

@export var line_edit:LineEdit

func _ready() -> void:
	line_edit.text = tag_string

func _on_button_pressed() -> void:
	queue_free()

func _on_line_edit_text_changed(new_text: String) -> void:
	tag_string = new_text.to_ascii_buffer().get_string_from_ascii()
