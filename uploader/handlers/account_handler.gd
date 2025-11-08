@tool
extends Node
class_name AccountHandler
# handles token renewal and caches player info

# in long running sessions we may need to renew our token while the game is running
# the renewal threshold determines the minimum time remaining before renewing
const TOKEN_RENEWAL_THRESHOLD:int = 60 * 60 * 24 * 7 * 3 # 3 weeks
# and the check rate determines how often we check our token expiry time
const TOKEN_RENEWAL_CHECK_RATE:int = 1800 # 30 minutes

const TOKEN_RENEW_ENDPOINT:String = "API/V0/token/"
const TOKEN_VERIFY_ENDPOINT:String = "API/V0/token/validate"
const TOKEN_USER_ENDPOINT:String = "API/V0/token/user"

var session_token:PackedByteArray = PackedByteArray()
# expiry time in seconds since epoch, -1 indicates no token or a token that never expires
var token_expiry_utc:int = -1
# tokens for temporary sessions cannot renew themselves, in that case renewal logic is disabled
var token_renewable:bool = false
var token_valid:bool = false
var persist_token:bool = true
var user_id:UUID = UUID.new()
var renew_timer:Timer = Timer.new()

@export var api_handler:APIHandler
@export var persistance_handler:PersistanceHandler

func _enter_tree() -> void:
	var saved_token:PackedByteArray = PackedByteArray()
	saved_token = persistance_handler.register_value("upload_token", "token", "token", PackedByteArray())
	var expiry:int = persistance_handler.register_value("upload_token", "token", "expiry", -1)
	var renewable:bool = persistance_handler.register_value("upload_token", "token", "renewable", false)
	if await is_token_valid(saved_token, expiry):
		token_valid = true
		set_token(saved_token, expiry, renewable)
		check_renew()

func _ready() -> void:
	renew_timer.autostart = true
	renew_timer.wait_time = TOKEN_RENEWAL_CHECK_RATE
	renew_timer.timeout.connect(check_renew)
	add_child.call_deferred(renew_timer)

func logout() -> void:
	token_valid = false
	set_token([], -1, false)

func set_token(token:PackedByteArray, expiry_utc:int, renewable:bool) -> void:
	session_token = token
	token_expiry_utc = expiry_utc
	token_renewable = renewable
	if persist_token:
		persistance_handler.set_value("upload_token", "token", "token", token)
		persistance_handler.set_value("upload_token", "token", "expiry", expiry_utc)
		persistance_handler.set_value("upload_token", "token", "renewable", renewable)
	if await is_token_valid(session_token, token_expiry_utc):
		user_id = await get_uuid(false)

func get_token_header() -> String:
	return "token: %s" % session_token

func get_uuid(use_cached_value:bool = true) -> UUID:
	if use_cached_value and user_id != UUID.new():
		return user_id
	var token_header:PackedStringArray = PackedStringArray([get_token_header()])
	var response:Array[Variant] = await api_handler.make_request(HTTPClient.METHOD_GET, TOKEN_USER_ENDPOINT, token_header)
	var result = api_handler.handle_response(response[0], response[2], [200], ["uuid"])
	var values = result[4]
	if values.is_empty():
		push_error("failed to aquire user uuid")
		if result[2] != -1:
			push_error("error code: %s" % result[2])
		if result[3] != "":
			push_error("error message: %s" % result[3])
		return UUID.new()
	return UUID.from_String(values[0])

func is_token_valid(token:PackedByteArray, expiry_utc:int) -> bool:
	if token == PackedByteArray():
		return false
	if expiry_utc != -1 and Time.get_unix_time_from_system() > expiry_utc:
		return false
	var token_header:PackedStringArray = PackedStringArray(["token: " + str(token)])
	# response = [response_code, response_headers, response_body]
	var response:Array[Variant] = await api_handler.make_request(HTTPClient.METHOD_GET, TOKEN_VERIFY_ENDPOINT, token_header)
	if response[0] == HTTPClient.RESPONSE_OK:
		return true
	elif response[0] == HTTPClient.RESPONSE_UNAUTHORIZED:
		return false
	else:
		push_warning("server error while validating token. code: ", response[0])
		return false

func check_renew() -> void:
	if token_expiry_utc < 0 or !token_renewable:
		return
	
	# indicate when token has expired
	# should only happen with non renewable tokens and a session lasting longer than the token expiry time
	if int(Time.get_unix_time_from_system()) > token_expiry_utc:
		push_error("token expired! if this is a renewable token (remember me checked when signing in) this is a bug")
		token_valid = false
		set_token([], -1, false)
	
	if int(Time.get_unix_time_from_system()) + TOKEN_RENEWAL_THRESHOLD > token_expiry_utc:
		renew_token()

func renew_token() ->  void:
	var token_header:PackedStringArray = PackedStringArray([get_token_header()])
	api_handler.make_request(HTTPClient.METHOD_GET, TOKEN_RENEW_ENDPOINT, token_header).connect(on_token_request)

func on_token_request(response_code:HTTPClient.ResponseCode, _headers:PackedStringArray, body:String) -> void:
	if response_code != HTTPClient.RESPONSE_OK:
		push_warning("server error when renewing token. code: ", response_code)
	var body_json:Dictionary = JSON.parse_string(body)
	var response_token:Array[int] = (body_json["token"] as String).hex_decode() as Array[int]
	if response_token.size() == 0:
		push_error("tried to renew token but server did not reply with one")
		return
	token_valid = true
	set_token(response_token, int(body_json["token_expiry_utc"]), true)
