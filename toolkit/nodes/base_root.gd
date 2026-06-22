@tool
@abstract
extends Node
class_name BaseRoot

# creates an error if any types or subtypes in this list are in the object
var blacklisted_types:Array = [Window, EditorPlugin, HTTPRequest, MultiplayerSpawner, MultiplayerSynchronizer, StatusIndicator]

@export var object_name:String
@export var _uuid:String

@export_tool_button("assign UUID", "Callable") var assign_button = assign_uuid

var attached_uuid:UUID

enum ObjectType{
	world,
	avatar,
	prop,
	component
}

# warning to be displayed in the upload panel
# Error level warnings prevent uploading
class Warning:
	enum WarningLevel{
		Info,
		Warning,
		Error
	}
	
	var level:WarningLevel
	var header:String
	var body:String
	var source:Node
	var has_autofix:bool = false
	var autofix:Callable
	
	func _init(level:WarningLevel, header:String, body:String, source:Node, 
			has_autofix:bool, autofix:Callable = Callable()) -> void:
		self.level = level
		self.header = header
		self.body = body
		self.source = source
		if has_autofix:
			self.has_autofix = true
			self.autofix = autofix

@abstract func get_object_type() -> ObjectType

func assign_uuid() -> void:
	var new_uuid:UUID
	if _uuid.is_empty():
		new_uuid = UUID.new(true)
	else:
		new_uuid = UUID.from_String(_uuid)
		if !new_uuid:
			new_uuid = UUID.new(true)
	_uuid = new_uuid.to_string()
	attached_uuid = new_uuid

# setup self and call prep on children, then return children
func on_pre_upload() -> bool:
	var success:bool = true
	EditorSceneTreeHelper.call_children_recursive(
			self.get_child(0), 
			func(x:Node) -> bool: 
				if x is CCKMarker:
					if !(x as CCKMarker).prep_for_upload():
						success = false
				return true)
	
	
	if !attached_uuid:
		attached_uuid = UUID.new(true)
	
	return success

# bindings are applied in reverse order so we need the second binding argument to be first
func get_child_warnings(node:Node, warnings:Array[Warning]) -> bool:
	if node.get_groups().any(func(group:StringName) -> bool:
		return !(group.begins_with("_") or group.begins_with("cck_"))):
			warnings.push_back(Warning.new(Warning.WarningLevel.Error, 
				"invalid group", 
				"group names used in an uploaded object must start with 'cck_' to prevent conflicts", 
				node, false))
	if blacklisted_types.any(
			func(blacklist_type) -> bool: return is_instance_of(node, blacklist_type)):
		warnings.push_back(Warning.new(Warning.WarningLevel.Error, 
				"Blacklisted Type", 
				"this object contains a node of type %s, which is not allowed" % (
				node.get_class()), 
				node, true, 
				func(): 
					node.queue_free() 
					return true))
	if node is CCKMarker:
		warnings.append_array((node as CCKMarker).get_uploader_warnings())
	elif node.get_script() != null:
		warnings.push_back(Warning.new(Warning.WarningLevel.Error, 
				"Node with script", 
				"Scripts are currently not allowed on uploaded objects, sandboxed scripting will be implemented in a future alpha build", 
				node, true, 
				func(): 
					node.queue_free() 
					return true))
	return true

func get_upload_warnings() -> Array[Warning]:
	var warnings:Array[Warning] = []
	if get_children().size() > 0:
		EditorSceneTreeHelper.call_children_recursive(get_child(0), get_child_warnings.bind(warnings))
	
	# get config warnings from self
	for warning in _get_configuration_warnings():
		warnings.push_back(Warning.new(
				Warning.WarningLevel.Warning, 
				"Root Config Error", 
				warning, 
				self, false))
	return warnings

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

# AABB is passed by value (technically CoW but whatever) but we need it passed by ref
# only way i know to do this is to wrap it in a class
class AABBRef:
	var is_init:bool = false
	var aabb:AABB

# bindings are applied in reverse order so we need the second binding argument to be first
func get_combined_aabb(node:Node, buffer:AABBRef) -> bool:
	if node is VisualInstance3D:
		var aabb:AABB = (node as VisualInstance3D).get_aabb()
		aabb.position = (node as Node3D).to_global(aabb.position)
		if buffer.is_init:
			buffer.aabb = buffer.aabb.merge(aabb)
		else:
			buffer.aabb = aabb
			buffer.is_init = true
	
	return true

# default camera position calculation
# positions the camera such that it sees the entire object based on its bounding box
func get_preview_camera_transform() -> Transform3D:
	var camera:Camera3D = Camera3D.new()
	add_child(camera)
	var aabb_ref:AABBRef = AABBRef.new()
	EditorSceneTreeHelper.call_children_recursive(self, get_combined_aabb.bind(aabb_ref))
	var aabb:AABB = aabb_ref.aabb
	var pos:Vector3 = aabb.position + (aabb.size / 2)
	
	var candidate1:float = (
			(aabb.size.x / 2) / absf(tan(deg_to_rad(camera.get_camera_projection().get_fov() / 2)))) * 1.1
	var fovy:float = Projection.get_fovy(
			camera.get_camera_projection().get_fov() / 2, 
			1 / camera.get_camera_projection().get_aspect())
	var candidate2:float = ((aabb.size.y / 2) / absf(tan(deg_to_rad(fovy / 2)))) * 1.1
	
	pos.z -= maxf(candidate1, candidate2)
	camera.queue_free()
	return Transform3D(Basis.IDENTITY.rotated(Vector3.UP, deg_to_rad(180)), pos)

func _get_configuration_warnings():
	var warnings:Array[String] = []
	
	if get_children().size() == 0:
		warnings.append("object root requires a child")
	if get_children().size() > 1:
		warnings.append("multiple children are not allowed on an object root, children beyond the first child will be ignored")
	
	return warnings
