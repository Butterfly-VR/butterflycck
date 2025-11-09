@tool
@abstract
extends Node
class_name BaseRoot

# creates an error if any types or subtypes in this list are in the object
const blacklisted_types:Array[GDScript] = []

@export var object_name:String
@export var uuid:String

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
	
	func _init(level:WarningLevel, header:String, body:String, source:Node) -> void:
		self.level = level
		self.header = header
		self.body = body
		self.source = source

@abstract func get_object_type() -> ObjectType

func assign_uuid() -> void:
	var new_uuid = UUID.from_String(uuid)
	if new_uuid != UUID.new():
		attached_uuid = new_uuid
	else:
		attached_uuid = null

# setup self and call prep on children, then return children
func on_pre_upload() -> Node:
	if !attached_uuid:
		attached_uuid = UUID.new(true)
	return null # todo

# bindings are applied in reverse order so we need the second binding argument to be first
func get_child_warnings(node:Node, warnings:Array[Warning]) -> bool:
	if blacklisted_types.any(
			func(blacklist_type:GDScript) -> bool: return is_instance_of(node, blacklist_type)):
		warnings.push_back(Warning.new(Warning.WarningLevel.Error, 
				"Blacklisted Type", 
				"this object contains a node of type %s, which is not allowed" % (
				node.get_class()), 
				self))
	elif node is CCKMarker:
		warnings.append_array((node as CCKMarker).get_uploader_warnings())
	return true

func get_upload_warnings() -> Array[Warning]:
	var warnings:Array[Warning] = []
	if get_children().size() > 0:
		SceneTreeHelper.call_children_recursive(get_child(0), get_child_warnings.bind(warnings))
	
	# get config warnings from self
	var self_warnings:Array[String] = _get_configuration_warnings()
	for warning in self_warnings:
		warnings.push_back(Warning.new(
				Warning.WarningLevel.Warning, 
				"Config Error", 
				warning, 
				self))
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
	const FOV:float = 75.0
	var aabb_ref:AABBRef = AABBRef.new()
	SceneTreeHelper.call_children_recursive(self, get_combined_aabb.bind(aabb_ref))
	var aabb:AABB = aabb_ref.aabb
	var pos:Vector3 = aabb.position + (aabb.size / 2)
	# todo: something is broken here.
	# this should place the camera as close as possible to the object,
	# while leaving everything visible.
	# right now it places the camers way too far away and i have no idea why
	pos.z += (maxf(aabb.size.x, aabb.size.y) / 2) / abs(tan(FOV / 2)) * 1.1
	return Transform3D(Basis.IDENTITY, pos)

func _get_configuration_warnings():
	var warnings:Array[String] = []
	
	if get_children().size() == 0:
		warnings.append("object root requires a child")
	if get_children().size() > 1:
		warnings.append("multiple children are not allowed on an object root, children beyond the first child will be ignored")
	
	return warnings
