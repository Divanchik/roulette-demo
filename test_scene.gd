extends CanvasLayer

var mag = [0, 0, 0, 0, 0, 0]

func _ready() -> void:
	pass

func _on_roll_button_pressed() -> void:
	mag = [0, 0, 0, 0, 0, 0]
	mag[randi_range(0, 5)] = 1
	print(mag)


func _on_trigger_button_pressed() -> void:
	mag.push_front(mag.pop_back())
	print(mag)
	if mag.front() == 1:
		$VBoxContainer/ResultLabel.text = "Проиграл"
	else:
		$VBoxContainer/ResultLabel.text = "Еще раз?"
