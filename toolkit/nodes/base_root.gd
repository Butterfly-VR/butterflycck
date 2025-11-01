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

class NodeStackItem:
	var node:Node
	var current_index:int = 0
	
	func get_next_child() -> NodeStackItem:
		if node.get_children().size() > current_index:
			var child = node.get_child(current_index)
			current_index += 1
			return NodeStackItem.new(child)
		return null
	
	func _init(node:Node) -> void:
		self.node = node



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

func get_upload_warnings() -> Array[Warning]:
	var warnings:Array[Warning] = []
	var node_stack:Array[NodeStackItem] = []
	if get_children().size() > 0:
		node_stack.push_back(NodeStackItem.new(get_child(0)))
	
	# get config warnings from self
	var self_warnings:Array[String] = _get_configuration_warnings()
	for warning in self_warnings:
		warnings.push_back(Warning.new(
				Warning.WarningLevel.Warning, 
				"Config Error", 
				warning))
	
	# scene tree traversal to aquire warnings from children
	while !node_stack.is_empty():
		# get the next unsearched branch if it exists
		var next_node:NodeStackItem = node_stack[node_stack.size() - 1].get_next_child()
		
		if next_node:
			if blacklisted_types.any(func(blacklist_type:GDScript) -> bool: 
					return is_instance_of(next_node.node, blacklist_type)):
				warnings.push_back(Warning.new(Warning.WarningLevel.Error, 
						"Blacklisted Type", 
						"this object contains a node of type %s, which is not allowed" % (
						next_node.node.get_class())))
			elif next_node.node is CCKMarker:
				warnings.append_array((next_node.node as CCKMarker).get_uploader_warnings())
			node_stack.push_back(next_node)
		
		# dead end / end of this branch
		node_stack.pop_front()
	return warnings

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
