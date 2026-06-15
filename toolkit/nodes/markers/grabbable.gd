extends CCKMarker
class_name Grabbable

## used to detect a player attempting to grab this object
## should be monitorable and added to layer 2
@export var hitbox:Area3D
@export var max_grab_distance:float
## if this is not null, when grabbed, the grabbable will snap to the players hand. 
## this node is the position of the players hand on the grabbale
@export var snap_target:Node3D

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if !hitbox:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Grabbable missing hitbox", 
				"the Grabbable requires a hitbox to be grabbed", 
				get_parent(), false))
	else:
		if hitbox.collision_layer != 0 and hitbox.collision_layer != 2:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
					"Grabbable hitbox exists in other layers", 
					"the hitbox for the grabbale exists in layers other than the grabbables physics layer, this is probably not intentional", 
					hitbox, true, 
					func():
						hitbox.collision_layer = 2
						return true))
		
		if !hitbox.monitorable:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
					"Grabbable hitbox will not detect grabs", 
					"the hitbox must be monitorable for the object to be grabbable", 
					hitbox, true, 
					func():
						hitbox.monitorable = true
						return true))
	
	if snap_target and snap_target.get_parent() != get_parent():
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"grabbable snap target is not child of grabbable", 
				"the snap target is used as an offset relative to the grabbable for positioning the player's hand. If it is not a child of the grabbale the offset may not be correct", 
				snap_target, false))
		
	return warnings

func prep_for_upload() -> bool:
	var values:Dictionary[String, Variant] = {}
	
	values["hitbox"] = get_parent().get_path_to(hitbox)
	values["max_grab_distance"] = max_grab_distance
	if snap_target:
		values["snap_on_grab"] = true
		values["snap_offset_position"] = snap_target.position
		values["snap_offset_rotation"] = snap_target.rotation
	else:
		values["snap_on_grab"] = false
	
	get_parent().set_meta("Grabbable", values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
