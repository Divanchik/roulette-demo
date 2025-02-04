extends Node

signal game_start
signal my_turn(cylinder)

var id = -1
var ws = WebSocketPeer.new()
var log_closed = false

func _process(_delta: float) -> void:
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			var command: Dictionary = JSON.parse_string(ws.get_packet().get_string_from_utf8())
			handle_message(command)
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED and log_closed:
		log_closed = false
		var code = ws.get_close_code()
		var reason = ws.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])

func handle_message(message: Dictionary):
	print(">>> ", JSON.stringify(message))
	if message["command"] == "start":
		game_start.emit()
	elif message["command"] == "join":
		id = message["id"]
	elif message["command"] == "turn" and message["id"] == id:
		my_turn.emit(message["cylinder"])

func is_open():
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		return true
	return false

func join(url: String) -> bool:
	print("Joining [", url, "]...")
	ws = WebSocketPeer.new()
	var err = ws.connect_to_url(url)
	if err != OK:
		printerr("Join error: ", err)
		return false
	else:
		print("Join success")
		log_closed = true
		return true

func leave():
	ws.close()

func send(comm: Dictionary) -> bool:
	var err = ws.send_text(JSON.stringify(comm))
	if err != OK:
		return false
	else:
		return true
