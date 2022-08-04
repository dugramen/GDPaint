tool
extends HBoxContainer

signal layer_dragged(source, destination)


func can_drop_data(position, data):
	
	return data is Control and data.is_in_group("TableLayer")


func drop_data(position, data):
	var adjust := 0
	if position.y >= rect_size.y / 2.0:
		adjust = 1
#	print("dropped layer")
	emit_signal("layer_dragged", data.get_index(), get_index() + adjust)
#	get_parent().move_child(data, get_index())


func get_drag_data(position):
	set_drag_preview(duplicate())
	return self
