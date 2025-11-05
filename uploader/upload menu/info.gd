@tool
extends VBoxContainer

const GIGABYTE:int = MEGABYTE * 1024
const MEGABYTE:int = KILOBYTE * 1024
const KILOBYTE:int = 1024

@export var object_name:LineEdit
@export var uuid:Button
@export var upload_size:Label
@export var image_display:TextureRect
@export var image_size:Label
@export var last_update_time:Label
@export var image_select:FileDialog

var object_file:FileAccess
var image:Image

# preexisting_values allows intializing with the values aquired from the api, 
# if this object already exists
# contains []
func setup(root:BaseRoot, current_image:Image, upload_name:String, last_update_string:String) -> void:
	if upload_name:
		object_name.text = upload_name
	elif root.object_name:
		object_name.text = root.object_name
	else:
		object_name.text = root.name
	
	root.uuid = root.uuid if root.uuid else UUID.new(true)
	uuid.text = root.uuid
	
	image = current_image
	image_display.texture = ImageTexture.create_from_image(current_image)
	
	object_file = create_object_file(root)
	
	image_size.text = get_size_string(current_image.get_data_size())
	upload_size.text = get_size_string(FileAccess.get_size(object_file.get_path()))
	
	last_update_time.text = last_update_string

func get_size_string(size:int) -> String:
	if size > GIGABYTE:
		return "%.2f GB" % (size as float / MEGABYTE)
	elif size > MEGABYTE:
		return "%.2f MB" % (size as float / GIGABYTE)
	else:
		return "%.2f KB" % (size as float / KILOBYTE)

func create_object_file(root:BaseRoot) -> FileAccess:
	# this is kinda messy we just need a random file name to save the scene to temporarily
	var path = FileAccess.create_temp(
			FileAccess.ModeFlags.WRITE_READ, "%s" % root.uuid, ".pck", true).get_path()
	var scene:PackedScene = PackedScene.new()
	match scene.pack(root):
		OK:
			ResourceSaver.save(scene, path, 
					ResourceSaver.FLAG_BUNDLE_RESOURCES + ResourceSaver.FLAG_OMIT_EDITOR_PROPERTIES +
					ResourceSaver.FLAG_COMPRESS + ResourceSaver.FLAG_CHANGE_PATH)
		var err:
			push_error("failed to save scene to temp file: %s." % err)
	return FileAccess.open(path, FileAccess.READ)

func _on_uuid_randomize() -> void:
	uuid.text = UUID.new(true).to_string()


func _on_image_upload_start() -> void:
	image_select.visible = true


func _on_image_selected(path: String) -> void:
	var new_image:Image = Image.new()
	var buffer:PackedByteArray = FileAccess.get_file_as_bytes(path)
	if new_image.load_png_from_buffer(buffer) == OK:
		image = new_image
		image_display.texture = ImageTexture.create_from_image(image)
		image_size.text = get_size_string(image.get_data_size())
	elif new_image.load_jpg_from_buffer(buffer) == OK:
		image = new_image
		image_display.texture = ImageTexture.create_from_image(image)
		image_size.text = get_size_string(image.get_data_size())
	elif new_image.load_webp_from_buffer(buffer) == OK:
		image = new_image
		image_display.texture = ImageTexture.create_from_image(image)
		image_size.text = get_size_string(image.get_data_size())
	else:
		push_error("failed to parse image file. must be png, jpg, or webp.")
