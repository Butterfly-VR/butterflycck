@abstract
@tool
extends CCKMarker
## Base class for all action nodes.
##
## An action nodes performs some action when it recieves and event from a CCKTrigger. 
## for more info see the wiki at https://github.com/Butterfly-VR/butterflycck/wiki
class_name CCKAction

## If false, will ignore any events targeting it.
@export var active:bool = true
## Specifies any additional parameters that will be added to events targeting this
## action. These custom parameters always get pushed after all other parameters.
@export var custom_parameters:Array[Variant]

var action_id = UUID.new(true)

func prep_for_upload() -> bool:
	var action_info:Dictionary[String, Variant] = {}
	action_info.assign(get_action_info())
	
	action_info["version"] = get_action_version_string()
	action_info["active"] = active
	action_info["action_id"] = action_id.backing_storage
	action_info["custom_parameters"] = custom_parameters
	
	get_parent().set_meta(get_action_name(), action_info)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	push_error("tried to get CCKMarker version of a CCKaction. \
			(did you mean get_action_version_string()?)")
	return "UNNAMED"

## gets the required info for this Action's effect
## this is used for configuring the trigger in game
## if this cannot be done (for example the action has a parent of the wrong type)
## then an empty dict should be returned
## the usual rule about prefering to raise upload warnings applies
## if ["action_version"], ["active"], ["action_id"], or ["custom_parameters"] are present they will be overwritten
@abstract
func get_action_info() -> Dictionary[String, Variant];

@abstract
func get_action_version_string() -> String;

@abstract
func get_action_name() -> String;
