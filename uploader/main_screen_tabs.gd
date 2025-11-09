@tool
extends TabContainer
class_name PageSelector

@export var button_section:HBoxContainer
@export var upload_handler:UploadHandler
@export var account_handler:AccountHandler

func _ready() -> void:
	if await account_handler.is_token_valid(
			account_handler.session_token, account_handler.token_expiry_utc):
		leave_token_entry()

func leave_token_entry() -> void:
	button_section.visible = true
	current_tab = 0

func enter_token_entry() -> void:
	button_section.visible = false
	current_tab = 4

func _on_upload_button_pressed() -> void:
	current_tab = 0


func _on_manage_button_pressed() -> void:
	current_tab = 1


func _on_settings_button_pressed() -> void:
	current_tab = 2

func go_to_upload_tab(selected_object:BaseRoot, default_image:Image) -> void:
	current_tab = 3
	upload_handler.setup(selected_object, default_image)
