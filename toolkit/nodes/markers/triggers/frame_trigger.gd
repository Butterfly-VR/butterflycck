## triggers any attached actions every physics tick. has no parameters
extends CCKTrigger
class_name AlwaysTrigger

func get_trigger_info() -> Dictionary[String, Variant]:
	return {}

func get_trigger_version_string() -> String:
	return "1"

func get_trigger_name() -> String:
	return "AlwaysTrigger"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	return warnings
