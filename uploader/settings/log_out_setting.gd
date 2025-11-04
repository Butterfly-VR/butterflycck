@tool
extends HBoxContainer

const USER_INFO_ENDPOINT:String = "API/V0/user/%s"

@export var account_handler:AccountHandler
@export var api_handler:APIHandler
@export var name_label:Label

func _ready() -> void:
	if account_handler.user_id != null:
		visible = true
		var response:Array[Variant] = await api_handler.make_request(
				HTTPClient.METHOD_GET, 
				USER_INFO_ENDPOINT % (await account_handler.get_uuid()).to_string(), 
				PackedStringArray([account_handler.get_token_header()]))
		var result:Array[Variant] = api_handler.handle_response(
				response[0], 
				response[2], 
				[200], 
				["username"])
		var values:Array[Variant] = result[4]
		name_label.text = values[0]


func _on_button_pressed() -> void:
	name_label.text = ""
	account_handler.logout()
	visible = false
