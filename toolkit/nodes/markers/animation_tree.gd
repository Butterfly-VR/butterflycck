@tool
extends CCKMarker
## A safe wrapper around a regular [AnimationTree].
##
## In Godot an [AnimationTree] state machine can contain arbitrary code using the advance expression feature. To avoid this 
## and the possibility of modifying arbitrary properties using animations both [AnimationTree]s and [AnimationPlayer]s must be
## wrapped in cck markers in order to be safe to upload. To use this node you should add your [AnimationTree] as the first
## child of this node. All properties from the child [AnimationTree] will be preserved and the [AnimationTree] on the client
## will inherit the name and path of this node.
class_name CCKAnimationTree

var tree_parse_failed:bool = false
var parse_fail_message:String = ""

func prep_for_upload() -> bool:
	if get_child(0) is not AnimationTree:
		return false
	var values:Dictionary[String, Variant] = {}
	
	var tree:AnimationTree = get_child(0)
	var player:AnimationPlayer = tree.get_node(tree.anim_player)
	
	values["version"] = get_marker_version_string()
	values["name"] = name
	
	values["active"] = tree.active
	
	var target:Node = tree.get_node(tree.root_node)
	values["root_node"] = get_parent().get_path_to(target)
	
	if !tree.tree_root:
		return false
	var root:AnimationRootNode = tree.tree_root
	
	tree_parse_failed = false
	var anim_tree_data:Dictionary[String, Variant] = get_anim_node_data(root)
	if tree_parse_failed:
		return false
	values["tree_data"] = anim_tree_data
	
	var libraries:Dictionary[String, Dictionary] = {}
	for library in player.get_animation_library_list():
		libraries[library] = {}
	for library_animation in player.get_animation_list():
		for library in libraries.keys():
			if library_animation.split("/")[0] == library:
				libraries[library][library_animation] = player.get_animation(library_animation)
	values["libraries"] = libraries
	
	var parameters:Dictionary[String, Variant] = {}
	for property in tree.get_property_list():
		var property_name:String = property["name"]
		if !property_name.begins_with("parameters"):
			continue
		if property_name.ends_with("playback"):
			continue
		parameters[property_name.trim_prefix("parameters/")] = tree.get(property_name)
	values["parameters"] = parameters
	
	get_parent().set_meta("CCKAnimationTree_%s" % name, values)
	
	player.queue_free()
	queue_free()
	
	return true

