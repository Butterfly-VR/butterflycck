@tool
extends TabContainer
class_name UploadHandler

const OBJECT_INFO_ENDPOINT:String = "api/v0/%s/%s"

@export var api_handler:APIHandler
@export var account_handler:AccountHandler

class ObjectMeta:
	var name:String
	var object_type:BaseRoot.ObjectType
	var description:String
	var tags:Array[String]
	var uuid:UUID
	var owner:UUID
	var object_size_KB:int
	var image_size_KB:int
	var image_bytes:PackedByteArray

func change_stage(idx:int) -> void:
	current_tab = idx

func setup(root:BaseRoot, default_image:Image, object_type:BaseRoot.ObjectType) -> void:
	pass

func get_object_info(uuid:UUID, object_type:BaseRoot.ObjectType) -> ObjectMeta:
	var response = await api_handler.make_request(
			HTTPClient.METHOD_GET, 
			OBJECT_INFO_ENDPOINT % [object_type, uuid], 
			PackedStringArray([account_handler.get_token_header()]))
	var result = api_handler.handle_response(response[0], response[2], [200, 404], 
			["name", "object_type", "description", "tags", "uuid", 
			"owner", "object_size_kb", "image_size_kb"])
