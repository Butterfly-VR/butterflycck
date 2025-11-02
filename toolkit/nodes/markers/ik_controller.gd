@tool
extends CCKMarker
class_name IKController

@export_enum(" ") var head_bone: String
@export_enum(" ") var left_arm_bone: String
@export_enum(" ") var right_arm_bone: String
@export_enum(" ") var left_leg_bone: String
@export_enum(" ") var right_leg_bone: String
@export_enum(" ") var spine_bone: String
@export_enum(" ") var hip_bone: String

@export var eye_placement:Node3D

func _validate_property(property: Dictionary) -> void:
	if property.name.contains("bone"):
		var skeleton: Skeleton3D = get_parent() if get_parent() is Skeleton3D else null
		if skeleton:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = skeleton.get_concatenated_bone_names()

func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed

func _get_configuration_warnings():
	var warnings:Array[String] = []
	if get_parent() is not Skeleton3D:
		warnings.append("IKController must be child of Skeleton3D.")
	return warnings

func check_bone_config(target:Skeleton3D) -> bool:
	return (target.find_bone(head_bone) == -1 or 
			target.find_bone(left_arm_bone) == -1 or 
			target.find_bone(right_arm_bone) == -1 or 
			target.find_bone(left_leg_bone) == -1 or 
			target.find_bone(right_leg_bone) == -1 or 
			target.find_bone(spine_bone) == -1 or 
			target.find_bone(hip_bone) == -1)

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	if get_parent() is not Skeleton3D:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController must be child of Skeleton3D", 
				"the IKController acts as a Skelleton3DModifier ingame, this means it also needs to be a child of a Skeleton3D", 
				self))
	
	else:
		if !check_bone_config(get_parent()):
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
					"IKController is missing bone targets", 
					"all target bones in the IKController must be assigned to valid bones in the Skeleton3D", 
					self))
	
	if eye_placement == null:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
				"IKController does not have eye position", 
				"the IKController needs a node that tell it where to place the player's camera relative to the head", 
				self))
	
	return warnings

func prep_for_upload() -> bool:
	var target = get_parent()
	if target is not Skeleton3D or !check_bone_config(target):
		return false
	var parent:Skeleton3D = get_parent()
	
	var bones:Array[String] = [head_bone, left_arm_bone, right_arm_bone, 
			left_leg_bone, right_leg_bone, spine_bone, hip_bone]
	var targets:Array[Node3D] = []
	
	# create bone targets in parent
	for bone in bones:
		var bone_target = Node3D.new()
		parent.add_child(bone_target)
		bone_target.transform = parent.get_bone_pose(parent.find_bone(bone))
		targets.push_back(bone_target)
	
	# create meta value for parent
	var meta_values:Dictionary[String, int] = {}
	
	meta_values["head_bone"] = parent.find_bone(bones[0])
	meta_values["head_target"] = targets[0].get_index()
	meta_values["head_view"] = eye_placement.get_index()
	meta_values["left_arm_bone"] = parent.find_bone(bones[1])
	meta_values["left_arm_target"] = targets[1].get_index()
	meta_values["right_arm_bone"] = parent.find_bone(bones[2])
	meta_values["right_arm_target"] = targets[2].get_index()
	meta_values["left_leg_bone"] = parent.find_bone(bones[3])
	meta_values["left_leg_target"] = targets[3].get_index()
	meta_values["right_leg_bone"] = parent.find_bone(bones[4])
	meta_values["right_leg_target"] = targets[4].get_index()
	meta_values["spine_bone"] = parent.find_bone(bones[5])
	meta_values["spine_target"] = targets[5].get_index()
	meta_values["hip_bone"] = parent.find_bone(bones[6])
	meta_values["hip_target"] = targets[6].get_index()
	
	parent.set_meta("IKMarker", meta_values)
	
	queue_free()
	
	return true
