@tool
extends CCKMarker
## This node allows a player to grab the parent node of this marker by right clicking.
##
## This node requires an Area3D set as monitorable to detect when a player targets it.
## [br]
## It can also optionaly snap to the player's hand when grabbed.
## [br]
## It can also add a highlight effect to a mesh when grabbed.
class_name Grabbable

## Used to detect a player attempting to grab this object.
## Should be monitorable and in no collision layers other than layer 2.
@export var hitbox:Area3D
## The maximum distance this can be grabbed from, calculated from the grabber's
## origin to the point on the hitbox surface where the raycast collided.
@export var max_grab_distance:float = -1.0
## If this is not null, when grabbed, the grabbable will snap to the players hand. 
## This node is the position of the players hand on the grabbable
@export var snap_target:Node3D
## The mesh that gets highlighted when the hitbox is hovered over.
## generally this should either be the mesh of the grabbed object or a mesh
## in the shape of the hitbox. If this is not set it may be hard for players
## to realise this object is grabbable.
@export var highlight_target:MeshInstance3D

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	for sibling in get_parent().get_children():
		if (sibling.get_script() != null 
				and sibling.get_class() == get_class() 
				and sibling.get_script().source_code == get_script().source_code 
				and sibling != self):
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Duplicate Grabbables on node", 
				"A node cannot have more than one Grabbable attached", 
				self, false))
	
	if !hitbox:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Grabbable missing hitbox", 
				"the Grabbable requires a hitbox to be grabbed", 
				self, false))
	else:
		if hitbox.collision_layer != 0 and hitbox.collision_layer != 2:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Info, 
					"Grabbable hitbox exists in other layers", 
					"the hitbox for the grabbable exists in layers other than the grabbables \
							physics layer, this is probably not intentional", 
					hitbox, true, 
					func():
						hitbox.collision_layer = hitbox.collision_layer | 2
						return true))
	
	if snap_target and snap_target.get_parent() != get_parent():
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"grabbable snap target is not child of grabbable", 
				"the snap target is used as an offset relative to the grabbable for \
						positioning the player's hand. If it is not a child of the \
						grabbale the offset may not be correct", 
				snap_target, false))
	
	if !highlight_target:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Info, 
				"grabbable has no highlight mesh", 
				"a highlight mesh is important to indicate that an object is grabbable,\
				you should strongly consider adding a highlight target.", 
				snap_target, false))
	
	return warnings

func prep_for_upload() -> bool:
	var values:Dictionary[String, Variant] = {}
	var parent:Node = get_parent()
	parent.remove_child(self)
	
	values["marker_version"] = get_marker_version_string()
	
	values["hitbox"] = hitbox.get_index()
	values["max_grab_distance"] = max_grab_distance
	values["highlight_mesh"] = hitbox.get_path_to(highlight_target) if highlight_target else ""
	if snap_target:
		values["snap_on_grab"] = true
		values["snap_offset_position"] = snap_target.position
		values["snap_offset_rotation"] = snap_target.rotation
	else:
		values["snap_on_grab"] = false
	
	parent.set_meta("Grabbable", values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
