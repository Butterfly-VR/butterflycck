@tool
extends BaseRoot
## Root node for avatars.
##
## An avatar should generally contain an IKController marker as well
## as an AvatarColliderConfig marker.
class_name AvatarRoot

class WarningCallState:
	var collider_settings_found:int = 0
	var last_collider_setting:AvatarColliderConfig = null

## Returns [enum BaseRoot.ObjectType].avatar.
func get_object_type() -> ObjectType:
	return ObjectType.avatar

## Returns warnings specific to an avatar.
func get_base_class_warnings() -> Array[BaseRoot.Warning]:
	var state:WarningCallState = WarningCallState.new()
	
	var warnings:Array[BaseRoot.Warning] = []
	
	EditorSceneTreeHelper.call_children_recursive(
			self.get_child(0), 
			func(x:Node) -> bool:
				if x is CCKMarker:
					if x is AvatarColliderConfig:
						state.collider_settings_found += 1
						state.last_collider_setting = x as AvatarColliderConfig
					return false
				return true, 
				true)
	
	if state.collider_settings_found == 0:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar missing collider config", 
				"An avatar should have a collider config node as a child to control \
						the size of the avatar's collider. the default collider is based on the \
						Avatar's AABB which may be too big", 
				self, false))
	if state.collider_settings_found > 1:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar has multiple collider configs", 
				"Only one of the configs will be applied ingame", 
				state.last_collider_setting, false))
	
	return warnings
