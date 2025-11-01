@tool
extends VBoxContainer

const OBJECT_LISTING:PackedScene = preload("res://addons/butterflycck/uploader/object_listing.tscn")

@export var object_list:VBoxContainer
@export var inspector:ObjectInspector

var selected_type:int = 0

func on_target_type_changed(selected_type:int) -> void:
	inspector.object_selected(null)
	
	for child in object_list.get_children():
		child.queue_free()
	await get_tree().physics_frame
	
	self.selected_type = selected_type
	match selected_type:
		0:
			find_objects(AvatarRoot)
		1:
			find_objects(WorldRoot)
		_:
			push_error("unhandled root search type")

# searches the file system for scenes, then searches those scenes for objects
func find_objects(type:GDScript) -> void:
	var found_scenes:Array[FileAccess]
	
	# file system tree traversal
	# todo: make not recursive
	var root_dir:String = "res://"
	var scene_files:Array[String] = find_objects_recursive(type, root_dir)
	
	for file:String in scene_files:
		var scene:Node = (load(file) as PackedScene).instantiate()
		find_objects_in_scene(type, scene)

func find_objects_recursive(type:GDScript, path:String) -> Array[String]:
	var files:Array[String] = []
	for dir:String in DirAccess.get_directories_at(path):
		files.append_array(find_objects_recursive(type, path + "/" + dir))
	for file:String in DirAccess.get_files_at(path):
		if file.ends_with(".tscn"):
			files.push_back(path + "/" + file)
	return files

# called by find_objects, searches for objects in a scene
# todo: should probably hoist listing creation out to the outer function
func find_objects_in_scene(type:GDScript, scene_root:Node) -> void:
	var objects:Array[BaseRoot]
	SceneTreeHelper.call_children_recursive(scene_root, check_node_is_object.bind(objects, type), true)
	# list the objects we found in the ui
	for object:BaseRoot in objects:
		var listing = OBJECT_LISTING.instantiate()
		
		listing.object_name.text = (
				object.object_name if !object.object_name.is_empty() else object.name)
		listing.uuid.text = (
				object.attached_uuid.to_string() if object.attached_uuid else "never uploaded")
		
		listing.select_button.pressed.connect(inspector.object_selected.bind(object))
		
		object_list.add_child(listing)

# bindings are applied in reverse order so we need the second binding argument to be first
func check_node_is_object(node:Node, objects:Array[BaseRoot], type:GDScript) -> bool:
	if is_instance_of(node, type):
		# since nesting isnt allowed we skip this branch and add it to the list
		objects.push_back(node)
		return false
	return true

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		on_target_type_changed(selected_type)


func _on_avatars_pressed(extra_arg_0: int) -> void:
	pass # Replace with function body.
