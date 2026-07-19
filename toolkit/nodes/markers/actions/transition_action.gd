@tool
extends CCKAction
class_name TransitionAction

@export var target:CCKAnimationTree
@export_enum(" ") var state_machine:String
@export_enum(" ") var transition:String
@export var transition_type:TransitionTypes
@export var teleport_if_unreachable:bool = false

var path_lookup:Dictionary[String, String]

enum TransitionTypes{
	single_transition,
	travel,
	instant
}

class UniquePathData:
	var original_path:String
	var start_point:int
	var valid:bool = true
	
	func _to_string() -> String:
		return "UniquePathData[%s, %s, %s]" % [original_path, start_point, valid]
	
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

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "TransitionAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	
	
	return warnings
