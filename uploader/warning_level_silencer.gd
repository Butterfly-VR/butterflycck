@tool
extends OptionButton

@export var persistence_handler:EditorPersistanceHandler

func _ready() -> void:
	persistence_handler.register_value("settings", "settings", "minimum_warning_level", 0)

func _on_item_selected(index: int) -> void:
	persistence_handler.set_value("settings", "settings", "minimum_warning_level", index)
