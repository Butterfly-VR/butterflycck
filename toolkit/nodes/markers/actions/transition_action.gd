@tool
extends CCKAction
class_name TransitionAction

@export var target:CCKAnimationTree:
	set(x):
		target = x
		notify_property_list_changed()
@export_enum(" ") var state_machine:String:
	set(x):
		state_machine = x
		notify_property_list_changed()
@export_enum(" ") var target_node:String
@export_enum("None") var source_node:String = "None"
@export var transition_type:TransitionTypes
@export var teleport_if_unreachable:bool = false

var path_lookup:Dictionary[String, String]
var node_list_string:String = ""

enum TransitionTypes{
	single_transition,
	travel,
	instant
}

class UniquePathData:
	var original_path:String
	var start_point:int
	var valid:bool = true
	
	static func create(original_path:String, start_point:int) -> UniquePathData:
		var x = UniquePathData.new()
		x.original_path = original_path
		x.start_point = start_point
		return x

func _validate_property(property: Dictionary) -> void:
	if property.name == "state_machine" and target:
		path_lookup.clear()
		
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		
		var paths:PackedStringArray = target.get_concatenated_sate_machine_paths().split(",", false)
		var shortest_unique_paths:Dictionary[PackedStringArray, UniquePathData] = {}
		var root_is_state_machine:bool = false
		
		for p:String in paths:
			if p == "ROOT":
				# root special case
				root_is_state_machine = true
				continue
			
			var path:PackedStringArray = p.split("/", false)
			
			for start_point in range(path.size() - 1, -1, -1):
				var sub_path:PackedStringArray = path.slice(start_point)
				
				if !shortest_unique_paths.has(sub_path):
					shortest_unique_paths[sub_path] = UniquePathData.create(p, start_point)
					break
				else:
					var other:UniquePathData = shortest_unique_paths[sub_path]
					other.valid = false
					shortest_unique_paths[sub_path] = other
					
					other = UniquePathData.create(other.original_path, other.start_point)
					other.start_point -= 1
					if other.start_point == -1:
						push_error("two state machines had identical paths. bug?")
						return
					
					shortest_unique_paths[other.original_path.split("/").slice(other.start_point)] = other
					continue
		
		var result:String = ""
		
		if root_is_state_machine:
			result += "ROOT,"
		
		for path in shortest_unique_paths.keys():
			if !shortest_unique_paths[path].valid:
				continue
			
			var path_string:String = ""
			for chunk:String in path:
				path_string += chunk.erase(0) + "/"
			path_string = path_string.trim_suffix("/")
			
			path_lookup[path_string] = shortest_unique_paths[path].original_path
			result += path_string + ","
		
		result = result.trim_suffix(",")
		property.hint_string = result
	
	if property.name == "target_node":
		if target and !state_machine.is_empty() and (!path_lookup.is_empty() or state_machine == "ROOT"):
			property.hint = PropertyHint.PROPERTY_HINT_ENUM
			
			var current_node:AnimationRootNode = target.get_child(0).tree_root
			if state_machine != "ROOT":
				for chunk in path_lookup[state_machine].trim_prefix("ROOT/").split("/", false):
					var prefix:String = chunk[0]
					match prefix:
						"I":
							current_node = current_node.get_blend_point_node(int(chunk.substr(1)))
						"N":
							current_node = current_node.get_node(chunk.substr(1))
						_:
							push_error("invalid prefix %s in path segment" % prefix)
			var state_machine_node:AnimationNodeStateMachine = current_node
			
			var result:String = ""
			for node_name in state_machine_node.get_node_list():
				result += node_name + ","
			result = result.trim_suffix(",")
			
			property.hint_string = result
			node_list_string = result
		else:
			node_list_string = ""
	
	if property.name == "source_node":
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		if !node_list_string.is_empty():
			property.hint_string = "None," + node_list_string
		else:
			property.hint_string = "None"

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["target"] = get_parent().get_path_to(target)
	values["state_machine"] = path_lookup[state_machine] if state_machine != "ROOT" else "ROOT"
	values["target_node"] = target_node
	if source_node != "None":
		values["source_node"] = source_node
	values["transition_type"] = transition_type as int
	values["teleport_if_unreachable"] = teleport_if_unreachable
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "TransitionAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if !target:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"TransitionAction target not set", 
			"A TransitionAction must target a CCKAnimationTree containing a state machine.", 
			self, false))
	if state_machine.is_empty() or state_machine == " ":
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"TransitionAction state machine not set", 
			"You must specify the state machine within the AnimationTree that this action will control.", 
			self, false))
	if target_node.is_empty() or target_node == " ":
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"TransitionAction target node not set", 
			"You must specify the animation node within the state machine that this action will transition to.", 
			self, false))
	
	return warnings
