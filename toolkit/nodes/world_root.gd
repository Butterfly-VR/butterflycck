@tool
extends BaseRoot
class_name WorldRoot

func get_object_type() -> ObjectType:
	return ObjectType.world

# transform is passed by value (technically CoW but whatever) but we need it passed by ref
# only way i know to do this is to wrap it in a class
class TransformWrapper:
	var transform:Transform3D

func get_spawnpoint_transform(node:Node, transform:TransformWrapper):
	if node is SpawnPoint:
		if node.get_parent() is Node3D:
			transform.transform = (node.get_parent() as Node3D).global_transform
	return true

# positions the preview camera so that it roughly shows the view of a newly spawned player
func get_preview_camera_transform() -> Transform3D:
	var spawn_tranform:TransformWrapper = TransformWrapper.new()
	EditorSceneTreeHelper.call_children_recursive(self, get_spawnpoint_transform.bind(spawn_tranform))
	if spawn_tranform.transform:
		spawn_tranform.transform.origin.y += 1.0
		return spawn_tranform.transform
	else:
		return Transform3D(Basis.IDENTITY, Vector3(0.0, 1.0, 0.0))

func get_base_class_warnings() -> Array[Warning]:
	return []
