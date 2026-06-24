@tool
extends HBoxContainer
class_name EditorUploadedObjectListing

@export var name_label:Label
@export var publicity_label:Label
@export var creation_time_label:Label
@export var uuid_label:Label
@export var delete_button:Button

func setup_and_get_button(uuid:String, object_name:String, publicity:String, created_at:String) -> Button:
	name_label.text = object_name
	publicity_label.text = publicity
	creation_time_label.text = created_at
	uuid_label.text = uuid
	return delete_button
