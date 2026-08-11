@tool
extends CCKAction
## When triggered, causes the specified transition in the specified state machine.
class_name TransitionAction

## The target CCKAnimationTree.
@export var target:CCKAnimationTree:
	set(x):
		target = x
		notify_property_list_changed()
## The target StateMachine.
@export_enum(" ") var state_machine:String:
	set(x):
		state_machine = x
		notify_property_list_changed()
## The node to transition to.
@export_enum(" ") var target_node:String
## If not 'None', will only transition if this is the current node in the StateMachine.
@export_enum("None") var source_node:String = "None"
## If true, teleport directly to target_node, otherwise follow a path of 
## transitions to the target. Will always teleport if no path to the target exists.
@export var teleport:bool = false

var path_lookup:Dictionary[String, String]
var node_list_string:String = ""

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
		
		var paths:PackedStringArray = target.get_concatenated_state_machine_paths().split(",", false)
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
					
					if !other.valid:
						continue
					else:
						if other.start_point == 0:
							if start_point == 0:
								push_error("two state machines had identical paths. bug?")
								return
							else:
								# this case is a pain to handle since only extending one of the paths
								# breaks the assumption that no path is a prefix of another path
								# at any rate it can only happen if one of the paths contains 
								# a second ROOT node so its pretty unlikely to happen by accident
								push_error("hit the weird edge case when two nodes have the same path \
										but one of them cant be extended. you only have yourself to blame")
								return
						
						other.valid = false
						other = UniquePathData.create(other.original_path, other.start_point)
						other.start_point -= 1
						shortest_unique_paths[other.original_path.split("/", false).slice(other.start_point)] = other
		
		var result:String = ""
		
		if root_is_state_machine:
			result += "ROOT,"
		
		for path in shortest_unique_paths.keys():
			if !shortest_unique_paths[path].valid:
				continue
			
			var path_string:String = ""
			for chunk:String in path:
				if chunk == "ROOT":
					path_string += chunk + "/"
				else:
					if chunk[0] == "N" and chunk.substr(1).is_valid_int():
						# special case to avoid "N0" and "I0" becoming the same displayed path
						path_string += "\"%s\"/" % chunk.substr(1)
					else:
						path_string += chunk.substr(1) + "/"
			path_string = path_string.trim_suffix("/")
			
			path_lookup[path_string] = shortest_unique_paths[path].original_path
			result += path_string + ","
		
		result = result.trim_suffix(",")
		property.hint_string = result
	
	if property.name == "target_node":
		if target and target.get_child_count() > 0 and !state_machine.is_empty() \
				and (!path_lookup.is_empty() or state_machine == "ROOT"):
			property.hint = PropertyHint.PROPERTY_HINT_ENUM
			
			var current_node:AnimationRootNode = target.get_child(0).tree_root
			if state_machine != "ROOT":
				for chunk in path_lookup[state_machine].trim_prefix("ROOT/").split("/", false):
					var prefix:String = chunk[0]
					match prefix:
						"I":
							# CCKAnimationTree guarentees this is a 1D/2D BlendSpace
							current_node = current_node.get_blend_point_node(int(chunk.substr(1)))
						"N":
							# CCKAnimationTree guarentees this is a StateMachine or BlendTree
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
		# will be stale if this property is updated before target_node
		# if update order stops being guarenteed we will need to change this
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		if !node_list_string.is_empty():
			property.hint_string = "None," + node_list_string
		else:
			property.hint_string = "None"

func get_action_info() -> Dictionary[String, Variant]:
	# dirty hack to force path_lookup to rebuild
	# todo: should probably move the rebuild to its own function
	get_property_list()
	
	var values:Dictionary[String, Variant] = {}
	
	values["target"] = get_parent().get_path_to(target)
	values["state_machine"] = path_lookup[state_machine] if state_machine != "ROOT" else "ROOT"
	values["target_node"] = target_node
	if source_node != "None":
		values["source_node"] = source_node
	values["teleport"] = teleport
	
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
	
	# todo: check we arnt holding stale values (check set values exist in the enum)
	
	return warnings
