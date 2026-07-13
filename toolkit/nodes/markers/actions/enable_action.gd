## Toggles or sets the "enabled" or "active" property of the parent node if it exists
##
## can either toggle the value or take a single bool parameter to set it
@tool
extends CCKAction
class_name EnableAction

@export var take_parameter:bool

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["take_parameter"] = take_parameter
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "EnableAction_%s" % name

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
				"The parent of an EnableAction marker has no \"enabled\" or \
						\"active\" property for the marker to toggle.", 
				get_parent(), false))
	
	return warnings
