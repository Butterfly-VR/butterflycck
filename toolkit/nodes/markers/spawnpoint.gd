@tool
extends CCKMarker
class_name SpawnPoint

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

func _get_configuration_warnings():
	var warnings:Array[String] = []
	if get_parent() is not Node3D:
		warnings.append("Spawnpoint must be child of Node3D.")
	return warnings

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	if get_parent() is not Node3D:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Spawnpoint invalid parent", 
				"A spawnpoint marker must be attached to a Node3D or subclass, 
				this node determines the actual spawning location"))
	
	return warnings

func prep_for_upload() -> bool:
	if get_parent() is not Node3D:
		return false
	
	get_parent().set_meta("Spawnpoint", true)
	
	queue_free()
	
	return true
