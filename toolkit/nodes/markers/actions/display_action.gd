@tool
extends CCKAction
class_name DisplayAction

@export_multiline var text:String = "%s"
@export var show_all_parameters:bool = false

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["text"] = text
	values["show_all_parameters"] = show_all_parameters
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "DisplayAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if get_parent() is not Label3D:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"DisplayAction must be child of Label3D", 
				"This is where the text for the DisplayAction will be shown", 
				get_parent(), false))
	
	if !text.contains("%s"):
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"DisplayAction text missing placeholder", 
				"The text must contain a '%s' placeholder to tell the \
				DisplayAction where to show the value", 
				self, false))
	
	return warnings
