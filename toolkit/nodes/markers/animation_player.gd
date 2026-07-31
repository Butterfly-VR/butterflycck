@tool
extends CCKMarker
class_name CCKAnimationPlayer

@export_enum(" ") var animation:String

func _validate_property(property: Dictionary) -> void:
	if property.name == "animation":
		if get_child(0) is AnimationPlayer:
			property.hint = PROPERTY_HINT_ENUM
			
			var hint_string:String = ""
			for x in get_child(0).get_animation_list():
				hint_string += x
				hint_string += ","
			hint_string.trim_suffix(",")
			
			property.hint_string = hint_string

func prep_for_upload() -> bool:
	if get_child(0) is not AnimationPlayer:
		return false
	var player:AnimationPlayer = get_child(0)
	
	var values:Dictionary[String, Variant] = {}
	
	values["version"] = get_marker_version_string()
	
	var libraries:Dictionary[String, Dictionary] = {}
	for library in player.get_animation_library_list():
		libraries[library] = {}
	for library_animation in player.get_animation_list():
		for library in libraries.keys():
			if library_animation.split("/")[0] == library:
				libraries[library][library_animation] = player.get_animation(library_animation)
	values["libraries"] = libraries
	
	values["player_name"] = name
	values["animation"] = animation
	values["active"] = player.active
	values["playback_speed"] = player.speed_scale
	var target:Node = player.get_node(player.root_node)
	values["root_node"] = get_parent().get_path_to(target)
	
	get_parent().set_meta("CCKAnimationPlayer_%s" % name, values)
	
	queue_free()
	
	return true

func get_marker_version_string() -> String:
	return "1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	
	if (!get_child(0)) or get_child(0) is not AnimationPlayer:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Warning, 
				"CCKAnimationPlayer needs AnimationPlayer child", 
				"the player must be the first child of the CCKAnimationPlayer.", 
				self, false))
		return warnings
	
	var player:AnimationPlayer = get_child(0)
	
	for animation_name in player.get_animation_list():
		var animation = player.get_animation(animation_name)
		for i in range(0, animation.get_track_count()):
			if animation.track_get_type(i) == Animation.TrackType.TYPE_METHOD:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Method call animations not supported", 
						"Animations are not allowed to call methods but %s has a method call track" % animation_name, 
						player, false))
			if animation.track_get_type(i) == Animation.TrackType.TYPE_VALUE:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Property animations not supported", 
						"This may be supported in the future. offending animation: %s" % animation_name, 
						player, false))
			if animation.track_get_type(i) == Animation.TrackType.TYPE_ANIMATION:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Sub animations not supported", 
						"This may be supported in the future. offending animation: %s" % animation_name, 
						player, false))
		
	return warnings
