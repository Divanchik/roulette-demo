extends CanvasLayer

func _ready() -> void:
	Client.game_start.connect(on_game_start)

func _on_disconnect_button_pressed() -> void:
	if Client.is_open():
		Client.leave()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _on_ready_button_pressed() -> void:
	var command = {
		"type": "command",
		"command": "ready"
	}
	Client.send_command(command)

func on_game_start():
	$Hub.hide()
