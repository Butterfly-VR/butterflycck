@abstract
extends CCKMarker
class_name CCKAction
# base class for all actions

enum ActionTypes{
	GAMEOBJECT_TOGGLER,
	SINGLE_ANIMATION_PLAYER,
	MULTI_ANIMATION_PLAYER
}

func prep_for_upload() -> bool:
	var action_info:Dictionary[String, Variant] = {}
	action_info.assign(get_action_info())
	
	if action_info.is_empty():
		return false
	
	var parent:Node = get_parent()
	
	for key in action_info.keys():
		parent.set_meta(key, action_info[key])
	
	queue_free()
	
	return true

# gets the required info for this Action's cause
# if this cannot be done (for example the action has a parent of the wrong type)
# then an empty dict should be returned
# the usual rule about prefering to raise upload warnings applies
@abstract
func get_action_info() -> Dictionary[String, Variant]
