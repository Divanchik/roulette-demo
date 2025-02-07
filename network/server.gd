extends Node


var players: Dictionary = {}
var serv = TCPServer.new()
var stream: StreamPeerTCP
var ready_players: Dictionary = {}
var started = false
var turn = 0

func _ready() -> void:
	pass
	#Performance.add_custom_monitor("Network/Players", get_players_count)

#func get_players_count():
	#return players.size()

func say(s: String):
	print_rich("[color=cyan]" + s + "[/color]")

func start(port: int, address: String = "127.0.0.1"):
	if address == "localhost":
		return serv.listen(port) == OK
	return serv.listen(port, address) == OK

func is_running():
	return serv.is_listening()

func stop():
	for id in players.keys():
		players[id].close()
		while players[id].get_ready_state() != WebSocketPeer.STATE_CLOSED:
			await get_tree().create_timer(0.1).timeout
	players.clear()
	serv.stop()

func restart_game():
	ready_players.clear()
	turn = 0
	started = false
	broadcast({"command": "restart"})

func _process(_delta: float) -> void:
	# accept new connections
	if serv.is_listening() and not started:
		accept_connection()
	# poll players
	for id in players.keys():
		var ws = players[id]
		ws.poll()
		var state = ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while ws.get_available_packet_count() > 0:
				handle_message(id, ws.get_var())
		elif state == WebSocketPeer.STATE_CLOSED:
			players.erase(id)
			broadcast({"command": "players", "players": players.keys()})
			say("< %d" % id)


func accept_connection():
	stream = serv.take_connection()
	if stream != null and stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var ws = WebSocketPeer.new()
		if ws.accept_stream(stream) == OK:
			var id = hash(ws.get_connected_host() + str(ws.get_connected_port()))
			players[id] = ws
			while ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
				await get_tree().create_timer(1.0).timeout
			send(ws, {"command": "join", "id": id})
			broadcast({"command": "players", "players": players.keys()})
			say("> %d" % id)


func send(ws: WebSocketPeer, command: Dictionary):
	ws.put_var(command)
	await get_tree().create_timer(0.5).timeout


func broadcast(command: Dictionary):
	for ws: WebSocketPeer in players.values():
		ws.poll()
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.put_var(command)
	await get_tree().create_timer(0.5).timeout


func handle_message(id: int, message: Dictionary):
	if message["command"] == "ready":
		ready_players[id] = true
		if ready_players.has_all(players.keys()):
			started = true
			broadcast({"command": "start"})
			broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": [1,0,0,0,0,0]})
	elif message["command"] == "lose":
		players[id].close()
		if players.size() == 0:
			return
		turn = 0 if turn + 1 >= players.size() else turn + 1
		broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": message["cylinder"]})
	elif message["command"] == "pass":
		turn = 0 if turn + 1 >= players.size() else turn + 1
		broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": message["cylinder"]})
	elif message["command"] == "players":
		broadcast({"command": "players", "players": players.keys()})
	else:
		say("Unknown command: %s" % message["command"])
