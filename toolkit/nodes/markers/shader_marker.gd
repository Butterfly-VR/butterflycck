@tool
extends CCKMarker
class_name ShaderMarker
## allows you to apply custom shaders. 
##
## Currently shader preprocessing is not allowed. Must be a child of the target node.

@export var shader:Shader
@export_enum("None") var material_path:String
@export var surface_idx:int = 0

func _validate_property(property: Dictionary) -> void:
	if property.name == "material_path" and get_parent():
		var result:String = ""
		
		for property_values in get_parent().get_property_list():
			if (property_values.class_name as String) == "Mesh":
				result += get_parent().name + "/" + (property_values.name as String) + ","
				continue

		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		property.hint_string = result.trim_suffix(",") if !result.is_empty() else "None"

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()
	
	var found_property:bool = false
	
	if get_parent():
		for property in get_parent().get_property_list():
			if material_path.contains("/") and property.name == material_path.split("/")[1]:
				found_property = true
				var mesh:Mesh = get_parent()[property.name]
				
				if mesh.get_surface_count() <= surface_idx:
					warnings.append(
						BaseRoot
						.Warning
						.new(
							BaseRoot.Warning.WarningLevel.Error,
							"Surface index out of bounds",
							"This ShaderMarker targets a surface on a mesh of it's parnet, \
									but the specified surface does not exist.",
							self,
							false,
						)
					)
				
				break
	
	if !found_property:
		warnings.append(
			BaseRoot
			.Warning
			.new(
				BaseRoot.Warning.WarningLevel.Error,
				"ShaderMarker has no Mesh target",
				"Check you have selected a valid Mesh property from the ShaderMarker's parent.",
				self,
				false,
			)
		)
	
	return warnings


func prep_for_upload() -> bool:
	var values: Dictionary[String, Variant] = { }
	var parent: Node = get_parent()
	parent.remove_child(self)

	values["version"] = get_marker_version_string()
	
	var shader_code:String = shader.code
	
	var ranges:Array[Vector2i]
	var current_range:Vector2i = Vector2i(0, 0)
	var inside_preprocessing:bool = false
	
	for idx:int in range(shader_code.length()):
		var c:String = shader_code[idx]
		
		if c == "#" and !inside_preprocessing:
			inside_preprocessing = true
			current_range.x = idx
			continue
		
		if c == "\n" and inside_preprocessing:
			inside_preprocessing = false
			current_range.y = idx
			ranges.push_back(current_range)
	
	while ranges.size() > 0:
		var range:Vector2i = ranges.pop_back()
		shader_code = shader_code.substr(0, range.x) + shader_code.substr(range.y)
	
	shader_code = "#pragma disable_preprocessor\n" + shader_code
	
	values["shader_code"] = shader_code
	values["surface_idx"] = surface_idx
	values["target_property"] = material_path.split("/")[1]

	parent.set_meta("ShaderMarker", values)

	queue_free()

	return true


func get_marker_version_string() -> String:
	return "1"
