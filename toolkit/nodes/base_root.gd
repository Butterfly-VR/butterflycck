@tool
extends Node
class_name BaseRoot

# creates an error if any types or subtypes in this list are in the object
const blacklisted_types:Array[GDScript] = []

@export var object_name:String
@export var uuid:String

@export_tool_button("assign UUID", "Callable") var assign_button = assign_uuid

var attached_uuid:UUID

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
	
	func _init(level:WarningLevel, header:String, body:String) -> void:
		self.level = level
		self.header = header
		self.body = body

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
				node.get_class())))
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
				warning))
	return warnings

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

# bindings are applied in reverse order so we need the second binding argument to be first
func get_combined_aabb(node:Node, buffer:AABB) -> bool:
	print(node.get_class())
	if node is VisualInstance3D:
		print("got one")
		buffer = buffer.merge((node as VisualInstance3D).get_aabb())
	return true

# default camera position calculation
# positions the camera such that it sees the entire object based on its bounding box
func get_preview_camera_transform() -> Transform3D:
	const FOV:float = 75.0
	var aabb:AABB = AABB()
	SceneTreeHelper.call_children_recursive(self, get_combined_aabb.bind(aabb))
	var pos:Vector3 = aabb.position
	print("size and distance calculations")
	print(max(aabb.size.x, aabb.size.y))
	print(max(aabb.size.x, aabb.size.y) / tan(FOV / 2))
	pos.z -= maxf(aabb.size.z / 2, maxf(aabb.size.x, aabb.size.y) / abs(tan(FOV / 2))) * 1.1
	return Transform3D(Basis.IDENTITY, pos)

func _get_configuration_warnings():
	var warnings:Array[String] = []
	
	if get_children().size() == 0:
		warnings.append("object root requires a child")
	if get_children().size() > 1:
		warnings.append("multiple children are not allowed on an object root, 
				children beyond the first child will be ignored")
	
	return warnings
