@tool
extends VBoxContainer
class_name EditorUploadMenu

const GIGABYTE: int = MEGABYTE * 1024
const MEGABYTE: int = KILOBYTE * 1024
const KILOBYTE: int = 1024

@export var uuid_text: Label
@export var size_text: Label
@export var creation_text: Label
@export var last_update_text: Label
@export var publicity_options: OptionButton
@export var license_options: OptionButton
@export var confirmation1: CheckBox
@export var confirmation2: CheckBox
@export var upload_button: Button

var object_size: int


func setup(
	uuid: UUID,
	root_pack: FileAccess,
	creation_time: String,
	last_update_time: String,
	publicity: int,
	license: int,
	custom_license: String = "",
) -> void:
	if uuid:
		uuid_text.text = uuid.to_string()

	object_size = root_pack.get_length()
	size_text.text = get_size_string(root_pack.get_length())

	creation_text.text = creation_time
	last_update_text.text = last_update_time

	publicity_options.select(publicity)
	license_options.select(license)


func get_size_string(size: int) -> String:
	if size > GIGABYTE:
		return "%.2f GB" % ((size as float) / GIGABYTE)
	elif size > MEGABYTE:
		return "%.2f MB" % ((size as float) / MEGABYTE)
	else:
		return "%.2f KB" % ((size as float) / KILOBYTE)
