@tool
extends TabContainer
class_name PageSelector

func _on_upload_button_pressed() -> void:
	current_tab = 0


func _on_manage_button_pressed() -> void:
	current_tab = 1


func _on_settings_button_pressed() -> void:
	current_tab = 2

func go_to_upload_tab(selected_object:BaseRoot, default_image:FileAccess) -> void:
	current_tab = 3
