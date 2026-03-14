@abstract
extends CCKMarker
class_name CCKTrigger
# base class for all triggers

enum TriggerTypes{
	COLLIDER_COLLISION_TRIGGER,
	RAYCAST_COLLISION_TRIGGER,
	BUTTON_COLLIDER_TRIGGER
}

# custom parameters always get passed after parameters from the trigger
@export var custom_parameters:Array[Variant]

var targets:Array[NodePath] = []

func prep_for_upload() -> bool:
	var trigger_info:Dictionary[String, Variant] = {}
	trigger_info.assign(get_trigger_info())
	
	if trigger_info.is_empty():
		return false
	
	var parent:Node = get_parent()
	
	for key in trigger_info.keys():
		parent.set_meta(key, trigger_info[key])
	
	parent.set_meta("targets", targets)
	parent.set_meta("custom_params", custom_parameters)
	
	queue_free()
	
	return true

# gets the required info for this Trigger's cause
# if this cannot be done (for example the trigger has a parent of the wrong type)
# then an empty dict should be returned
# the usual rule about prefering to raise upload warnings applies
@abstract
func get_trigger_info() -> Dictionary[String, Variant]
