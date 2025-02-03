extends Node


var players: Dictionary = {}
var serv = TCPServer.new()
var stream: StreamPeerTCP
var ready_count = 0
var started = false
var turn = 0

func _ready() -> void:
	serv.listen(5000)

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
	stream = serv.take_connection()
	if stream != null and stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var ws = WebSocketPeer.new()
		var err = ws.accept_stream(stream)
		if err == OK:
			var id = hash(ws.get_connected_host() + str(ws.get_connected_port()))
			players[id] = ws
			while ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
				ws.poll()
			ws.send_text(JSON.stringify({"command": "join", "id": id}))
			print("> ", id)
			print("Total ", players.size(), " players")
		else:
			print("Error while accepting stream: ", err)

func broadcast(comm: Dictionary):
	for ws: WebSocketPeer in players.values():
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(JSON.stringify(comm))

#func send(ws: WebSocketPeer, comm: Dictionary) -> bool:
	#var err = ws.send_text(JSON.stringify(comm))
	#if err != OK:
		#return false
	#else:
		#return true

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
