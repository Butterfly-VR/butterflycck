@abstract
@tool
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
	
	for sibling in get_parent().get_children():
		if (sibling.get_script() != null 
				and sibling.get_class() == get_class() 
				and sibling.get_script().source_code == get_script().source_code 
				and sibling != self):
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Duplicate Markers on node", 
				"A node currently cannot have more than one Marker of the same type attached", 
				sibling))
	
	return warnings

func _process(delta: float) -> void:
	update_configuration_warnings()

func _get_configuration_warnings():
	var warnings:Array[BaseRoot.Warning] = get_uploader_warnings()
	var errors:Array[BaseRoot.Warning] = warnings.filter(
			func(x:BaseRoot.Warning) -> bool:
				return x.level == BaseRoot.Warning.WarningLevel.Error)
	var warning_strings:Array[String] = []
	warning_strings.assign(errors.map(
			func(x:BaseRoot.Warning) -> String:
				return x.header))
	return warning_strings

## this function gets called before uploading the object, 
## it should place the scene in the correct state for uploading.
## if a node is incorrectly configured it can return false to prevent uploading.
## generally you should always return true here and instead use get_uploader_warnings.
## Error level warnings prevent uploading and are preferred over returning false here.
@abstract
func prep_for_upload() -> bool

## this function is used to refresh the uploader warning list
## it should return a list of any configuration issues with this marker
@abstract
func get_uploader_warnings() -> Array[BaseRoot.Warning]

@abstract
func get_marker_version_string() -> String
