@abstract
@tool
extends CCKMarker
## Base class for all trigger nodes.
##
## A trigger node emits an event for any attached [CCKAction]s whenever a specified
## condition becomes true. For more info see the wiki at
## [url]https://github.com/Butterfly-VR/butterflycck/wiki[/url]
class_name CCKTrigger

## If false, will not trigger any attached events.
@export var active: bool = true
## Specifies any extra parameters that will be included with events emitted by
## this trigger. Custom parameters always get pushed in front of this
## trigger's own parameters.
@export var custom_parameters: Array[Variant]
## The list of [CCKAction]s triggered by this node. Each one receives a copy of the event.
@export var triggered_actions: Array[CCKAction]


func prep_for_upload() -> bool:
	var targets: Array[PackedByteArray] = []
	targets.assign(
		triggered_actions.map(
			func(action: CCKAction):
				return action.action_id.backing_storage,
		)
	)
	var trigger_info: Dictionary[String, Variant] = { }
	trigger_info.assign(get_trigger_info())

	trigger_info["version"] = get_trigger_version_string()
	trigger_info["active"] = active
	trigger_info["targets"] = targets
	trigger_info["custom_parameters"] = custom_parameters

	get_parent().set_meta(get_trigger_name(), trigger_info)

	queue_free()

	return true


## Triggers use [method get_trigger_version_string] instead of this function;
## calling this will push an error and return [code]"UNNAMED"[/code].
func get_marker_version_string() -> String:
	push_error(
		"tried to get CCKMarker version of a CCKTrigger. \
			(did you mean get_trigger_version_string()?)"
	)
	return "UNNAMED"


## Gets the required info for this trigger's cause.[br]
## This is used for configuring the trigger in game.[br]
## If this cannot be done (for example the trigger has a parent of the wrong type)
## then an empty dict should be returned.[br]
## The usual rule about preferring to raise upload warnings applies.[br]
## If [code]"version"[/code], [code]"active"[/code], [code]"targets"[/code], or
## [code]"custom_parameters"[/code] are present they will be overwritten.
@abstract
func get_trigger_info() -> Dictionary[String, Variant] ;


@abstract
func get_trigger_version_string() -> String ;


@abstract
func get_trigger_name() -> String ;
