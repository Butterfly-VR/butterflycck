@tool
extends CCKMarker
class_name ShaderMarker
## allows you to apply custom shaders. 
## Currently shader preprocessing is not allowed. Must be a child of the target node.

@export var shader:ShaderMaterial
@export_enum("None") var material_path:String

func _validate_property(property: Dictionary) -> void:
	if property.name == "material_path" and get_parent():
		property.hint = PropertyHint.PROPERTY_HINT_ENUM

		var result:String = recusive_property_search(get_parent())

		property.hint_string = result.trim_suffix(",") if !result.is_empty() else "None"

static func recusive_property_search(root:Object) -> String:
	var result:String = ""
	for property_values in root.get_property_list():
		if property_values.name == "owner":
			continue
		if (property_values.class_name as String) == "ShaderMaterial":
			result += (property_values.name as String) + ","
			continue
		if property_values.type == Variant.Type.TYPE_ARRAY:
			for item in root[property_values.name]:
				if item is ShaderMaterial:
					result += (property_values.name as String) + ","
				elif item is Object:
					if root[property_values.name]:
						result += recusive_property_search(root[property_values.name])
		if property_values.type == Variant.Type.TYPE_OBJECT:
			if root[property_values.name]:
				result += recusive_property_search(root[property_values.name])
	return result

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	return warnings


func prep_for_upload() -> bool:
	var values: Dictionary[String, Variant] = { }
	var parent: Node = get_parent()
	parent.remove_child(self)

	values["version"] = get_marker_version_string()
	
	var shader_code:String = shader.shader.code
	
	var ranges:Array[Vector2i]
	var current_range:Vector2i = Vector2i(0, shader_code.length() + 1)
	
	for idx:int in range(shader_code):
		var c:String = shader_code[idx]
		
		if c == "\n" and current_range.y < shader_code.length():
			current_range.y = idx
			ranges.push_back(current_range)
			current_range = Vector2i(0, shader_code.length() + 1)
		
		if c == "#" and current_range.y > shader_code.length():
			current_range = Vector2i(idx, 0)
	
	while ranges.size() > 0:
		var range:Vector2i = ranges.pop_back()
		shader_code = shader_code.substr(0, range.x) + shader_code.substr(range.y)
	
	shader_code = "#pragma disable_preprocessor\n" + shader_code
	
	shader.shader = null
	values["material"] = shader
	values["shader_code"] = shader_code
	values["target_property"] = material_path

	parent.set_meta("ShaderMarker", values)

	queue_free()

	return true


func get_marker_version_string() -> String:
	return "1"