func get_anim_node_data(untyped_node:AnimationRootNode) -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	if untyped_node is AnimationNodeAnimation:
		var node:AnimationNodeAnimation = untyped_node
		values["type"] = "AnimationNodeAnimation"
		values["advance_on_start"] = node.advance_on_start
		values["animation"] = node.animation
		values["loop_mode"] = node.loop_mode as int
		values["play_mode"] = node.play_mode as int
		values["start_offset"] = node.start_offset
		values["stretch_time_scale"] = node.stretch_time_scale
		values["timeline_length"] = node.timeline_length
		values["use_custom_timeline"] = node.use_custom_timeline
	
	elif untyped_node is AnimationNodeBlendSpace1D:
		var node:AnimationNodeBlendSpace1D = untyped_node
		values["type"] = "AnimationNodeBlendSpace1D"
		values["blend_mode"] = node.blend_mode as int
		values["max_space"] = node.max_space
		values["min_space"] = node.min_space
		values["snap"] = node.snap
		values["sync"] = node.sync
		values["value_label"] = node.value_label
		
		var blend_point_positions:Array[float] = []
		var blend_points_data:Array[Dictionary] = []
		
		for index:int in range(0, node.get_blend_point_count()):
			blend_point_positions.push_back(node.get_blend_point_position(index))
			blend_points_data.push_back(get_anim_node_data(node.get_blend_point_node(index)))
		
		values["blend_point_positions"] = blend_point_positions
		values["blend_point_nodes"] = blend_points_data
	
	elif untyped_node is AnimationNodeBlendSpace2D:
		var node:AnimationNodeBlendSpace2D = untyped_node
		values["type"] = "AnimationNodeBlendSpace2D"
		values["auto_triangles"] = node.auto_triangles
		values["blend_mode"] = node.blend_mode as int
		values["max_space"] = node.max_space
		values["min_space"] = node.min_space
		values["snap"] = node.snap
		values["sync"] = node.sync
		values["x_label"] = node.x_label
		values["y_label"] = node.y_label
		
		var blend_point_positions:Array[Vector2] = []
		var blend_points_data:Array[Dictionary] = []
		var triangles_point_indexes:Array[Array] = []
		
		for index:int in range(0, node.get_blend_point_count()):
			blend_point_positions.push_back(node.get_blend_point_position(index))
			blend_points_data.push_back(get_anim_node_data(node.get_blend_point_node(index)))
		
		for index:int in range(0, node.get_triangle_count()):
			var triangle_point_indexes:Array[int] = []
			for point in range(0, 3):
				triangle_point_indexes.push_back(node.get_triangle_point(index, point))
			
			triangles_point_indexes.push_back(triangle_point_indexes)
		
		values["blend_point_positions"] = blend_point_positions
		values["blend_point_nodes"] = blend_points_data
		values["triangles_point_indexes"] = triangles_point_indexes
	
	elif untyped_node is AnimationNodeBlendTree:
		var node:AnimationNodeBlendTree = untyped_node
		values["type"] = "AnimationNodeBlendTree"
		
		var sub_nodes:Dictionary[String, Dictionary] = {}
		var node_positions:Dictionary[String, Vector2] = {}
		
		for node_name:String in node.get_node_list():
			node_positions[node_name] = node.get_node_position(node_name)
			var sub_node:AnimationNode = node.get_node(node_name)
			sub_nodes[node_name] = get_blend_tree_node_data(sub_node)
		
		values["nodes"] = sub_nodes
		values["positions"] = node_positions
	
	elif untyped_node is AnimationNodeStateMachine:
		var node:AnimationNodeStateMachine = untyped_node
		values["type"] = "AnimationNodeStateMachine"
		values["allow_transition_to_self"] = node.allow_transition_to_self
		values["reset_ends"] = node.reset_ends
		values["state_machine_type"] = node.state_machine_type as int
		
		var nodes:Dictionary[String, Dictionary] = {}
		var node_positions:Dictionary[String, Vector2]
		var transitions:Array[Dictionary] = []
		
		for node_name in node.get_node_list():
			var sub_node:AnimationRootNode = node.get_node(node_name) as AnimationRootNode
			nodes[node_name] = get_anim_node_data(sub_node)
			node_positions[node_name] = node.get_node_position(node_name)
		
		for index:int in range(0, node.get_transition_count()):
			var data:Dictionary[String, Variant] = {}
			var transition:AnimationNodeStateMachineTransition = node.get_transition(index)
			
			if transition.advance_mode == 0:
				continue
			
			data["break_loop_at_end"] = transition.break_loop_at_end
			data["priority"] = transition.priority
			data["reset"] = transition.reset
			data["switch_mode"] = transition.switch_mode as int
			data["xfade_curve"] = parse_curve(transition.xfade_curve)
			data["xfade_time"] = transition.xfade_time
			data["auto_transition"] = transition.advance_mode == 2
			data["source"] = node.get_transition_from(index)
			data["target"] = node.get_transition_to(index)
			
			transitions.push_back(data)
		
		values["nodes"] = nodes
		values["node_positions"] = node_positions
		values["transitions"] = transitions
	
	# for some reason these classes arnt available as types in the editor
	# so we match on the class name instead
	elif untyped_node.get_class() == "AnimationNodeEndState":
		values["type"] = "AnimationNodeEndState"
	elif untyped_node.get_class() == "AnimationNodeStartState":
		values["type"] = "AnimationNodeStartState"
	else:
		push_error("unhandled AnimationTree node: %s" % untyped_node.get_class())
	
	return values

