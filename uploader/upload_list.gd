@tool
extends VBoxContainer

const SEARCH_ENDPOINT:String = "/api/v0/search/%s"
const OBJECT_INFO_ENDPOINT:String = "/api/v0/%s/%s"
const OBJECT_DELETE_ENDPOINT:String = "/api/v0/%s/%s/delete"

@export var api_handler:EditorAPIHandler
@export var account_handler:EditorAccountHandler
@export var popup:Control
@export var popup_object_name_label:Label
@export var confirm_button:Button
@export var cancel_button:Button

func _on_visibility_changed() -> void:
	if is_visible_in_tree():
		var search:String = "&is:world,creator:%s" % (await account_handler.get_uuid()).to_string()
		
		var response:Array[Variant] = await api_handler.make_request(
				HTTPClient.METHOD_GET, 
				SEARCH_ENDPOINT % search, 
				PackedStringArray([account_handler.get_token_header()]))
		
		@warning_ignore("unsafe_call_argument")
		var result:Array[Variant] = api_handler.handle_response(
				response[0], response[2], [200], ["worlds"])
		if !result[0]:
			var error_msg:Label = Label.new()
			error_msg.text = "error while retriving worlds, please try again"
			add_child(error_msg)
			push_error("error while retriving worlds")
			if result[1] != -1:
				push_error("server response: %s" % result[1])
			if result[2] != "":
				push_error("error code: %s" % result[2])
			if result[3] != "":
				push_error("error message: %s" % result[3])
			return
		
		var object_list:Array[Dictionary] = []
		
		for world_untyped:Dictionary in result[4]["worlds"]:
			var world:Dictionary[String, Variant] = {}
			world.assign(world_untyped)
			
			response = await api_handler.make_request(
					HTTPClient.METHOD_GET, OBJECT_INFO_ENDPOINT % ["World", world["id"]], 
					PackedStringArray([account_handler.get_token_header()]))
			@warning_ignore("unsafe_call_argument")
			result = api_handler.handle_response(response[0], response[2], [200], 
					["id", "name", "description", "created_at", "creator", "publicity", "tags"])
			
			if !result[0]:
				push_error("error when getting world details")
				if result[1] != -1:
					push_error("server response: %s" % result[1])
				if result[2] != "":
					push_error("error code: %s" % result[2])
				if result[3] != "":
					push_error("error message: %s" % result[3])
				continue
			
			result[4]["type_string"] = "World"
			
			object_list.push_back(result[4])
		
		search = "&is:avatar,creator:%s" % (await account_handler.get_uuid()).to_string()
		
		response = await api_handler.make_request(
				HTTPClient.METHOD_GET, 
				SEARCH_ENDPOINT % search, 
				PackedStringArray([account_handler.get_token_header()]))
		
		@warning_ignore("unsafe_call_argument")
		result = api_handler.handle_response(
				response[0], response[2], [200], ["avatars"])
		if !result[0]:
			var error_msg:Label = Label.new()
			error_msg.text = "error while retriving avatars, please try again"
			add_child(error_msg)
			push_error("error while retriving avatars")
			if result[1] != -1:
				push_error("server response: %s" % result[1])
			if result[2] != "":
				push_error("error code: %s" % result[2])
			if result[3] != "":
				push_error("error message: %s" % result[3])
			return
		
		for avatar_untyped:Dictionary in result[4]["avatars"]:
			var avatar:Dictionary[String, Variant] = {}
			avatar.assign(avatar_untyped)
			
			response = await api_handler.make_request(
					HTTPClient.METHOD_GET, OBJECT_INFO_ENDPOINT % ["Avatar", avatar["id"]], 
					PackedStringArray([account_handler.get_token_header()]))
			@warning_ignore("unsafe_call_argument")
			result = api_handler.handle_response(response[0], response[2], [200], 
					["id", "name", "description", "created_at", "creator", "publicity", "tags"])
			
			if !result[0]:
				push_error("error when getting avatar details")
				if result[1] != -1:
					push_error("server response: %s" % result[1])
				if result[2] != "":
					push_error("error code: %s" % result[2])
				if result[3] != "":
					push_error("error message: %s" % result[3])
				continue
			
			result[4]["type_string"] = "Avatar"
			
			object_list.push_back(result[4])
		
		for child:Node in get_children():
			child.queue_free()
		await get_tree().physics_frame
		
		for object:Dictionary in object_list:
			var listing:EditorUploadedObjectListing = preload(
					"res://addons/butterflycck/uploader/object_listing.tscn").instantiate()
			
			var publicity:String = ""
			
			match object["publicity"] as int:
				0:
					publicity = "Private"
				1:
					publicity = "Friends"
				2:
					publicity = "Unlisted"
				3:
					publicity = "Public"
				_:
					publicity = "UNNAMED"
			
			var creation_time = "Created at: " + \
					Time.get_date_string_from_unix_time(object["created_at"] as int)
			
			var button:Button = listing.setup_and_get_button(
					object["id"], object["name"], publicity, creation_time)
			button.pressed.connect(on_delete.bind(UUID.from_String(object["id"]), object["name"], object["type_string"]))
			
			add_child(listing)

func on_delete(id:UUID, object_name:String, object_type_string:String) -> void:
	popup_object_name_label.text = object_name
	
	for conn:Dictionary in confirm_button.pressed.get_connections():
		confirm_button.pressed.disconnect(conn["callable"])
	confirm_button.pressed.connect(on_confirm.bind(id, object_type_string))
	
	popup.visible = true

func on_confirm(id:UUID, type_string:String) -> void:
	confirm_button.disabled = true
	cancel_button.disabled = true
	
	var response:Array[Variant] = await api_handler.make_request(
			HTTPClient.METHOD_GET, OBJECT_DELETE_ENDPOINT % [type_string, id.to_string()], 
			PackedStringArray([account_handler.get_token_header()]))
	@warning_ignore("unsafe_call_argument")
	var result:Array[Variant] = api_handler.handle_response(response[0], response[2], [200], [])
	
	if !result[0]:
		push_error("error while deleting object")
		if result[1] != -1:
			push_error("server response: %s" % result[1])
		if result[2] != "":
			push_error("error code: %s" % result[2])
		if result[3] != "":
			push_error("error message: %s" % result[3])
	else:
		print("deleted %s" % id.to_string())
	
	popup.visible = false
	confirm_button.disabled = false
	cancel_button.disabled = false
	_on_visibility_changed()

func _on_cancel() -> void:
	popup.visible = false
