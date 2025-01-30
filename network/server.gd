extends Node


var peers: Array[WebSocketPeer] = []
var serv = TCPServer.new()
var stream: StreamPeerTCP


func _ready() -> void:
	serv.listen(5000)

func _process(_delta: float) -> void:
	# accept new connections
	stream = serv.take_connection()
	if stream != null and stream.get_status() == StreamPeerTCP.STATUS_CONNECTED:
		var ws = WebSocketPeer.new()
		var err = ws.accept_stream(stream)
		if err == OK:
			peers.append(ws)
			print("> ", ws.get_connected_host(), ":", ws.get_connected_port())
		else:
			print("Error while accepting stream: ", err)
	# poll websocket
	for peer in peers:
		peer.poll()
		var state = peer.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			while peer.get_available_packet_count() > 0:
				var command: Dictionary = JSON.parse_string(peer.get_packet().get_string_from_utf8())
				if command.has("type"):
					print("Got protocol")
		elif state == WebSocketPeer.STATE_CLOSED:
			peers.erase(peer)
