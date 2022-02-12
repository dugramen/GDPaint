tool
extends Button

func gui_input(event):
	if event is InputEventKey:
		if event.scancode == KEY_Z and event.pressed and event.control and event.shift and !event.echo:
			emit_signal("pressed")
