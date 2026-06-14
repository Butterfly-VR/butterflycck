## triggers any attached actions every physics tick. has no parameters
extends CCKTrigger
class_name AlwaysTrigger

func get_trigger_info() -> Dictionary[String, Variant]:
	return {}

func get_trigger_version_string() -> String:
	return "FrameTrigger:1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	return []
