@tool
extends CCKMarker
class_name SpawnPoint

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	return warnings

func prep_for_upload() -> bool:
	if get_parent() is not Node3D:
		return false
	
	get_parent().set_meta("Spawnpoint", {"marker_type": get_marker_version_string()})
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
