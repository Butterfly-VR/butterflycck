@tool
extends VBoxContainer
class_name EditorObjectInspector

const WARNING_LISTING:PackedScene = preload("res://addons/butterflycck/uploader/inspector/warning.tscn")
const OBJECT_INFO_ENDPOINT:String = "/api/v0/%s/%s"

@export var api_handler:EditorAPIHandler
@export var account_handler:EditorAccountHandler
@export var preview:SubViewport
@export var preview_camera:Camera3D
@export var preview_texture:TextureRect
@export var name_text:Label
@export var uuid_text:Label
@export var created_text:Label
@export var modified_text:Label
@export var warnings_list:VBoxContainer
@export var upload_button:Button
@export var page_selector:EditorPageSelector

var previewed_object_root:Node
var preview_image:Image

func hide_self() -> void:
	modulate = Color.TRANSPARENT
	if previewed_object_root:
		previewed_object_root.queue_free()

func object_selected(original_root:BaseRoot, original_file_path:String) -> void:
	for child:Node in warnings_list.get_children():
		child.queue_free()
	
	await get_tree().physics_frame
	
	var warnings:Array[BaseRoot.Warning] = original_root.get_upload_warnings()
	warnings.sort_custom(
			func(a:BaseRoot.Warning, b:BaseRoot.Warning) -> bool:
				return a.level < b.level)
	
	upload_button.disabled = false
	
	for warning:BaseRoot.Warning in warnings:
		if warning.level == BaseRoot.Warning.WarningLevel.Error:
			upload_button.disabled = true
		
		var listing:EditorWarningListing = WARNING_LISTING.instantiate()
		
		listing.warning_level.current_tab = warning.level
		listing.heading.text = warning.header
		listing.message.text = warning.body
		
		listing.find_button.pressed.connect(func(): 
			var path:NodePath = warning.source.owner.get_path_to(warning.source)
			EditorInterface.open_scene_from_path(original_file_path)
			await get_tree().physics_frame
			await get_tree().physics_frame
			EditorInterface.set_main_screen_editor("3D")
			EditorInterface.edit_node(
					EditorInterface.get_edited_scene_root().get_node(path))
			EditorInterface.get_selection().clear()
			EditorInterface.get_selection().add_node(
					EditorInterface.get_edited_scene_root().get_node(path)))
		
		# todo: this needs to edit and save the scene file, then reload the object listings
		#if warning.has_autofix:
			#listing.fix_button.visible = true
			#listing.find_button.pressed.connect(func(): if warning.autofix.call(): listing.queue_free())
		
		warnings_list.add_child(listing)
	
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
	
	var object_type_string:String = "UNNAMED"
	match original_root.get_object_type():
		BaseRoot.ObjectType.world:
			object_type_string = "World"
		BaseRoot.ObjectType.avatar:
			object_type_string = "Avatar"
	
	root.try_assign_uuid()
	if root.attached_uuid:
		var response = await api_handler.make_request(
				HTTPClient.METHOD_GET, 
				OBJECT_INFO_ENDPOINT % [object_type_string, root.attached_uuid], 
				PackedStringArray([account_handler.get_token_header()]))
		var result = api_handler.handle_response(response[0], response[2], [200], 
				["name", "id", "created_at", "updated_at"])
		var values:Dictionary[String, Variant] = result[4]
		if result[0]:
			name_text.text = values["name"] as String
			uuid_text.text = "UUID: " + values["id"] as String
			created_text.text = "Created at: " + Time.get_date_string_from_unix_time(values["created_at"] as int)
			modified_text.text = "Last modified: " + Time.get_date_string_from_unix_time(values["updated_at"] as int)
		else:
			name_text.text = (
					root.object_name if !root.object_name.is_empty() else root.name)
			uuid_text.text = "never uploaded"
			created_text.text = ""
			modified_text.text = ""
	else:
		name_text.text = (
				root.object_name if !root.object_name.is_empty() else root.name)
		uuid_text.text = "never uploaded"
		created_text.text = ""
		modified_text.text = ""
	
	await get_tree().physics_frame
	
	modulate = Color.WHITE


func _on_upload_started() -> void:
	page_selector.go_to_upload_tab(previewed_object_root.duplicate(), preview_image)


func _on_visibility_changed() -> void:
	if !is_visible_in_tree():
		hide_self()
