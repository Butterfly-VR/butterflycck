@tool
extends CCKTrigger
## Emits an event every frame. Can optionally include a parameter containing
## the number of ticks it has been active.
class_name AlwaysTrigger

## If true, will push a parameter containing the total number of ticks this trigger
## has been active for.
@export var include_tick_count: bool = false


func get_trigger_info() -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = { }

	values["include_tick_count"] = include_tick_count

	return values


func get_trigger_version_string() -> String:
	return "1"


func get_trigger_name() -> String:
	return "AlwaysTrigger_%s" % name


func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	return warnings
