@tool
extends OptionButton

@export var target:TextEdit

func _process(delta: float) -> void:
	if selected == 8:
		target.visible = true
	else:
		target.visible = false
