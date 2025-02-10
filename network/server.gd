extends Node


const SEND_DELAY = 0.2
var players: Dictionary = {}
var serv: TCPServer
var stream: StreamPeerTCP
var started = false
var turn = 0

func say(s: String):
	print_rich("[color=cyan]" + s + "[/color]")

## Start server
func start(port: int, address: String = "127.0.0.1"):
	serv = TCPServer.new()
	if address == "localhost":
		return serv.listen(port) == OK
	return serv.listen(port, address) == OK

## Check server
func is_running():
	return serv.is_listening()

## Stop server
func stop():
	for player in players.values():
		player.ws.close()
		while player.ws.get_ready_state() != WebSocketPeer.STATE_CLOSED:
			await get_tree().create_timer(0.1).timeout
	players.clear()
	serv.stop()

## Check if all players are ready
func all_ready():
	if players.size() < 2:
		return false
	for player in players.values():
		if player.ready == false:
			return false
	return true

# Init game variables and broadcast
func game_start():
	started = true
	turn = -1
	var cylinder = [1,0,0,0,0,0]
	cylinder.shuffle()
	for player: Player in players.values():
		player.alive = true
	var next_id = next()
	broadcast({"command": "start"})
	sendi(
		next_id,
		{
			"command": "turn", 
			"id": next_id, 
			"cylinder": cylinder
		}
	)
	#broadcast({"command": "turn", "id": players.keys()[turn], "cylinder": cylinder})

## Clear game variables and broadcast
func game_stop():
	started = false
	for player: Player in players.values():
		player.ready = false
	broadcast({"command": "stop"})

## Advance turn and get next player id
func next() -> int:
	turn = 0 if turn + 1 >= players.size() else turn + 1
	return players.keys()[turn]

func last_alive():
	var res_id = -1
	var count = 0
	for id in players.keys():
		if players[id].alive:
			res_id = id
			count += 1
	say("not yet" if res_id < 0 else "%d is the last player alive" % res_id)
	return res_id if count == 1 else -1

func _process(_delta: float) -> void:
	# accept new connections
	if serv != null and serv.is_listening() and not started:
		accept_connection()
	# poll players
	for id in players.keys():
		var ws = players[id].ws
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
			players[id] = Player.new(ws)
			while ws.get_ready_state() != WebSocketPeer.STATE_OPEN:
				await get_tree().create_timer(0.2).timeout
			send(ws, {"command": "join", "id": id})
			broadcast({"command": "players", "players": players.keys()})
			say("> %d" % id)

## Send message to a player
func send(ws: WebSocketPeer, command: Dictionary):
	ws.put_var(command)
	await get_tree().create_timer(SEND_DELAY).timeout

func sendi(id: int, command: Dictionary):
	players[id].ws.put_var(command)
	await get_tree().create_timer(SEND_DELAY).timeout

## Send message to all players
func broadcast(command: Dictionary):
	for player: Player in players.values():
		#player.ws.poll()
		if player.ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			player.ws.put_var(command)
	await get_tree().create_timer(SEND_DELAY).timeout


func handle_message(id: int, message: Dictionary):
	if message["command"] == "ready":
		players[id].ready = true
		if all_ready():
			game_start()
	elif message["command"] == "lose":
		players[id].alive = false
		if last_alive() < 0:
			var next_id = next()
			sendi(
				next_id,
				{
					"command": "turn", 
					"id": next_id, 
					"cylinder": message["cylinder"]
				}
			)
		else:
			var alive_id = last_alive()
			sendi(alive_id, {"command": "winner"})
			game_stop()
	elif message["command"] == "pass":
		var next_id = next()
		sendi(
			next_id,
			{
				"command": "turn", 
				"id": next_id, 
				"cylinder": message["cylinder"]
			}
		)
	elif message["command"] == "players":
		broadcast({"command": "players", "players": players.keys()})
	else:
		say("Unknown command: %s" % message["command"])
