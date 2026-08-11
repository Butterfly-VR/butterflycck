@tool
extends CCKAction
## When triggered, changes the animation of the target CCKAnimationPlayer
class_name AnimationSetAction

## the target CCKAnimationPlayer
@export var target:CCKAnimationPlayer:
	set(x):
		target = x
		notify_property_list_changed()
## Determines which animation will play when triggered. If set to "From Parameter", 
## the first parameter will be used as the name of the target animation. Does nothing
## if the first parameter is not a String or is not the name of an animation
@export_enum("From Parameter") var animation:String

func _validate_property(property: Dictionary) -> void:
	if property.name == "animation" and target:
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		
		var player:AnimationPlayer = target.get_child(0)
		
		var result:String = "From Parameter,"
		for animation in player.get_animation_list():
			result += animation + ","
		
		property.hint_string = result.trim_suffix(",")

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	values["target"] = get_parent().get_path_to(target)
	if animation != "From Parameter":
		values["animation"] = animation
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "AnimationSetAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if !target:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"AnimationSetAction has no target", 
			"The Target should be the AnimationPlayer to set the animation for.", 
			self, false))
	
	if animation.is_empty():
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"AnimationSetAction has no animation", 
			"The animation parameter should be set to the target animation or to 'From Parameter' \
			to take a parameter as the target path.", 
			self, false))
	
	return warnings
