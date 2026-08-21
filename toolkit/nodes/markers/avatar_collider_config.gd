@tool
extends CCKMarker
## This marker tells the client how large the avatar's [CapsuleShape3D]-based
## collider should be.
##
## If this node is missing from an avatar the collider will be sized to the
## Avatar's [AABB].
## [br]
## In the client, the collider size is clamped between two values
## relative to the [AABB] of the avatar. This clamping behavior is currently not
## shown in the cck.
## [br][br]
## The capsule visualization is drawn relative to the position of this
## marker's parent, which must be a [Node3D]. The position may not be
## accurate if that parent is not the Avatar's root node.
## [br][br]
## IMPORTANT: Because of how the debug visualization is drawn, adding this node to a scene where
## the root node is an [AvatarRoot] or [WorldRoot] will result in a 'multiple children on root' error
## in the scene tree. This error will not appear in the uploader or prevent the object being uploaded.
## The error will disappear if you disable the visibility of the debug visual (see [member visible]).
class_name AvatarColliderConfig

## The radius of the collider. If this is greater than half the height, either
## the radius or the height will be clamped so that it is equal to half the height.
## Which value gets clamped is not specified.
@export var radius: float = 0.25
## The height of the collider. If this is less than double the radius, either
## the radius or the height will be clamped so that it is equal to half the height.
## Which value gets clamped is not specified.
@export var height: float = 1.8
## Offsets the collider from the center of the parent node. Limited to the bounds of the avatar's [AABB].
@export var offset: Vector3 = Vector3.ZERO
## If false, hides this marker's debug capsule visualization in the editor.
## Has no effect on the collider that is generated in-game.
@export var visible: bool = true


func _process(delta: float) -> void:
	if !visible:
		return
	var target: Node = get_parent()

	if target is not Node3D:
		return

	var position: Vector3 = (target as Node3D).global_position
	position.y += height / 2

	DebugDraw3D.draw_capsule(position + offset, Quaternion.IDENTITY, radius, height)


func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	if get_parent() is not Node3D:
		warnings.append(BaseRoot.Warning.new(
				BaseRoot.Warning.WarningLevel.Error,
				"Collider config must be child of Node3D.",
				"The parent node (+ the offset) determines where the Avatar's collider \
						will be positioned. the parent should be positioned between the
						avatar's feet.",
				self,
				false,
			))

	# todo: check sizeand offset are in valid bounds based on aabb
	return warnings


func prep_for_upload() -> bool:
	if get_parent() is not Node3D:
		return false

	var meta_values: Dictionary[String, Variant] = { }

	meta_values["version"] = get_marker_version_string()
	meta_values["radius"] = radius
	meta_values["height"] = height
	meta_values["offset"] = offset

	get_parent().set_meta("AvatarColliderConfig", meta_values)

	queue_free()

	return true


func get_marker_version_string() -> String:
	return "2"
