@tool
extends CCKMarker
class_name AvatarColliderConfig

@export var radius:float = 0.5
@export var height:float = 1.0

func _process(delta: float) -> void:
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
	
	return warnings

func prep_for_upload() -> bool:
	var meta_values:Dictionary[String, Variant] = {}
	
	meta_values["marker_version"] = get_marker_version_string()
	meta_values["radius"] = radius
	meta_values["height"] = height
	
	get_parent().set_meta("AvatarColliderConfig", meta_values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"
