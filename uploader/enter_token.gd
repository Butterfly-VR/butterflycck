@tool
extends VBoxContainer

const SIGNIN_ENDPOINT:String = "/api/v0/token"

## WARNING: changing the constants in this region could stop all users from signing in
#region DANGER
# since the salt for the client side hash must be something the client knows,
# we use the email as the unique part of the hash, but since emails are often reused,
# we append this application specific value to the salt to ensure different platforms,
# have different salts for the same user.
const PASSWORD_SALT_CONST_HALF:String = "6uplNKoY38xV81Cl"
# argon2 parameters
const MEMORY:int = 512
const ITERATIONS:int = 1
const PARALLELISM:int = 4
const OUTPUT_LENGTH:int = 64
#endregion

@export var email_entry:LineEdit
@export var password_entry:LineEdit
@export var account_handler:EditorAccountHandler
@export var api_handler:EditorAPIHandler
@export var page_selector:EditorPageSelector
@export var button:Button

func _on_token_entered() -> void:
	button.disabled = true
	
	await get_tree().physics_frame
	
	var email:String = email_entry.text
	var password:String = password_entry.text
	
	## WARNING: changing this code could prevent users from logging in
	var client_salt:String = PASSWORD_SALT_CONST_HALF + email
	var password_hash:PackedByteArray = Argon2Hasher.hash(MEMORY, ITERATIONS, PARALLELISM, password, client_salt, OUTPUT_LENGTH)
	
	
	var body:String = JSON.stringify({"email": email, "password_hash": password_hash as Array[int], "allow_renew": true})
	api_handler.make_request(HTTPClient.METHOD_POST, SIGNIN_ENDPOINT, PackedStringArray(), body).connect(on_login_response)

func on_login_response(code:HTTPClient.ResponseCode, _headers:PackedStringArray, body:String) -> void:
	button.disabled = false
	
	var result:Array = api_handler.handle_response(code, body, [HTTPClient.RESPONSE_OK], [
			"token",
			"token_expires",
			"renewable"
			])
	if result[0]:
		var data:Dictionary = result[4]
		var token:Array[int] = []
		token.assign(data["token"])
		account_handler.set_token(
				token,
				data["token_expires"],
				data["renewable"]
				)
		page_selector.leave_token_entry()
	else:
		var response_code:int = result[1]
		var error_code:String = result[2]
		var error_message:String = result[3]
		push_error("Failed to log in.")
		if response_code != -1:
			push_error("Response code: %s" % (response_code))
		if error_code != "":
			push_error("Error code: %s" % (error_code))
		if error_message != "":
			push_error("Error message: \n%s" % (error_message))
