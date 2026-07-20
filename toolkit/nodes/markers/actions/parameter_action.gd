@tool
extends CCKAction
class_name ParameterAction

@export var target:CCKAnimationTree:
	set(x):
		target = x
		notify_property_list_changed()
@export_enum(" ") var parameter:String

func _validate_property(property: Dictionary) -> void:
	if property.name == "parameter" and target:
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		
		var tree:AnimationTree = target.get_child(0)
		
		var result:String = ""
		for property_values in tree.get_property_list():
			if !(property_values.name as String).begins_with("parameters/"):
				continue
			if (property_values.name as String).ends_with("playback"):
				continue
			result += (property_values.name as String).trim_prefix("parameters/") + ","
		
		property.hint_string = result.trim_suffix(",") if !result.is_empty() else " "

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["target"] = get_parent().get_path_to(target)
	values["parameter"] = parameter
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "ParameterAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	push_warning("todo: uploader warnings ParameterAction")
	
	return warnings
