## prevents child nodes from appearing in the uploaded object
@tool
extends CCKMarker
class_name UploadSkipMarker

func get_universal_warnings() -> Array[BaseRoot.Warning]:
	return []

func _get_configuration_warnings():
	return []

func prep_for_upload() -> bool:
	queue_free()
	return true

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	return []

func get_marker_version_string() -> String:
	return "UNNAMED"
