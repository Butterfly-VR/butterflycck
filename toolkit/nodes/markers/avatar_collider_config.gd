@tool
extends CCKMarker
## This marker tells the client how large the avatar's CapsuleCollider should be.
##
## If this node is missing from an avatar the collider will be sized to the 
## Avatar's AABB. 
## [br]
## in the client, the collider size is clamped between two values
## relative to the AABB of the avatar. This clamping behavior is currently not
## shown in the cck.
## [br][br]
## the capsule visualization is based on the position of the nearest parent Node3D.
## The position may not be accurate if that node is not the Avatar's root node.
## [br][br]
## IMPORTANT: Because of how the debug visualization is drawn, adding this node to a scene where 
## the root node is a AvatarRoot or WorldRoot will result in a 'multiple children on root' error
## in the scene tree. This error will not appear in the uploader or prevent the object being uploaded
class_name AvatarColliderConfig

## The radius of the collider. If this is greater than half the height, either
## the radius or the height will be clamped so that it is equal to half the height.
## Which value gets clamped is not specified.
@export var radius:float = 0.25
## The height of the collider. If this is less than double the radius, either
## the radius or the height will be clamped so that it is equal to half the height.
## Which value gets clamped is not specified.
@export var height:float = 1.8
@export var visible:bool = true

func _process(delta: float) -> void:
	if !visible:
		return
	var target:Node = get_parent()
	for i in range(0, 16):
		if target is Node3D:
			break
		if target.get_parent() == null:
			return
		target = target.get_parent()
	
	if target is not Node3D:
		return
	
	var position:Vector3 = (target as Node3D).global_position
	position.y += height / 2
	
	DebugDraw3D.draw_capsule(
			position, Quaternion.IDENTITY, radius, height)

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	# todo: check size is in valid bounds based on aabb
	
	return warnings

func prep_for_upload() -> bool:
	var meta_values:Dictionary[String, Variant] = {}
	
	meta_values["version"] = get_marker_version_string()
	meta_values["radius"] = radius
	meta_values["height"] = height
	
	get_parent().set_meta("AvatarColliderConfig", meta_values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
