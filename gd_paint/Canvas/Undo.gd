tool
extends Button


func _gdpaint_input(event):
#	return
	if event is InputEventKey:
		if event.scancode == KEY_Z and event.pressed and event.control and !event.shift and !event.echo:
			emit_signal("pressed")
