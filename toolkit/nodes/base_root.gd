@tool
extends Node
class_name BaseRoot

@export var string_uuid:String

@export_tool_button("assign UUID", "Callable") var assign_button = assign_uuid

var attached_uuid:UUID

func assign_uuid() -> void:
	var new_uuid = UUID.from_String(string_uuid)
	if new_uuid != UUID.new():
		attached_uuid = new_uuid
	else:
		attached_uuid = null

func on_upload() -> void:
	if !attached_uuid:
		attached_uuid = UUID.new(true)

func check_valid() -> bool:
	return true

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

func _get_configuration_warnings():
	var warnings:Array[String] = []
	
	if get_children().size() == 0:
		warnings.append("object root requires a child")
	if get_children().size() > 1:
		warnings.append("multiple children are not allowed on an object root, 
				children beyond the first child will be ignored")
	
	return warnings
