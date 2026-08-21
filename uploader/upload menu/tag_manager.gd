@tool
extends PanelContainer
class_name TagManager

const TAG_BOX: PackedScene = preload("res://addons/butterflycck/uploader/upload menu/tag_box.tscn")

@export var tag_container: FlowContainer
@export var tag_entry: LineEdit


func add_tag(tag: String = "") -> void:
	var tag_box: EditorTagBox = TAG_BOX.instantiate()
	if tag.is_empty():
		tag_box.tag_string = tag_entry.text
		tag_entry.text = ""
	else:
		tag_box.tag_string = tag
	tag_container.add_child(tag_box)


func get_tags() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for child: EditorTagBox in tag_container.get_children():
		result.push_back(child.tag_string)
	return result


func clear_tags() -> void:
	for child: Node in tag_container.get_children():
		child.queue_free()