func get_blend_tree_node_data(untyped_node:AnimationNode) -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	var inputs:Array[String] = []
	for index:int in range(0, untyped_node.get_input_count()):
		inputs.push_back(untyped_node.get_input_name(index))
	values["inputs"] = inputs
	
	if untyped_node is AnimationNodeOutput:
		values["type"] = "AnimationNodeOutput"
	elif untyped_node is AnimationNodeTimeScale:
		values["type"] = "AnimationNodeTimeScale"
	elif untyped_node is AnimationNodeTimeSeek:
		var node:AnimationNodeTimeSeek = untyped_node
		values["type"] = "AnimationNodeTimeSeek"
		values["explicit_elapse"] = node.explicit_elapse
	elif untyped_node is AnimationNodeAdd2:
		values["type"] = "AnimationNodeAdd2"
	elif untyped_node is AnimationNodeAdd3:
		values["type"] = "AnimationNodeAdd3"
	elif untyped_node is AnimationNodeBlend2:
		values["type"] = "AnimationNodeBlend2"
	elif untyped_node is AnimationNodeBlend3:
		values["type"] = "AnimationNodeBlend3"
	elif untyped_node is AnimationNodeOneShot:
		values["type"] = "AnimationNodeOneShot"
		var node:AnimationNodeOneShot = untyped_node
		values["abort_on_reset"] = node.abort_on_reset
		values["autorestart"] = node.autorestart
		values["autorestart_delay"] = node.autorestart_delay
		values["autorestart_random_delay"] = node.autorestart_random_delay
		values["break_loop_at_end"] = node.break_loop_at_end
		values["fadein_curve"] = parse_curve(node.fadein_curve)
		values["fadein_time"] = node.fadein_time
		values["fadeout_curve"] = parse_curve(node.fadeout_curve)
		values["fadeout_time"] = node.fadeout_time
		values["mix_mode"] = node.mix_mode as int
	elif untyped_node is AnimationNodeSub2:
		values["type"] = "AnimationNodeSub2"
	elif untyped_node is AnimationNodeTransition:
		values["type"] = "AnimationNodeTransition"
		var node:AnimationNodeTransition = untyped_node
		values["allow_transition_to_self"] = node.allow_transition_to_self
		values["input_count"] = node.input_count
		values["xfade_curve"] = parse_curve(node.xfade_curve)
		values["xfade_time"] = node.xfade_time
		var auto_advance_input_toggles:Array[bool] = []
		var reset_input_toggles:Array[bool] = []
		var loop_broken_at_end_input_toggles:Array[bool] = []
		for index in range(0, node.input_count):
			auto_advance_input_toggles.push_back(node.is_input_set_as_auto_advance(index))
			reset_input_toggles.push_back(node.is_input_reset(index))
			loop_broken_at_end_input_toggles.push_back(node.is_input_loop_broken_at_end(index))
		values["auto_advance_input_toggles"] = auto_advance_input_toggles
		values["reset_input_toggles"] = reset_input_toggles
		values["loop_broken_at_end_input_toggles"] = loop_broken_at_end_input_toggles
	elif is_instance_of(untyped_node, AnimationRootNode):
		values.merge(get_anim_node_data(untyped_node as AnimationRootNode))
	else:
		push_error("unhandled blendtree node: %s" % untyped_node.get_class())
	return values

func parse_curve(curve:Curve) -> Dictionary[String, Variant]:
	if !curve:
		return {}
	var values:Dictionary[String, Variant] = {}
	values["bake_resolution"] = curve.bake_resolution
	values["max_domain"] = curve.max_domain
	values["max_value"] = curve.max_value
	values["min_domain"] = curve.min_domain
	values["min_value"] = curve.min_value
	var points:Array[Dictionary] = []
	for index:int in range(0, curve.point_count):
		var point:Dictionary[String, Variant] = {}
		point["position"] = curve.get_point_position(index)
		point["left_mode"] = curve.get_point_left_mode(index) as int
		point["left_tangent"] = curve.get_point_left_tangent(index)
		point["right_mode"] = curve.get_point_right_mode(index) as int
		point["right_tangent"] = curve.get_point_right_tangent(index)
		points.push_back(point)
	values["points"] = points
	return values

