@tool
extends TabContainer
class_name UploadHandler

const OBJECT_INFO_ENDPOINT:String = "api/v0/%s/%s"
const OBJECT_IMAGE_ENDPOINT:String = "api/v0/%s/%s/image"

@export var api_handler:APIHandler
@export var account_handler:AccountHandler
@export var info_menu:InfoMenu

class ObjectMeta:
	var name:String
	var object_type:BaseRoot.ObjectType
	var description:String
	var tags:Array[String]
	var uuid:UUID
	var owner:UUID
	var object_size_KB:int
	var image_size_KB:int
	var image:Image

func change_stage(idx:int) -> void:
	current_tab = idx

func setup(root:BaseRoot, default_image:Image) -> void:
	var object:ObjectMeta = await get_object_info(root.attached_uuid, root.get_object_type())
	if object:
		root.object_name = object.name
		root.uuid = object.uuid.to_string()
		info_menu.setup(root, create_finialized_file(root), object.image, object.name, 
				object.tags, object.description)
	else:
		info_menu.setup(root, create_finialized_file(root), default_image, "never", 
				PackedStringArray(), "")

func upload() -> void:
	print("upload started")

func test_locally() -> void:
	print("test started")

func create_finialized_file(root:BaseRoot) -> FileAccess:
	root.on_pre_upload()
	var pack:PackedScene = PackedScene.new()
	pack.pack(root.get_child(0))
	var path:String = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "upload_tmp", ".pck", true).get_path()
	ResourceSaver.save(pack, path, 2 + 4 + 8 + 32)
	return FileAccess.open(path, FileAccess.READ)

func get_object_info(uuid:UUID, object_type:BaseRoot.ObjectType) -> ObjectMeta:
	if !uuid:
		return null
	var response = await api_handler.make_request(
			HTTPClient.METHOD_GET, 
			OBJECT_INFO_ENDPOINT % [object_type, uuid], 
			PackedStringArray([account_handler.get_token_header()]))
	var result = api_handler.handle_response(response[0], response[2], [200], 
			["name", "object_type", "description", "tags", "uuid", 
			"owner", "object_size_kb", "image_size_kb"])
	if !result[0]:
		return null
	if UUID.from_String(result[4][5]) != await account_handler.get_uuid():
		return null
	var object:ObjectMeta = ObjectMeta.new()
	object.name = result[4][0]
	object.object_type = result[4][1]
	object.description = result[4][2]
	object.tags = PackedStringArray(result[4][3])
	object.uuid = UUID.from_String(result[4][4])
	object.owner = UUID.from_String(result[4][5])
	object.object_size_KB = result[4][6]
	object.image_size_KB = result[4][7]
	object.image = Image.new()
	var bytes:PackedByteArray = (await api_handler.make_request(HTTPClient.METHOD_GET, 
			OBJECT_IMAGE_ENDPOINT % [object_type, uuid], 
			PackedStringArray([account_handler.get_token_header()])))[2] as PackedByteArray
	if object.image.load_png_from_buffer(bytes) != OK:
		if object.image.load_webp_from_buffer(bytes) != OK:
			if object.image.load_jpg_from_buffer(bytes) != OK:
				push_error("failed to parse response image")
	return object
