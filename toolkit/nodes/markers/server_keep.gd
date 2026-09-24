@tool
extends CCKMarker
## Stops visual assets (meshes, textures, etc) from being removed, from its parent and any children
## of that parent, when this object is loaded on a gameserver.
class_name RetainOnServer

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	return get_universal_warnings()


func prep_for_upload() -> bool:
	queue_free()
	return true


func get_marker_version_string() -> String:
	return "UNNAMED"
