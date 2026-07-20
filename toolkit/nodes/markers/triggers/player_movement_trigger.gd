@tool
extends CCKTrigger
class_name PlayerMovementTrigger

func get_trigger_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	return values

func get_trigger_version_string() -> String:
	return "1"

func get_trigger_name() -> String:
	return "PlayerMovementTrigger_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	return warnings
