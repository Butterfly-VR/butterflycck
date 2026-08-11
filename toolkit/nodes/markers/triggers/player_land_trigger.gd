@tool
extends CCKTrigger
## Emits an event whenever the player lands after being in the air. This node will 
## be removed in the future for a more flexible [i]PlayerValuesTrigger[/i].
class_name PlayerLandTrigger

func get_trigger_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	return values

func get_trigger_version_string() -> String:
	return "1"

func get_trigger_name() -> String:
	return "LandTrigger_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	return warnings
