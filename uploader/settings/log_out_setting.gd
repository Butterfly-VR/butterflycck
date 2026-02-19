@tool
extends HBoxContainer

const USER_INFO_ENDPOINT:String = "/api/v0/user/%s"

@export var account_handler:AccountHandler
@export var api_handler:APIHandler
@export var name_label:Label
@export var page_selector:PageSelector

func _process(delta: float) -> void:
	if !is_visible_in_tree():
		return
	if account_handler.get_token_header() == "token: []":
		return
	if name_label.text != "":
		return
	
	var response:Array[Variant] = await api_handler.make_request(
			HTTPClient.METHOD_GET, 
			USER_INFO_ENDPOINT % (await account_handler.get_uuid()).to_string(), 
			PackedStringArray([account_handler.get_token_header()]))
	var result:Array[Variant] = api_handler.handle_response(
			response[0], 
			response[2], 
			[200], 
			["username"])
	var values:Dictionary[String, Variant] = result[4]
	name_label.text = values["username"]


func _on_button_pressed() -> void:
	name_label.text = ""
	account_handler.logout()
	page_selector.enter_token_entry()
