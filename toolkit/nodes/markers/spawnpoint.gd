@tool
extends CCKMarker
## Determines where players spawn in a world.
##
## The parent of this marker is the position and rotation a player will 
## start in upon joining a world. the parent must be a [Node3D] or derived from it.
class_name Spawnpoint

@export var enabled:bool = true

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if get_parent() is not Node3D:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Spawnpoint must be child of Node3D", 
				"The Node3D is where players will spawn.", 
				get_parent(), false))
	
	for sibling in get_parent().get_children():
		if (sibling.get_script() != null 
				and sibling.get_class() == get_class() 
				and sibling.get_script().source_code == get_script().source_code 
				and sibling != self):
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Duplicate Spawnpoints on node", 
				"A node cannot have more than one Spawnpoint attached.", 
				self, false))
	
	return warnings

func prep_for_upload() -> bool:
	if get_parent() is not Node3D:
		return false
	
	get_parent().set_meta("Spawnpoint", {"version": get_marker_version_string(), "enabled": enabled})
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "2"
