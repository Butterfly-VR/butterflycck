## triggers any attached actions every physics tick. can optionally include a parameter counting the number of ticks it has triggered for.
@tool
extends CCKTrigger
class_name AlwaysTrigger

@export var include_tick_count:bool = false

func get_trigger_info() -> Dictionary[String, Variant]:
	return {}

func get_trigger_version_string() -> String:
	return "1"

func get_trigger_name() -> String:
	return "AlwaysTrigger:%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	return warnings
