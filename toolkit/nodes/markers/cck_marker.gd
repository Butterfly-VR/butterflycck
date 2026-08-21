@abstract
@tool
extends Node
## Base class for all cck marker nodes.
##
## Marker nodes are not uploaded themselves, instead they include extra
## information for the client, telling it how to modify the object.
## [br]
## This is done for three main reasons: it allows predefined scripts to run
## on an object without giving an attacker the ability to execute arbitrary
## code on the client, they can replace certain "dangerous" nodes like
## [AnimationMixer]s that can also execute arbitrary code, and it allows
## the implementation of a marker to change without needing to modify
## or reupload all previous uploads.
class_name CCKMarker


## Gets a list of warnings that apply to any marker node, such as a warning
## that markers should not have child nodes.
func get_universal_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = []

	for child in get_children():
		warnings.append(BaseRoot.Warning.new(
				BaseRoot.Warning.WarningLevel.Warning,
				"Markers should not have children",
				"Children of marker nodes will be deleted on upload, the node you want a marker \
						to target should be the parent of the marker.",
				child,
				false,
			))
		break

	return warnings


func _process(delta: float) -> void:
	update_configuration_warnings()


func _get_configuration_warnings():
	var warnings: Array[BaseRoot.Warning] = get_uploader_warnings()
	var errors: Array[BaseRoot.Warning] = warnings.filter(
		func(x: BaseRoot.Warning) -> bool:
			return x.level >= BaseRoot.Warning.WarningLevel.Warning,
	)
	var warning_strings: Array[String] = []
	warning_strings.assign(
		errors.map(
			func(x: BaseRoot.Warning) -> String:
				return x.header,
		)
	)
	return warning_strings


## This function gets called before uploading the object,
## it should place the scene in the correct state for uploading.
## If a node is incorrectly configured it can return false to prevent uploading.
## Generally you should always return true here and instead use get_uploader_warnings.
## Error level warnings prevent uploading and are preferred over returning false here.
@abstract
func prep_for_upload() -> bool ;


## This function is used to refresh the uploader warning list.
## It should return a list of any configuration issues with this marker.
## Error level warning indicate that uploading cannot continue, Warning level
## indicate valid data that will likely result in unintended behavior, and
## Info level indicates unusual configurations that most users should avoid.
@abstract
func get_uploader_warnings() -> Array[BaseRoot.Warning] ;


## This function returns a string indicating the compatability version for this marker.
## This should be incremented whenever a change is made to the uploaded metadata
## that is not backwards compatible with older metadata versions (as in, a parser,
## for the current version could parse the old metadata into the same results as
## the old parser).
@abstract
func get_marker_version_string() -> String ;
