extends CanvasLayer


var shuffled = false
var cylinder = [1, 0, 0, 0, 0, 0]


func _ready() -> void:
	cylinder.shuffle()
	Client.game_start.connect(on_game_start)
	Client.my_turn.connect(on_my_turn)


func _on_disconnect_button_pressed() -> void:
	if Client.is_open():
		Client.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_ready_button_pressed() -> void:
	Client.send({"command": "ready"})


func on_game_start():
	$Hub.hide()


func on_my_turn(last_cylinder: Array):
	await get_tree().create_timer(1.0).timeout
	$StatusLabel.text = "My turn"
	$Sounds/CockSound.play()
	cylinder.clear()
	cylinder.append_array(last_cylinder)
	shuffled = false
	$HBoxContainer/ShuffleButton.disabled = false
	$HBoxContainer/TriggerButton.disabled = false


func _on_shuffle_button_pressed() -> void:
	$HBoxContainer/ShuffleButton.disabled = true
	cylinder.shuffle()
	$Sounds/ShuffleSound.play()

func _on_trigger_button_pressed() -> void:
	cylinder.push_front(cylinder.pop_back())
	if cylinder.front() == 1:
		$StatusLabel.text = "Boom!"
		$Sounds/GunshotSound.play()
		Client.send({"command": "lose", "cylinder": cylinder})
		await get_tree().create_timer(1.0).timeout
		Client.leave()
		$HBoxContainer.hide()
		$ReturnButton.show()
	else:
		$StatusLabel.text = "Click..."
		$Sounds/TriggerSound.play()
		Client.send({"command": "pass", "cylinder": cylinder})


func _on_return_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
