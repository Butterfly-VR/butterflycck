@tool
extends CCKMarker
## Prevents child nodes from appearing in the uploaded object.
##
## This is a marker node that applies no metadata to the uploaded object.
## Children of this marker will not be uploaded, and this node will not
## generate warnings if it contains blacklisted children.
## [br][br]
## This allows for example a [WorldEnvironment] to be attached to an avatar,
## allowing you to adjust the preview camera environment, or add lighting with
## a [DirectionalLight3D].
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
