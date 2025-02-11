extends CanvasLayer


var shuffled = false
var cylinder = [1, 0, 0, 0, 0, 0]
@onready var players_container: VBoxContainer = $ScrollContainer/PlayersContainer
@onready var debug: CanvasLayer = $DebugOverlay
const MAIN = preload("res://components/main.theme")
@onready var anim = $ColtPython/AnimationPlayer


func _ready() -> void:
	cylinder.shuffle()
	Client.game_start.connect(on_game_start)
	Client.game_stop.connect(on_game_stop)
	Client.my_turn.connect(on_my_turn)
	Client.got_players.connect(on_got_players)
	#Client.leave_game.connect(_on_disconnect_button_pressed)
	Client.send({"command": "players"})


func _on_disconnect_button_pressed() -> void:
	if Client.is_open():
		Client.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_ready_button_pressed() -> void:
	Client.send({"command": "ready"})


func on_game_start():
	debug.put("Game started!")
	$Hub.hide()


func on_game_stop():
	debug.put("Game ended!")
	$Hub.show()


func on_got_players(players: Array):
	for ch in players_container.get_children():
		ch.queue_free()
	for player in players:
		var btn = Button.new()
		btn.text = str(player)
		btn.disabled = true
		btn.theme = MAIN
		players_container.add_child(btn)


func on_my_turn(last_cylinder: Array):
	debug.put("My turn: " + str(last_cylinder))
	await get_tree().create_timer(0.5).timeout
	$StatusLabel.text = "My turn"
	anim.play("cock")
	cylinder.clear()
	cylinder.append_array(last_cylinder)
	shuffled = false
	$HBoxContainer/ShuffleButton.disabled = false
	$HBoxContainer/TriggerButton.disabled = false


func _on_shuffle_button_pressed() -> void:
	$HBoxContainer/ShuffleButton.disabled = true
	cylinder.shuffle()
	anim.play("shuffle")


func _on_trigger_button_pressed() -> void:
	$HBoxContainer/ShuffleButton.disabled = true
	$HBoxContainer/TriggerButton.disabled = true
	cylinder.push_front(cylinder.pop_back())
	anim.play("shot")
	if cylinder.front() == 1:
		debug.put("Boom!")
		$Sounds/GunshotSound.play()
		Client.send({"command": "lose", "cylinder": cylinder})
	else:
		debug.put("Click...")
		$Sounds/TriggerSound.play()
		Client.send({"command": "pass", "cylinder": cylinder})


func _on_return_button_pressed() -> void:
	Server.stop()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
