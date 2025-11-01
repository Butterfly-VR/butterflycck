@tool
extends VBoxContainer
class_name ObjectInspector

@export var preview:SubViewport
@export var preview_camera:Camera3D
@export var name_text:Label
@export var uuid_text:Label
@export var warnings_list:VBoxContainer
@export var upload_button:Button

var previewed_object_root:Node

func object_selected(root:BaseRoot) -> void:
	if previewed_object_root:
		previewed_object_root.queue_free()
	
	await get_tree().physics_frame
	
	if root == null:
		modulate = Color.TRANSPARENT
		return
	
	if root.get_parent():
		root.get_parent().remove_child(root)
	if root.owner:
		root.owner = null
	
	preview.add_child(root)
	previewed_object_root = root
	
	preview_camera.transform = root.get_preview_camera_transform()
	preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	
	await get_tree().physics_frame
	
	modulate = Color.WHITE


func _on_upload_started() -> void:
	pass # Replace with function body.
