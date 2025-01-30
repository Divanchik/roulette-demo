extends CanvasLayer

var is_loading = false


func _physics_process(_delta: float) -> void:
	if is_loading:
		$LoadingIcon.rotation_degrees += 10


func _on_join_button_pressed() -> void:
	$TitleContainer.hide()
	$JoinContainer.show()


func _on_host_button_pressed() -> void:
	$TitleContainer.hide()
	$HostContainer.show()


func _on_options_button_pressed() -> void:
	pass # Replace with function body.


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_join_address_button_pressed() -> void:
	$JoinContainer.hide()
	if len($JoinContainer/JoinAddress.text) == 0:
		$AcceptDialog.dialog_text = "Неверный адрес"
		$AcceptDialog.show()
		$TitleContainer.show()
		return
	var success = Client.join($JoinContainer/JoinAddress.text)
	$LoadingIcon.show()
	is_loading = true
	await get_tree().create_timer(2).timeout
	$LoadingIcon.hide()
	is_loading = false
	if success and Client.is_open():
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	else:
		$AcceptDialog.dialog_text = "Не удалось подключиться к игре"
		$AcceptDialog.show()
		$TitleContainer.show()


func _on_host_address_button_pressed() -> void:
	pass # Replace with function body.
