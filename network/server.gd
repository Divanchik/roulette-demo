extends Node


var players: Dictionary = {}
var serv = TCPServer.new()
var stream: StreamPeerTCP
var ready_count = 0
var started = false
var turn = 0

func _ready() -> void:
	Performance.add_custom_monitor("Network/Players", get_players_count)

func get_players_count():
	return players.size()

func start(port: int, address: String = "127.0.0.1"):
	if address == "localhost":
		return serv.listen(port) == OK
	return serv.listen(port, address) == OK


func _process(_delta: float) -> void:
	# accept new connections
	if not started:
		accept_connection()
	# poll players
	for id in players.keys():
		var ws = players[id]
		ws.poll()
		var state = ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				var command: Dictionary = JSON.parse_string(ws.get_packet().get_string_from_utf8())
				handle_message(id, command)
		elif state == WebSocketPeer.STATE_CLOSED:
			players.erase(id)
			print("< ", id)


func accept_connection():
	if not serv.is_listening():
		return
	stream = serv.take_connection()
	if stream != null and stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var ws = WebSocketPeer.new()
		var err = ws.accept_stream(stream)
		if err == OK:
			var id = hash(ws.get_connected_host() + str(ws.get_connected_port()))
			players[id] = ws
			while ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
				await get_tree().create_timer(1.0).timeout
				ws.poll()
			ws.send_text(JSON.stringify({"command": "join", "id": id}))
			print("> %d (%s:%d)" % [id, ws.get_connected_host(), ws.get_connected_port()])
			print("Total ", players.size(), " players")
		else:
			print("Error while accepting stream: ", err)


func broadcast(comm: Dictionary):
	for ws: WebSocketPeer in players.values():
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(JSON.stringify(comm))


func handle_message(id: int, message: Dictionary):
	if message["command"] == "ready":
		ready_count += 1
		if ready_count == players.size():
			started = true
			broadcast({"command": "start"})
	elif message["command"] == "lose":
		players[id].close()
		if players.size() == 0:
			return
		turn = 0 if turn + 1 >= players.size() else turn + 1
		broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": message["cylinder"]})
	elif message["command"] == "pass":
		turn = 0 if turn + 1 >= players.size() else turn + 1
		broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": message["cylinder"]})
	else:
		print("Unknown command: ", message["command"])
