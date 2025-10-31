extends Node
class_name CCKMarker
# base class for all cck nodes

# this function gets called before uploading the object, it should place the scene in the correct state for uploading
# if a node is incorrectly configured it can return false to prevent uploading
# generally you should always return true here and instead check for issues in get_uploader_warnings
# Error level warnings prevent uploading and are preferred over returnign false here
func prep_for_upload() -> bool:
	return true

# this function is used to refresh the uploader warning list
# it should return a list of any configuration issues with this marker
func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	return []
