@tool
extends TabContainer
class_name UploadHandler

const OBJECT_INFO_ENDPOINT:String = "api/v0/%s/%s"
const OBJECT_DOWNLOAD_ENDPOINT:String = "api/v0/%s/%s/epck"
const OBJECT_IMAGE_ENDPOINT:String = "api/v0/%s/%s/image"
const GIGABYTE:int = MEGABYTE * 1024
const MEGABYTE:int = KILOBYTE * 1024
const KILOBYTE:int = 1024
const CUSTOM_LICENSE_TYPE:int = 3
const PCK_INTERNAL_PATH:String = "res://_loaded_content/%s/%s"

@export var api_handler:APIHandler
@export var account_handler:AccountHandler
@export var info_menu:InfoMenu
@export var upload_menu:UploadMenu

var object_file:FileAccess

var object_type:BaseRoot.ObjectType
var uuid:UUID
var object_owner:UUID

var object_key:PackedByteArray
var object_iv:PackedByteArray
var object_padding:int

class ObjectMeta:
	var name:String
	var object_type:BaseRoot.ObjectType
	var publicity:int
	var license:int
	var custom_license:String
	var description:String
	var tags:PackedStringArray
	var uuid:UUID
	var owner:UUID
	var object_size_KB:int
	var image_size_KB:int
	# image is used in the editor, image_bytes is used when uploading
	var image:Image
	var image_bytes:PackedByteArray
	
	var creation_time_utc:int
	var modified_time_utc:int

func change_stage(idx:int) -> void:
	current_tab = idx

func setup(root:BaseRoot, default_image:Image) -> void:
	var object:ObjectMeta = await get_object_info(root.attached_uuid, 
			root.get_object_type())
	
	if !object:
		object = await make_object(root, default_image)
	
	object_file = await create_finialized_file(root, object.uuid)
	
	object_type = object.object_type
	uuid = object.uuid
	object_owner = object.owner
	
	var creation_time_string:String
	if object.creation_time_utc == 0:
		creation_time_string = "Never"
	else:
		creation_time_string = Time.get_date_string_from_unix_time(
				object.creation_time_utc)
	
	var modified_time_string:String
	if object.modified_time_utc == 0:
		modified_time_string = "Never"
	else:
		modified_time_string = Time.get_date_string_from_unix_time(
				object.modified_time_utc)
	
	info_menu.setup(object.name, object_file, object.image, object.tags, 
			object.description)
	
	upload_menu.setup(object.uuid, object_file, creation_time_string, 
			modified_time_string, object.publicity, object.license, 
			object.custom_license)

# gets the set values from the upload menus
func collect_object_values() -> ObjectMeta:
	if !upload_menu.confirmation1.button_pressed:
		return null
	if !upload_menu.confirmation2.button_pressed:
		return null
	
	var object = ObjectMeta.new()
	object.name = info_menu.object_name.text
	object.object_type = object_type
	
	object.description = info_menu.description_box.text
	object.tags = info_menu.tag_manager.get_tags()
	
	object.uuid = uuid if uuid else UUID.new(true)
	object.owner = object_owner
	
	object.object_size_KB = upload_menu.object_size_kb / 1000
	object.image_size_KB = info_menu.image_bytes.size() / 1000
	
	object.publicity = upload_menu.publicity_options.get_selected_id()
	object.license = upload_menu.license_options.get_selected_id()
	
	if object.license == 3:
		pass # todo: custom licenses
	
	object.creation_time_utc = upload_menu.creation_text.text
	object.modified_time_utc = upload_menu.last_update_text.text
	
	object.image_bytes = info_menu.image_bytes
	return object

func upload() -> void:
	var object = collect_object_values()
	
	# todo: dont send unchanged object data? maybe keep remote object to compare
	var upload_values:Dictionary[String, Variant] = {
		"name":object.name,
		"publicity":object.publicity,
		"license":object.license,
		"description":object.description,
		"tags":object.tags,
	}
	
	if object.license == 3:
		upload_values["custom_license"] = object.custom_license
	
	var response = await api_handler.make_request(
			HTTPClient.METHOD_POST, 
			OBJECT_INFO_ENDPOINT % [object.object_type, object.uuid],
			PackedStringArray([account_handler.get_token_header()]),
			JSON.stringify(upload_values))
	
	if response[0] != 200:
		return # todo: error handling
	
	var blob_uploader:HTTPRequest = HTTPRequest.new()
	add_child(blob_uploader)
	blob_uploader.request_raw(OBJECT_IMAGE_ENDPOINT, 
			PackedStringArray([account_handler.get_token_header()]),
			HTTPClient.METHOD_POST, object.image_bytes)
	
	response = await blob_uploader.request_completed
	# todo: error handling
	
	object_file.seek(0)
	
	blob_uploader.request_raw(OBJECT_DOWNLOAD_ENDPOINT, 
			PackedStringArray([account_handler.get_token_header()]),
			HTTPClient.METHOD_POST, 
			object_file.get_buffer(object_file.get_length()))
	
	response = await blob_uploader.request_completed
	# todo: error handling
	
	print("upload completed!")

