@tool
extends CCKAction
## Toggles or sets the [code]enabled[/code] or [code]active[/code] property of
## the parent node, if it has one.
class_name EnableAction

## Determines which property name is targeted by this action.
enum TargetProperties {
	## Targets the parent node's [code]enabled[/code] property.
	Enable,
	## Targets the parent node's [code]active[/code] property.
	Active,
}

## If false, toggles the current value of the target property. If true, uses
## the first parameter to set the property instead; does nothing if that
## parameter is not a bool.
@export var take_parameter: bool
## Determines which property name will be targeted. See [enum TargetProperties].
@export var target_property: TargetProperties


func get_action_info() -> Dictionary[String, Variant]:
	var values: Dictionary[String, Variant] = { }

	values["take_parameter"] = take_parameter
	values["target_property"] = target_property as int

	return values


func get_action_version_string() -> String:
	return "1"


func get_action_name() -> String:
	return "EnableAction_%s" % name


func check_parent_properties() -> bool:
	var properties: Array[Dictionary] = get_parent().get_property_list()

	for property: Dictionary[String, Variant] in properties:
		if property["name"] == "enabled" or property["name"] == "active":
			return true
	return false


func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings: Array[BaseRoot.Warning] = get_universal_warnings()

	if !check_parent_properties():
		warnings.append(BaseRoot.Warning.new(
				BaseRoot.Warning.WarningLevel.Warning,
				"EnableAction parent missing property",
				"The parent of an EnableAction marker has no \"enabled\" or \
						\"active\" property for the marker to toggle.",
				get_parent(),
				false,
			))

	return warnings
