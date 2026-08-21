@tool
extends CCKTrigger
## Emits an event whenever the player's velocity changes, pushes a single parameter
## containing the new velocity. This node will be removed in the future for a more
## flexible [i]PlayerValuesTrigger[/i].
class_name PlayerVelocityTrigger


func get_trigger_info() -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = { }

	return values


func get_trigger_version_string() -> String:
	return "1"


func get_trigger_name() -> String:
	return "VelocityTrigger_%s" % name


func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	return warnings
