extends Object
class_name Player

var ws: WebSocketPeer
var ready: bool
var alive: bool

func _init(websocket) -> void:
	ws = websocket
	ready = false
	alive = true
