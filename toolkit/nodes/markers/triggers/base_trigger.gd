@abstract
@tool
extends CCKMarker
## Base class for all trigger nodes.
##
## A trigger nodes emits an event for any attached CCKActions whenever a specified 
## condition becomes true. for more info see the wiki at 
## https://github.com/Butterfly-VR/butterflycck/wiki
class_name CCKTrigger

## If false, will not trigger any attached events.
@export var active:bool = true
## Specifies any extra parameters that will be included with events emitted by 
## this trigger. Custom parameters always get pushed in front of parameters 
## from the trigger.
@export var custom_parameters:Array[Variant]
## the list of CCKActions triggered by this node. Each one recieves a copy of the event.
@export var triggered_actions:Array[CCKAction]

func prep_for_upload() -> bool:
	var targets:Array[PackedByteArray] = []
	targets.assign(triggered_actions.map(
			func(action:CCKAction): 
				return action.action_id.backing_storage))
	var trigger_info:Dictionary[String, Variant] = {}
	trigger_info.assign(get_trigger_info())
	
	trigger_info["version"] = get_trigger_version_string()
	trigger_info["active"] = active
	trigger_info["targets"] = targets
	trigger_info["custom_parameters"] = custom_parameters
	
	get_parent().set_meta(get_trigger_name(), trigger_info)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	push_error("tried to get CCKMarker version of a CCKTrigger. \
			(did you mean get_trigger_version_string()?)")
	return "UNNAMED"

## gets the required info for this Trigger's cause
## this is used for configuring the trigger in game
## if this cannot be done (for example the trigger has a parent of the wrong type)
## then an empty dict should be returned
## the usual rule about prefering to raise upload warnings applies
## if ["trigger_version"], ["active"], ["targets"], or ["custom_parameters"] are present they will be overwritten
@abstract
func get_trigger_info() -> Dictionary[String, Variant];

@abstract
func get_trigger_version_string() -> String;

@abstract
func get_trigger_name() -> String;
