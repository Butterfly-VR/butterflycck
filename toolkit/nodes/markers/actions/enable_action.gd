## Toggles or sets the "enabled" or "active" property of the parent node if it exists
extends CCKAction
class_name EnableAction

enum BehaviorMode{
	Toggle,
	SetOn,
	SetOff
}

@export var behavior:BehaviorMode

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["mode"] = int(behavior)
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "EnableAction"

func check_parent_properties() -> bool:
	var properties:Array[Dictionary] = get_parent().get_property_list()
	
	for property:Dictionary[String, Variant] in properties:
		if property["name"] == "enabled" or property["name"] == "active":
			return true
	return false

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if !check_parent_properties():
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"EnableAction parent missing property", 
				"The parent of an EnableAction marker has no \"enabled\" or \"active\" property for the marker to toggle.", 
				self))
	
	return warnings
