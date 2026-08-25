@tool
@abstract
extends Node
## Base class for uploadable objects. Contains a UUID corresponding to
## the uploaded object, and a default name for it.
##
## To upload an object, you must create a node with one of the derived classes
## of this node and then create a single root node that is a child of that node.
## That root node should contain everything you want to upload.
## [br]
## Scripts are not allowed on any uploaded objects.
## [br][br]
## Tip: An [UploadSkipMarker] can contain nodes in the object you
## don't want uploaded, and will silence warnings related to them.
class_name BaseRoot

## List of types that are not allowed in any object.
var blacklisted_types: Array = [
	Window,
	EditorPlugin,
	HTTPRequest,
	MultiplayerSpawner,
	MultiplayerSynchronizer,
	StatusIndicator,
]

## The default name for this object. This is only used as a fallback; if the
## UUID assigned to this object matches an existing uploaded object, that
## object's existing name is shown in the upload menu instead.
@export var object_name: String
## The UUID of the object, as text. A valid UUID entered here will be applied
## automatically. If this is left empty or contains invalid text, you must
## press the [b]assign UUID[/b] button to generate a new one.
@export var _uuid: String

## Generates a new UUID if [member _uuid] is empty or invalid, or confirms
## the UUID currently entered in [member _uuid] otherwise.
@export_tool_button("assign UUID", "Callable") var assign_button = assign_uuid

## The actual [UUID] of the object. Kept in sync with [member _uuid] and
## generated automatically by [method assign_uuid]/[method try_assign_uuid].
@export_storage var attached_uuid: UUID

## The possible types of objects.
enum ObjectType {
	## A world, uploaded via [WorldRoot].
	world,
	## An avatar, uploaded via [AvatarRoot].
	avatar,
	## not yet implemented
	prop,
	## not yet implemented
	component,
}


class WarningState:
	var state: Array[Warning]


## A warning or error to be displayed in the upload panel for an object.
## Returned by [method CCKMarker.get_uploader_warnings], [method BaseRoot.get_base_class_warnings],
## and related functions.
class Warning:
	## The severity of a [Warning].
	enum WarningLevel {
		## An informational message. Does not indicate a problem and does not
		## prevent uploading.
		Info,
		## A likely misconfiguration. Does not prevent uploading, but may
		## result in unintended behavior.
		Warning,
		## A configuration error. Prevents the object from being uploaded.
		Error,
	}

	## The severity of this warning. See [enum WarningLevel].
	var level: WarningLevel
	## A short summary of the warning, shown in the warning list.
	var header: String
	## A detailed explanation of the warning and how to resolve it.
	var body: String
	## The node this warning applies to. Selected when the user clicks on
	## the warning in the upload panel.
	var source: Node
	## If true, the upload panel will offer a button that calls [member autofix].
	var has_autofix: bool = false
	## Called when the user clicks the autofix button, if [member has_autofix]
	## is true. Should return true if the fix succeeded.
	var autofix: Callable


	func _init(
		level: WarningLevel,
		header: String,
		body: String,
		source: Node,
		has_autofix: bool,
		autofix: Callable = Callable(),
	) -> void:
		self.level = level
		self.header = header
		self.body = body
		self.source = source
		if has_autofix:
			self.has_autofix = true
			self.autofix = autofix


## Retrieves the type of an object, will usually be a constant value.
@abstract func get_object_type() -> ObjectType ;


## Called by the assign UUID button. Sets [member attached_uuid] to the
## parsed value of [member _uuid], generating a new one if [member _uuid]
## is empty or invalid.
func assign_uuid() -> void:
	var new_uuid: UUID
	if _uuid.is_empty():
		new_uuid = UUID.new(true)
	else:
		new_uuid = UUID.from_String(_uuid)
		if !new_uuid:
			new_uuid = UUID.new(true)
	_uuid = new_uuid.to_string()
	attached_uuid = new_uuid


func try_assign_uuid() -> void:
	var new_uuid: UUID
	if _uuid.is_empty():
		return
	else:
		new_uuid = UUID.from_String(_uuid)
		if !new_uuid:
			return
	_uuid = new_uuid.to_string()
	attached_uuid = new_uuid


## Prepares the object and any [CCKMarker]s within it for uploading, and
## resets the root child node's position and rotation to zero.
## Returns false if an error occurred during preparation.
func on_pre_upload() -> bool:
	var success: bool = true
	EditorSceneTreeHelper.call_children_recursive(
		self.get_child(0),
		func(x: Node) -> bool:
			if x is CCKMarker:
				if !(x as CCKMarker).prep_for_upload():
					success = false
			return true,
	)

	if get_child(0) is Node3D:
		(get_child(0) as Node3D).position = Vector3.ZERO
		(get_child(0) as Node3D).rotation = Vector3.ZERO

	if !attached_uuid:
		attached_uuid = UUID.new(true)

	return success


