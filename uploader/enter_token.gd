extends VBoxContainer

const TOKEN_VERIFY_ENDPOINT:String = "API/V0/token/validate"

@export var token_entry:LineEdit
@export var account_handler:AccountHandler
@export var page_selector:PageSelector

func _on_token_entered() -> void:
	var token:String = token_entry.text
	if token.is_valid_hex_number():
		var token_bytes:PackedByteArray = PackedByteArray()
		for idx:int in range(0, token.length(), 2):
			token_bytes.push_back(token.substr(idx, 2).hex_to_int())
		if await account_handler.is_token_valid(token_bytes, -1):
			account_handler.set_token(token_bytes, -1, true)
			account_handler.renew_token()
			page_selector.leave_token_entry()
			return
	token_entry.text = ""
