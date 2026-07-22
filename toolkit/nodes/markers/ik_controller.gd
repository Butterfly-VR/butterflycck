@tool
extends CCKMarker
## Provides IK targets from a [Skeleton3D]'s bones for avatars.
##
## When attached to a [Skeleton3D] on an avatar, this marker configures
## the avatar IK to do stuff like move the avatar's head when the player
## looks around or move their arms or legs if they are in VR.
## [br]
## Also configures the positioning of the camera relative to the avatar's head.
class_name IKController

@export_enum(" ") var head_bone: String
@export_enum(" ") var left_hand_bone: String
@export_enum(" ") var right_hand_bone: String
@export_enum(" ") var left_foot_bone: String
@export_enum(" ") var right_foot_bone: String
@export_enum(" ") var spine_bone: String
@export_enum(" ") var hip_bone: String
@export_enum(" ") var chest_bone: String

## Controls the position of the player's 'eyes' relative to the avatar's head.
## Should generally be placed between the avatar's eyes near skin level.
@export var eye_placement:Node3D

func _validate_property(property: Dictionary) -> void:
	if property.name.contains("bone"):
		var skeleton: Skeleton3D = get_parent() if get_parent() is Skeleton3D else null
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func check_bone_config(target:Skeleton3D) -> bool:
	return (target.find_bone(head_bone) == -1 or 
			target.find_bone(left_hand_bone) == -1 or 
			target.find_bone(right_hand_bone) == -1 or 
			target.find_bone(left_foot_bone) == -1 or 
			target.find_bone(right_foot_bone) == -1 or 
			target.find_bone(spine_bone) == -1 or 
			target.find_bone(hip_bone) == -1 or 
			target.find_bone(chest_bone) == -1)

func check_bones_set() -> bool:
	return (head_bone == "" or 
			left_hand_bone == "" or 
			right_hand_bone == "" or 
			left_foot_bone == "" or 
			right_foot_bone == "" or 
			spine_bone == "" or 
			hip_bone == "" or 
			chest_bone == "")

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if get_parent() is not Skeleton3D:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController must be child of Skeleton3D", 
				"The IKController must be a child of the Skeleton3D it is intended to control", 
				get_parent(), false))
	
	for sibling in get_parent().get_children():
		if (sibling.get_script() != null 
				and sibling.get_class() == get_class() 
				and sibling.get_script().source_code == get_script().source_code 
				and sibling != self):
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"Duplicate IKControllers on node", 
				"A node cannot have more than one IKController attached", 
				self, false))
	
	if check_bones_set():
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController is missing bone targets", 
				"all target bones in the IKController must be assigned", 
				self, false))
	elif check_bone_config(get_parent()):
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController has invalid bone targets", 
				"all target bones in the IKController must be valid bones in the Skeleton3D", 
				self, false))
	
	if eye_placement == null:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController does not have eye position", 
				"the IKController needs a node that tell it where to place the player's \
						camera relative to the head", 
				self, false))
	else:
		if eye_placement.get_parent() != get_parent():
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
					"IKController eye position is not child of Skeleton3D", 
					"the eye position node is used as an offset relative to the Skeleton3D \
							for positioning the eyes. If it is not a child of the Skeleton3D \
							the offset may not be correct", 
					eye_placement, false))
	
	return warnings

func prep_for_upload() -> bool:
	var target = get_parent()
	
	if target is not Skeleton3D or check_bone_config(target):
		return false
	
	var parent:Skeleton3D = get_parent()
	
	var meta_values:Dictionary[String, Variant] = {}
	
	meta_values["marker_version"] = get_marker_version_string()
	
	meta_values["head_bone"] = parent.find_bone(head_bone)
	meta_values["head_view"] = eye_placement.position
	meta_values["left_hand_bone"] = parent.find_bone(left_hand_bone)
	meta_values["right_hand_bone"] = parent.find_bone(right_hand_bone)
	meta_values["left_foot_bone"] = parent.find_bone(left_foot_bone)
	meta_values["right_foot_bone"] = parent.find_bone(right_foot_bone)
	meta_values["spine_bone"] = parent.find_bone(spine_bone)
	meta_values["hip_bone"] = parent.find_bone(hip_bone)
	meta_values["chest_bone"] = parent.find_bone(chest_bone)
	
	parent.set_meta("IKMarker", meta_values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
