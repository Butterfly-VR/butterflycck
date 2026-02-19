extends Node
class_name SceneTreeHelper

class NodeStackItem:
	var node:Node
	var current_index:int = 0
	
	func get_next_child() -> NodeStackItem:
		if node.get_children().size() > current_index:
			var child = node.get_child(current_index)
			current_index += 1
			return NodeStackItem.new(child)
		return null
	
	func _init(node:Node) -> void:
		self.node = node

# callable should return a boolean
# if the callable is false then that nodes children are skipped
# todo: this feels kinda awkward with godot semantics maybe theres a better way?
static func call_children_recursive(root:Node, callable:Callable, run_on_root:bool = false) -> void:
	var node_stack:Array[NodeStackItem] = [NodeStackItem.new(root)]
	
	if run_on_root:
		callable.bind(root).call()
	
	while !node_stack.is_empty():
		# get the next unsearched node if it exists
		var next_node:NodeStackItem = node_stack[node_stack.size() - 1].get_next_child()
		
		if next_node:
			if callable.bind(next_node.node).call():
				node_stack.push_back(next_node)
			continue
		
		# dead end / end of this branch
		node_stack.pop_back()
