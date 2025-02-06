extends CanvasLayer


@onready var message_container: VBoxContainer = $ScrollContainer/MessageContainer
const DEBUG_OVERLAY = preload("res://components/debug_overlay.theme")


func put(message: String):
	var lbl = Label.new()
	lbl.text = message
	lbl.theme = DEBUG_OVERLAY
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	message_container.add_child(lbl)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_debug_overlay"):
		visible = not visible
