extends Node

signal game_start

var ws = WebSocketPeer.new()
var log_closed = false

func _process(_delta: float) -> void:
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count():
			print("Packet: ", ws.get_packet())
	elif state == WebSocketPeer.STATE_CLOSING:
		pass
	elif state == WebSocketPeer.STATE_CLOSED and log_closed:
		log_closed = false
		var code = ws.get_close_code()
		var reason = ws.get_close_reason()
		print("WebSocket closed with code: %d, reason %s. Clean: %s" % [code, reason, code != -1])

func is_open():
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		return true
	return false

func join(url: String) -> bool:
	var err = ws.connect_to_url(url)
	if err != OK:
		return false
	else:
		log_closed = true
		return true

func leave():
	ws.close()

func send_command(comm: Dictionary) -> bool:
	var err = ws.send_text(JSON.stringify(comm))
	if err != OK:
		return false
	else:
		return true
