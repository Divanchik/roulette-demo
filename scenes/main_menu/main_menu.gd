extends CanvasLayer
var addr_temp = RegEx.create_from_string(r"localhost:\d{4,5}|\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}:\d{4,5}")

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
	var tmp = addr_temp.search($JoinContainer/JoinAddress.text)
	if tmp.get_start() < 0:
		$AcceptDialog.dialog_text = "Неверный адрес"
		$AcceptDialog.show()
		$TitleContainer.show()
		return
	var success = Client.join($JoinContainer/JoinAddress.text)
	$AnimationPlayer.play("loading")
	await $AnimationPlayer.animation_finished
	if success and Client.is_open():
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	else:
		$AcceptDialog.dialog_text = "Не удалось подключиться к игре"
		$AcceptDialog.show()
		$TitleContainer.show()


func _on_host_address_button_pressed() -> void:
	$HostContainer.hide()
	var tmp = addr_temp.search($HostContainer/HostAddress.text)
	if tmp.get_start() < 0:
		$AcceptDialog.dialog_text = "Неверный адрес"
		$AcceptDialog.show()
		$TitleContainer.show()
		return
	var addr = $HostContainer/HostAddress.text.split(":")
	if not Server.start(int(addr[1]), addr[0]):
		$AcceptDialog.dialog_text = "Не удалось запустить сервер"
		$AcceptDialog.show()
		$TitleContainer.show()
		return
	var success = Client.join($HostContainer/HostAddress.text)
	$AnimationPlayer.play("loading")
	await $AnimationPlayer.animation_finished
	if success and Client.is_open():
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	else:
		$AcceptDialog.dialog_text = "Не удалось подключиться к игре"
		$AcceptDialog.show()
		$TitleContainer.show()


func _on_return_button_pressed() -> void:
	$JoinContainer.hide()
	$HostContainer.hide()
	$TitleContainer.show()


func _on_credits_0_pressed() -> void:
	OS.shell_open("https://hyqqm.itch.io/gameready-colt-python-revolver")


func _on_credits_1_pressed() -> void:
	OS.shell_open("https://lospec.com/palette-list/oil-6")
