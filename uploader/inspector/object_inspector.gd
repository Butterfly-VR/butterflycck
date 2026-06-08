@tool
extends VBoxContainer
class_name ObjectInspector

const WARNING_LISTING:PackedScene = preload("res://addons/butterflycck/uploader/inspector/warning.tscn")

@export var preview:SubViewport
@export var preview_camera:Camera3D
@export var preview_texture:TextureRect
@export var name_text:Label
@export var uuid_text:Label
@export var warnings_list:VBoxContainer
@export var upload_button:Button
@export var page_selector:PageSelector

var previewed_object_root:Node
var preview_image:Image

func hide_self() -> void:
	modulate = Color.TRANSPARENT
	if previewed_object_root:
		previewed_object_root.queue_free()

func object_selected(original_root:BaseRoot) -> void:
	var root:BaseRoot = original_root.duplicate()
	if previewed_object_root:
		previewed_object_root.queue_free()
	
	await get_tree().physics_frame
	
	if root.get_parent():
		root.get_parent().remove_child(root)
	if root.owner:
		root.owner = null
	
	preview.add_child(root)
	previewed_object_root = root
	
	preview_camera.transform = root.get_preview_camera_transform()
	preview.render_target_update_mode = SubViewport.UPDATE_ONCE
	preview_texture.texture = null
	await RenderingServer.frame_post_draw
	preview_image = preview.get_texture().get_image()
	preview_texture.texture = preview.get_texture()
	
	name_text.text = (
			root.object_name if !root.object_name.is_empty() else root.name)
	uuid_text.text = (
			root.attached_uuid.to_string() if root.attached_uuid else "never uploaded")
	
	for child:Node in warnings_list.get_children():
		child.queue_free()
	
	await get_tree().physics_frame
	
	var warnings:Array[BaseRoot.Warning] = root.get_upload_warnings()
	
	upload_button.disabled = false
	
	for warning:BaseRoot.Warning in warnings:
		if warning.level == BaseRoot.Warning.WarningLevel.Error:
			upload_button.disabled = true
		
		var listing:WarningListing = WARNING_LISTING.instantiate()
		
		listing.warning_level.current_tab = warning.level
		listing.heading.text = warning.header
		listing.message.text = warning.body
		
		# todo: this dosent do what we want, 
		# we need to open the scene and select the node in there instead
		# would require passing the scene path and node path into the Warning
		#listing.find_button.pressed.connect(func(): EditorInterface.edit_node(warning.source))
		
		if warning.has_autofix:
			listing.fix_button.visible = true
			# autofix function should return a bool to indicate success
			# todo: this should probably just refresh the entire object inspector on success
			listing.find_button.pressed.connect(func(): if warning.autofix.call(): listing.queue_free())
		
		warnings_list.add_child(listing)
	
	await get_tree().physics_frame
	
	modulate = Color.WHITE


func _on_upload_started() -> void:
	page_selector.go_to_upload_tab(previewed_object_root.duplicate(), preview_image)


func _on_visibility_changed() -> void:
	if !is_visible_in_tree():
		hide_self()
