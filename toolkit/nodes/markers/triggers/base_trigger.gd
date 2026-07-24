@abstract
@tool
extends CCKMarker
class_name CCKTrigger
# base class for all triggers

@export var active:bool = true
# custom parameters always get pushed in front of parameters from the trigger
@export var custom_parameters:Array[Variant]
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
