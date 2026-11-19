@tool
extends Button

@export var target:Label

func _pressed() -> void:
	DisplayServer.clipboard_set(target.text)
