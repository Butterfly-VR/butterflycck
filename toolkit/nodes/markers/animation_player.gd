@tool
extends CCKMarker
class_name CCKAnimationPlayer

@export_enum(" ") var animation:String
@export var active:bool = true
@export_range(-5, 5, 0.1) var playback_speed:float = 1.0

func _validate_property(property: Dictionary) -> void:
	if property.name == "animation":
		if get_child(0) is AnimationPlayer:
			property.hint = PROPERTY_HINT_ENUM
			property.hint_string = get_child(0).get_animation_list()

func prep_for_upload() -> bool:
	if get_child(0) is not AnimationPlayer:
		return false
	var values:Dictionary[String, Variant] = {}
	
	values["marker_version"] = get_marker_version_string()
	
	values["animation"] = get_child(0).get_animation(animation)
	values["active"] = active
	values["playerback_speed"] = playback_speed
	
	get_parent().set_meta("CCKAnimationPlayer:%s" % name, values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	if get_child(0) is not AnimationPlayer:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"CCKAnimationPlayer needs AnimationPlayer child", 
				"the player must be the first child of the CCKAnimationPlayer.", 
				self, false))
		return warnings
	
	var animation:Animation = get_child(0).get_animation(animation)
	
	for i in range(0, animation.get_track_count()):
		if animation.track_get_type(i) == Animation.TrackType.TYPE_METHOD:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
					"Method call animations not supported", 
					"animations are not allowed to call methods", 
					self, false))
		if animation.track_get_type(i) == Animation.TrackType.TYPE_VALUE:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
					"Property animations not supported", 
					"this may be supported in the future", 
					self, false))
		if animation.track_get_type(i) == Animation.TrackType.TYPE_ANIMATION:
			warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
					"Sub animations not supported", 
					"this may be supported in the future", 
					self, false))
	
	return warnings
