@tool
extends BaseRoot
## Root node for avatars.
##
## An avatar should generally contain an [IKController] marker as well
## as an [AvatarColliderConfig] marker.
class_name AvatarRoot

class WarningCallState:
	var collider_settings_found:int = 0
	var ik_controllers_found:int = 0
	var has_animator:bool = false
	var last_collider_setting:AvatarColliderConfig = null
	var last_ik_controller:IKController = null

## Returns [constant BaseRoot.ObjectType.avatar].
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
					if x is IKController:
						state.ik_controllers_found += 1
						state.last_ik_controller = x as IKController
					if x is CCKAnimationPlayer or x is CCKAnimationTree:
						state.has_animator = true
					return false
				return true, 
				true)
	
	if state.collider_settings_found == 0:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar missing collider config", 
				"An avatar should have a collider config node as a child to control \
						the size of the avatar's collider. The default collider is 
						based on the Avatar's AABB which may be too big.", 
				self, false))
	if state.collider_settings_found > 1:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar has multiple collider configs", 
				"Only one of the configs will be applied in-game.", 
				state.last_collider_setting, false))
	
	if state.ik_controllers_found == 0:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar missing IK controller", 
				"Without an IKController IK animations (such as following the \
						players view in desktop or vr) will not work.", 
				self, false))
	if state.ik_controllers_found > 1:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"Avatar has multiple IK controllers", 
				"Only one of the IK controllers will be applied in-game.", 
				state.last_ik_controller, false))
	
	if !state.has_animator:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Info, 
				"Avatar missing animator", 
				"No CCKAnimationPlayer or CCKAnimationTree was found as a child of \
						this avatar. Without one, this avatar will only be animated by IK.", 
				self, false))
	
	return warnings
