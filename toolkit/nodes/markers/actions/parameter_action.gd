@tool
extends CCKAction
## When triggered, sets the specified parameter of the target [AnimationTree]
## to the value of the event's first parameter.
class_name ParameterAction

## The target [AnimationTree].
@export var target: AnimationTree:
	set(x):
		target = x
		notify_property_list_changed()
## The [AnimationTree] parameter to set the value of, chosen from the
## parameters exposed by the target [AnimationTree]. Does nothing if the
## types do not match.
@export_enum(" ") var parameter: String


func _validate_property(property: Dictionary) -> void:
	if property.name == "parameter" and target:
		property.hint = PropertyHint.PROPERTY_HINT_ENUM

		var result: String = ""
		for property_values in target.get_property_list():
			if !(property_values.name as String).begins_with("parameters/"):
				continue
			if (property_values.name as String).ends_with("playback"):
				continue
			result += (property_values.name as String).trim_prefix("parameters/") + ","

		property.hint_string = result.trim_suffix(",") if !result.is_empty() else " "


func get_action_info() -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = { }

	values["target"] = get_parent().get_path_to(target)
	values["parameter"] = parameter

	return values


func get_action_version_string() -> String:
	return "1"


func get_action_name() -> String:
	return "ParameterAction_%s" % name


func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	if !target:
		warnings.append(BaseRoot.Warning.new(
				BaseRoot.Warning.WarningLevel.Error,
				"ParameterAction target not set",
				"A ParameterAction must target a AnimationTree to control the parameter of.",
				self,
				false,
			))
	if parameter.is_empty() or parameter == " ":
		warnings.append(BaseRoot.Warning.new(
				BaseRoot.Warning.WarningLevel.Error,
				"ParameterAction parameter not set",
				"A specific parameter must be chosen for this action to control.",
				self,
				false,
			))

	return warnings
