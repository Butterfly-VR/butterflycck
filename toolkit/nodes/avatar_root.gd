@tool
extends BaseRoot
class_name AvatarRoot

func get_object_type() -> ObjectType:
	return ObjectType.avatar

func get_base_class_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	return warnings
