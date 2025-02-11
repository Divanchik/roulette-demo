extends CanvasLayer
var addr_temp = RegEx.create_from_string(r"localhost:\d{4,5}|\d{,3}\.\d{,3}\.\d{,3}\.\d{,3}:\d{4,5}")


func alert(title: String, text: String):
	$AcceptDialog.title = title
	$AcceptDialog.dialog_text = text
	$AcceptDialog.show()


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


func join_url(url: String):
	var err = Client.join(url)
	$AnimationPlayer.play("loading")
	await $AnimationPlayer.animation_finished
	if err == OK and Client.is_open():
		get_tree().change_scene_to_file("res://scenes/game/game.tscn")
	elif err == ERR_CANT_CONNECT:
		alert("Ошибка", "Не удалось подключиться к игре")
	elif err == ERR_CONNECTION_ERROR:
		alert("Ошибка", "Ошибка подключения")
	elif err == ERR_CANT_RESOLVE or err == OK:
		alert("Ошибка", "Неверный адрес подключения")
	else:
		alert("Ошибка", "Номер ошибки: %d" % err)


func _on_join_address_button_pressed() -> void:
	$JoinContainer.hide()
	await join_url($JoinContainer/JoinAddress.text)
	$TitleContainer.show()


func _on_host_address_button_pressed() -> void:
	$HostContainer.hide()
	var tmp = addr_temp.search($HostContainer/HostAddress.text)
	if tmp.get_start() < 0:
		alert("Ошибка", "Неверный адрес!")
		$TitleContainer.show()
		return
	var addr = $HostContainer/HostAddress.text.split(":")
	if not Server.start(int(addr[1]), addr[0]):
		$AcceptDialog.dialog_text = "Не удалось запустить сервер"
		$AcceptDialog.show()
		$TitleContainer.show()
		return
	await join_url($HostContainer/HostAddress.text)
	$TitleContainer.show()


func _on_return_button_pressed() -> void:
	$JoinContainer.hide()
	$HostContainer.hide()
	$TitleContainer.show()


func _on_credits_0_pressed() -> void:
	OS.shell_open("https://hyqqm.itch.io/gameready-colt-python-revolver")


func _on_credits_1_pressed() -> void:
	OS.shell_open("https://lospec.com/palette-list/oil-6")
