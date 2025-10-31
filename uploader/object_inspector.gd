@tool
extends VBoxContainer
class_name ObjectInspector

@export var preview:SubViewport
@export var name_text:Label
@export var uuid_text:Label
@export var warnings_list:VBoxContainer
@export var upload_button:Button

func object_selected(root:BaseRoot) -> void:
	pass


func _on_upload_started() -> void:
	pass # Replace with function body.
