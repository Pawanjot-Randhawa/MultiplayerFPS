extends Node
@onready var http: HTTPRequest = $HTTPRequest
@onready var screenshot_timer: Timer = $ScreenshotTimer
var images: Array[Image] = []

var packedIMG:PackedByteArray 

var post_url:String = "http://127.0.0.1:8000/image/upload"
var get_url:String = "http://127.0.0.1:8000/flag"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("anticheat online")
	http.request_completed.connect(_on_request_completed)
	screenshot_timer.stop()


func _unhandled_input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("test_key"):
		if screenshot_timer.is_stopped():
			screenshot_timer.start()
		else:
			screenshot_timer.stop()

func _on_request_completed(result, response_code, headers, body):
	print("Response Code: ", response_code)
	var json = JSON.parse_string(body.get_string_from_utf8())
	print(json["flag"])


func _on_screenshot_timer_timeout() -> void:
	var img := get_viewport().get_texture().get_image()
	images.append(img)
	packedIMG = img.save_png_to_buffer().compress(FileAccess.COMPRESSION_DEFLATE)
	
	var headers := ["Content-Type: application/octet-stream"]
	var error := http.request_raw(
		post_url,
		headers,
		HTTPClient.METHOD_POST,
		packedIMG
	)
	if error != OK:
		print("An error occurred in the HTTP request: ", error)
	else:
		await http.request_completed
		screenshot_timer.start()
