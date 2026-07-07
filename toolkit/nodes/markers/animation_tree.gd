@tool
extends CCKMarker
class_name CCKAnimationTree

var tree_parse_failed:bool = false
var parse_fail_message:String = ""

func prep_for_upload() -> bool:
	if get_child(0) is not AnimationTree:
		return false
	var values:Dictionary[String, Variant] = {}
	
	var tree:AnimationTree = get_child(0)
	var player:AnimationPlayer = tree.get_node(tree.anim_player)
	
	values["marker_version"] = get_marker_version_string()
	
	values["active"] = tree.active
	values["playback_speed"] = tree.speed_scale
	
	var target:Node = tree.get_node(tree.root_node)
	values["root_node"] = get_parent().get_path_to(target)
	
	var root:AnimationRootNode = tree.tree_root
	
	tree_parse_failed = false
	var anim_tree_data:String = JSON.stringify(get_anim_node_data(root))
	if tree_parse_failed:
		return false
	
	# add animationplayer
	# add info for parameters
	# make parameters overridable if extensions exist
	
	get_parent().set_meta("CCKAnimationTree_%s" % name, values)
	
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
		var blend_points_data:Array[String] = []
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
		var blend_points_data:Array[String] = []
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
	# state machine:
	# 	startstate
	# 	endstate
	# 	transitions
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
	# blend tree:
	# 	sync:
	# 		add2
	# 		add3
	# 		blend2
	# 		blend3
	# 		oneshot
	# 		sub2
	# 		transition
	return values

func get_marker_version_string() -> String:
	return "1"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = []
	
	return warnings
