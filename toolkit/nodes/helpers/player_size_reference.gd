@tool
extends Node3D
## A visual guide showing the default size of the player's capsule collider.
##
## This is mainly useful for correctly scaling objects in worlds or other uploads.
## This node will be removed when uploading
class_name PlayerSizeReference

func _ready() -> void:
	add_child(InnerPlayerSizeReference.new())
	set_script(null)

class InnerPlayerSizeReference extends CCKMarker:
	func _process(delta: float) -> void:
		var target:Node3D = get_parent()
		
		var position:Vector3 = (target as Node3D).global_position
		position.y += 0.9
		
		DebugDraw3D.draw_capsule(
				position, Quaternion.IDENTITY, 0.25, 1.8)

	func get_uploader_warnings() -> Array[BaseRoot.Warning]:
		return []

	func prep_for_upload() -> bool:
		get_parent().queue_free()
		
		return true

	func get_marker_version_string() -> String:
		return "1"
