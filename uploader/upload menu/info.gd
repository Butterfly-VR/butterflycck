@tool
extends VBoxContainer
class_name EditorInfoMenu

const GIGABYTE: int = MEGABYTE * 1024
const MEGABYTE: int = KILOBYTE * 1024
const KILOBYTE: int = 1024

@export var object_name: LineEdit
@export var image_display: TextureRect
@export var image_size: Label
@export var image_select: FileDialog
@export var description_box: TextEdit
@export var tag_manager: TagManager

var image_bytes: PackedByteArray


# preexisting_values allows intializing with the values aquired from the api,
# if this object already exists
# contains []
func setup(
	object_name: String,
	root_pack: FileAccess,
	current_image: Image,
	tags: PackedStringArray,
	description: String,
) -> void:
	self.object_name.text = object_name

	image_bytes = current_image.save_png_to_buffer()
	image_display.texture = ImageTexture.create_from_image(current_image)

	image_size.text = get_size_string(image_bytes.size())
	#upload_size.text = get_size_string(FileAccess.get_size(root_pack.get_path()))
	tag_manager.clear_tags()
	for tag: String in tags:
		tag_manager.add_tag(tag)

	description_box.text = description


func get_size_string(size: int) -> String:
	if size > GIGABYTE:
		return "%.2f GB" % ((size as float) / GIGABYTE)
	elif size > MEGABYTE:
		return "%.2f MB" % ((size as float) / MEGABYTE)
	else:
		return "%.2f KB" % ((size as float) / KILOBYTE)


func _on_image_upload_start() -> void:
	image_select.visible = true


func _on_image_selected(path: String) -> void:
	var new_image: Image = Image.new()
	var buffer: PackedByteArray = FileAccess.get_file_as_bytes(path)
	if new_image.load_png_from_buffer(buffer) == OK:
		image_bytes = buffer
		image_display.texture = ImageTexture.create_from_image(new_image)
		image_size.text = get_size_string(image_bytes.size())
	elif new_image.load_jpg_from_buffer(buffer) == OK:
		image_bytes = buffer
		image_display.texture = ImageTexture.create_from_image(new_image)
		image_size.text = get_size_string(image_bytes.size())
	elif new_image.load_webp_from_buffer(buffer) == OK:
		image_bytes = buffer
		image_display.texture = ImageTexture.create_from_image(new_image)
		image_size.text = get_size_string(image_bytes.size())
	else:
		push_error("failed to parse image file. must be png, jpg, or webp.")
