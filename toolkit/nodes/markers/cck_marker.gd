@abstract
extends Node
class_name CCKMarker
# base class for all cck nodes

func get_universal_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	if get_child_count() != 0:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Marker has children", 
				"Children of marker nodes will be deleted on upload, the node you want a marker to target should be the parent of the marker", 
				self))
	return warnings

# this function gets called before uploading the object, 
# it should place the scene in the correct state for uploading.
# if a node is incorrectly configured it can return false to prevent uploading.
# generally you should always return true here and instead use get_uploader_warnings.
# Error level warnings prevent uploading and are preferred over returning false here.
@abstract
func prep_for_upload() -> bool

# this function is used to refresh the uploader warning list
# it should return a list of any configuration issues with this marker
@abstract
func get_uploader_warnings() -> Array[BaseRoot.Warning]
