@tool
extends CCKMarker
class_name CCKAnimationPlayer

@export var animation:Animation
@export var active:bool = true
@export_range(-5, 5, 0.1) var playback_speed:float = 0

func prep_for_upload() -> bool:
	var values:Dictionary[String, Variant] = {}
	
	values["marker_version"] = get_marker_version_string()
	
	values["animation"] = animation
	values["active"] = active
	values["playerback_speed"] = playback_speed
	
	get_parent().set_meta("CCKAnimationPlayer:%s" % name, values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	# check animation for property tracks or method call tracks
	
	return warnings