func get_concatenated_state_machine_paths() -> String:
	if get_child(0) is not AnimationTree:
		return " "
	
	var root:AnimationRootNode = (get_child(0) as AnimationTree).tree_root
	
	var result:String = get_concatenated_state_machine_paths_recursive("ROOT", root)
	
	result = result.trim_suffix(",")
	return result

func get_concatenated_state_machine_paths_recursive(path:String, root:AnimationNode) -> String:
	var result:String = ""
	if root is AnimationNodeStateMachine:
		result = path + ","
		
		for node_name in root.get_node_list():
			var new_path:String = path + "/N%s" % node_name
			var node:AnimationNode = root.get_node(node_name)
			result += get_concatenated_state_machine_paths_recursive(new_path, node)
	
	elif root is AnimationNodeBlendSpace1D:
		for idx in root.get_blend_point_count():
			var new_path:String = path + "/I%s" % idx
			var node:AnimationNode = root.get_blend_point_node(idx)
			result += get_concatenated_state_machine_paths_recursive(new_path, node)
	
	elif root is AnimationNodeBlendSpace2D:
		for idx in root.get_blend_point_count():
			var new_path:String = path + "/I%s" % idx
			var node:AnimationNode = root.get_blend_point_node(idx)
			result += get_concatenated_state_machine_paths_recursive(new_path, node)
	
	elif root is AnimationNodeBlendTree:
		for node_name in root.get_node_list():
			var new_path:String = path + "/N%s" % node_name
			var node:AnimationNode = root.get_node(node_name)
			result += get_concatenated_state_machine_paths_recursive(new_path, node)
	
	return result

func get_marker_version_string() -> String:
	return "1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	
	
	if (!get_child(0)) or get_child(0) is not AnimationTree:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"CCKAnimationTree must contain AnimationTree", 
			"This node is only meant as a safe wrapper around the AnimationTree for uploading. \
					The tree must also be the first child of this node.", 
			self, false))
		return warnings
	
	var tree:AnimationTree = get_child(0)
	if !tree.tree_root:
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"CCKAnimationTree has no root node", 
			"The inner AnimationTree must contain a tree of AnimationNodes to function.", 
			tree, false))
	
	if !tree.get_node_or_null(tree.anim_player):
		warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
			"CCKAnimationTree has no AnimationPlayer", 
			"An AnimationPlayer is required to provide a library of animations to the tree.", 
			tree, false))
		return warnings
	
	for animation_name in tree.get_node(tree.anim_player).get_animation_list():
		var animation:Animation = tree.get_node(tree.anim_player).get_animation(animation_name)
		for i in range(0, animation.get_track_count()):
			if animation.track_get_type(i) == Animation.TrackType.TYPE_METHOD:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Method call animations not supported", 
						"Animations are not allowed to call methods but %s has a method call track" % animation_name, 
						tree.get_node(tree.anim_player), false))
			if animation.track_get_type(i) == Animation.TrackType.TYPE_VALUE:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Property animations not supported", 
						"This may be supported in the future. offending animation: %s" % animation_name, 
						tree.get_node(tree.anim_player), false))
			if animation.track_get_type(i) == Animation.TrackType.TYPE_ANIMATION:
				warnings.append(BaseRoot.Warning.new(BaseRoot.Warning.WarningLevel.Error, 
						"Sub animations not supported", 
						"This may be supported in the future. offending animation: %s" % animation_name, 
						tree.get_node(tree.anim_player), false))
	
	return warnings