func test_locally() -> void:
	var object = collect_object_values()
	
	var test_file:FileAccess = FileAccess.create_temp(FileAccess.WRITE_READ, 
			"remote-object", ".cfg", true)
	
	test_file.store_line("type: %s" % object_type)
	test_file.store_line("object path: %s" % object_file.get_path_absolute())
	test_file.store_line("key: %s" % object_key)
	test_file.store_line("iv: %s" % object_iv)
	
	test_file.flush()
	
	OS.create_instance(PackedStringArray(
			["--object_override=%s" % test_file.get_path()]))
	
	print("starting game...")

func create_finialized_file(root:BaseRoot, uuid:UUID) -> FileAccess:
	var internal_path = PCK_INTERNAL_PATH % [root.get_object_type(), uuid]
	
	root.on_pre_upload()
	
	# post-prep, since the root isnt included in the file all nodes 
	# need their owner set to the new root node
	await get_tree().physics_frame
	SceneTreeHelper.call_children_recursive(
			root.get_child(0), 
			func(x:Node) -> bool: 
				x.owner = root.get_child(0) 
				return true)
	
	var pack:PackedScene = PackedScene.new()
	pack.pack(root.get_child(0))
	
	var path:String = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "scene_tmp", ".tscn", true).get_path()
	
	ResourceSaver.save(pack, path, 2 + 4 + 8 + 32 + 64)
	
	var pck_path:String = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "upload_tmp", ".pck", true).get_path()
	var pck := PCKPacker.new()
	pck.pck_start(pck_path)
	
	var scene_file:FileAccess = FileAccess.open(path, FileAccess.READ)
	for line in scene_file.get_as_text(true).split("\n"):
		if line.begins_with("load_path = \""):
			var dependancy_path:String = line.trim_prefix(
					"load_path = \"").trim_suffix("\"")
			pck.add_file(dependancy_path, dependancy_path)
	
	scene_file.close()
	
	pck.add_file(internal_path, path)
	
	pck.flush()
	
	# todo: this requires 2 copies of the object in memory
	# one in pack_bytes, the other created by compress
	# dont think theres a streaming solution in godot so probably need a rust module
	var pack_bytes:PackedByteArray = FileAccess.get_file_as_bytes(pck_path)
	
	var unencrypted:FileAccess = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "compressed_pck", ".tmp")
	
	unencrypted.store_buffer(pack_bytes.compress(
			FileAccess.CompressionMode.COMPRESSION_ZSTD))
	
	unencrypted.seek(0)
	pack_bytes = PackedByteArray()
	
	var encrypted:FileAccess = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "final_tmp", ".epck")
	
	var crypto := Crypto.new()
	object_key = crypto.generate_random_bytes(32)
	object_iv = crypto.generate_random_bytes(16)
	
	var aes:AESContext = AESContext.new()
	aes.start(AESContext.MODE_CBC_ENCRYPT, object_key, object_iv)
	
	while unencrypted.get_position() + 16 < unencrypted.get_length():
		encrypted.store_buffer(aes.update(unencrypted.get_buffer(16)))
	
	var final_segment = unencrypted.get_buffer(
			unencrypted.get_length() - unencrypted.get_position())
	
	object_padding = 0
	while final_segment.size() < 16:
		final_segment.push_back(0)
		object_padding += 1
	
	encrypted.store_buffer(aes.update(final_segment))
	
	encrypted.seek(0)
	
	# cleanup temporary files we couldnt delete automatically
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(pck_path)
	
	return encrypted

func make_object(root:BaseRoot, image:Image) -> ObjectMeta:
	var object:ObjectMeta = ObjectMeta.new()
	
	object.name = root.object_name if root.object_name else root.name
	object.object_type = root.get_object_type()
	
	object.description = ""
	object.tags = PackedStringArray()
	
	object.uuid = null
	object.owner = await account_handler.get_uuid()
	
	object.object_size_KB = 0
	object.image_size_KB = 0
	
	object.publicity = 0
	object.license = 0
	
	object.creation_time_utc = 0
	object.modified_time_utc = 0
	
	object.image = image
	
	return object

func get_object_info(uuid:UUID, object_type:BaseRoot.ObjectType) -> ObjectMeta:
	if !uuid:
		return null
	
	var response = await api_handler.make_request(
			HTTPClient.METHOD_GET, 
			OBJECT_INFO_ENDPOINT % [object_type, uuid], 
			PackedStringArray([account_handler.get_token_header()]))
	var result = api_handler.handle_response(response[0], response[2], [200], 
			["name", "object_type", "description", "tags", "uuid", 
			"owner", "object_size_kb", "image_size_kb", "publicity", 
			"license", "creation_time_utc", "modified_time_utc"])
	
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
	
	object.publicity = result[4][8]
	object.license = result[4][9]
	
	object.creation_time_utc = result[4][10]
	object.modified_time_utc = result[4][11]
	
	if object.license == 3 and ("custom_license" in response[2]):
		object.custom_license = response[2]["custom_license"]
	
	object.image = Image.new()
	
	var bytes:PackedByteArray = (await api_handler.make_request(HTTPClient.METHOD_GET, 
			OBJECT_IMAGE_ENDPOINT % [object_type, uuid], 
			PackedStringArray([account_handler.get_token_header()])))[2] as PackedByteArray
	
	if object.image.load_png_from_buffer(bytes) != OK:
		if object.image.load_webp_from_buffer(bytes) != OK:
			if object.image.load_jpg_from_buffer(bytes) != OK:
				push_error("failed to parse response image")
	
	return object
