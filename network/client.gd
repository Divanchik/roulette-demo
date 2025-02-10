extends Node

const SEND_DELAY = 0.2
signal game_start
signal game_stop
signal my_turn(cylinder)
signal got_players(players)

var id = -1
var ws = WebSocketPeer.new()
var log_closed = false

func _process(_delta: float) -> void:
	ws.poll()
	var state = ws.get_ready_state()
	if state == WebSocketPeer.STATE_OPEN:
		while ws.get_available_packet_count() > 0:
			handle_message(ws.get_var())
	elif state == WebSocketPeer.STATE_CLOSED and log_closed:
		log_closed = false
		var code = ws.get_close_code()
		say("Disconnected, %s" % ["clean" if code == 1 else "not clean"])

func say(s: String):
	print_rich("[color=orange]" + s + "[/color]")

func handle_message(message: Dictionary):
	if message["command"] == "start":
		game_start.emit()
	elif message["command"] == "stop":
		game_stop.emit()
	elif message["command"] == "join":
		id = message["id"]
	elif message["command"] == "turn" and message["id"] == id:
		my_turn.emit(message["cylinder"])
	elif message["command"] == "players":
		got_players.emit(message["players"])
	elif message["command"] == "winner":
		say("Лежать плюс сосать!")

func is_open():
	return ws.get_ready_state() == WebSocketPeer.STATE_OPEN

func join(url: String) -> bool:
	ws = WebSocketPeer.new()
	var err = ws.connect_to_url(url)
	if err != OK:
		return false
	else:
		log_closed = true
		return true

func leave():
	ws.close()

func send(command: Dictionary) -> bool:
	var err = ws.put_var(command)
	if err != OK:
		return false
	else:
		return true
	await get_tree().create_timer(SEND_DELAY).timeout