## Helper function for getting warnings associated with a child node.
func get_child_warnings(node: Node, warnings: WarningState) -> bool:
	if node is CCKMarker:
		warnings.state.append_array((node as CCKMarker).get_uploader_warnings())
		return false
	else:
		if node.get_groups().any(
			func(group: StringName) -> bool:
				return !(group.begins_with("_") or group.begins_with("cck_")),
		):
			warnings.state.push_back(
				Warning.new(
					Warning.WarningLevel.Error,
					"Invalid group",
					"Group names used in an uploaded object must start with 'cck_' to prevent conflicts.",
					node,
					false,
				)
			)
		if blacklisted_types.any(
			func(blacklist_type) -> bool:
				return is_instance_of(node, blacklist_type),
		):
			warnings.state.push_back(
				Warning.new(
					Warning.WarningLevel.Error,
					"Blacklisted Type",
					"This object contains a node of type %s, which is not allowed." % \
							node.get_class(),
					node,
					true,
					func():
						node.queue_free()
						return true,
				)
			)
		if node.get_script() != null:
			warnings.state.push_back(
				Warning.new(
					Warning.WarningLevel.Error,
					"Node with script",
					"Scripts are currently not allowed on uploaded objects, \
							sandboxed scripting will be implemented in a future alpha build.",
					node,
					true,
					func():
						node.queue_free()
						return true,
				)
			)
	return true


## Retrieves warnings related to the root node itself, such as an incorrect
## number of children, a missing UUID, and the warnings from
## [method get_base_class_warnings].
func get_root_warnings() -> Array[Warning]:
	var warnings: Array[Warning] = []

	if get_child_count() == 0:
		warnings.append(
			Warning.new(
				Warning.WarningLevel.Error,
				"Object root requires a child",
				"The object you wish to upload must be the child of the BaseRoot node.",
				self,
				false,
			)
		)
		return warnings

	if get_child_count() > 1:
		warnings.append(
			Warning.new(
				Warning.WarningLevel.Error,
				"Multiple children on root",
				"Multiple children are not allowed on an object root, \
				consider adding another node and reparenting the children to it.",
				get_child(1),
				false,
			)
		)

	try_assign_uuid()
	if attached_uuid == null:
		warnings.append(
			Warning.new(
				Warning.WarningLevel.Error,
				"No UUID assigned",
				"Before uploading an object, you must click \"assign UUID\" to generate \
						an upload id for the object. This is due to a technical limitation \
						that may be fixed in the future.",
				self,
				false,
			)
		)

	warnings.append_array(get_base_class_warnings())

	return warnings


## Retrieves the list of warnings and errors for this object.
func get_upload_warnings() -> Array[Warning]:
	var warnings: WarningState = WarningState.new()

	warnings.state = get_root_warnings()

	if get_children().size() > 0:
		EditorSceneTreeHelper.call_children_recursive(
			get_child(0),
			get_child_warnings.bind(warnings),
		)

	return warnings.state


func _process(delta: float) -> void:
	update_configuration_warnings() # todo: this should be callled only when needed


# AABB is passed by value (technically CoW but whatever) but we need it passed by ref
# only way i know to do this is to wrap it in a class
class AABBRef:
	var is_init: bool = false
	var aabb: AABB


## Helper function for generating the preview image.
func get_combined_aabb(node: Node, buffer: AABBRef) -> bool:
	if node is VisualInstance3D:
		var aabb: AABB = (node as VisualInstance3D).get_aabb()
		aabb.position = (node as Node3D).to_global(aabb.position)
		if buffer.is_init:
			buffer.aabb = buffer.aabb.merge(aabb)
		else:
			buffer.aabb = aabb
			buffer.is_init = true

	return true


## Positions the camera for generating the preview image for an object.
## This default implementation positions the camera on the object's -Z side,
## facing back toward it along +Z, such that the entire [AABB] of the object
## is visible.
func get_preview_camera_transform() -> Transform3D:
	var camera: Camera3D = Camera3D.new()
	add_child(camera)
	var aabb_ref: AABBRef = AABBRef.new()
	EditorSceneTreeHelper.call_children_recursive(self, get_combined_aabb.bind(aabb_ref))
	var aabb: AABB = aabb_ref.aabb
	var pos: Vector3 = aabb.position + (aabb.size / 2)

	var candidate1: float = (
		(aabb.size.x / 2) / absf(tan(deg_to_rad(camera.get_camera_projection().get_fov() / 2)))
	) * 1.1
	var fovy: float = Projection.get_fovy(
		camera.get_camera_projection().get_fov() / 2,
		1 / camera.get_camera_projection().get_aspect(),
	)
	var candidate2: float = ((aabb.size.y / 2) / absf(tan(deg_to_rad(fovy / 2)))) * 1.1

	pos.z -= maxf(candidate1, candidate2)
	camera.queue_free()
	return Transform3D(Basis.IDENTITY.rotated(Vector3.UP, deg_to_rad(180)), pos)


func _get_configuration_warnings():
	var warnings: Array = get_root_warnings().map(
		func(x: Warning) -> String:
			return x.header,
	)

	return PackedStringArray(warnings)


## Retrieves the list of warnings for a specific object type.
@abstract
func get_base_class_warnings() -> Array[Warning]
