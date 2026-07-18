@tool
extends CCKAction
class_name TransitionAction

@export var target:CCKAnimationTree
@export_enum(" ") var state_machine:String
@export_enum(" ") var transition:String
@export var transition_type:TransitionTypes
@export var teleport_if_unreachable:bool = false

enum TransitionTypes{
	single_transition,
	travel,
	instant
}

func _validate_property(property: Dictionary) -> void:
	if property.name == "state_machine" and target:
		property.hint = PropertyHint.PROPERTY_HINT_ENUM
		property.hint_string = target.get_concatenated_sate_machine_paths()

func get_action_info() -> Dictionary[String, Variant]:
	var values:Dictionary[String, Variant] = {}
	
	
	
	return values

func get_action_version_string() -> String:
	return "1"

func get_action_name() -> String:
	return "TransitionAction_%s" % name

func get_uploader_warnings() -> Array[BaseRoot.Warning]:
	var warnings:Array[BaseRoot.Warning] = get_universal_warnings()
	
	
	
	return warnings
