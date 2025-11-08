@tool
extends TabContainer

class ObjectMeta:
	var name:String
	var description:String
	var tags:Array[String]
	var uuid:UUID
	var owner:UUID
	var object_size_KB:int
	var image_size_KB:int
	var image_bytes:PackedByteArray

func change_stage(idx:int) -> void:
	current_tab = idx

func setup(root:BaseRoot) -> void:
	pass

func get_object_info(uuid:UUID, object_type:BaseRoot.ObjectType) -> ObjectMeta:
	return null
