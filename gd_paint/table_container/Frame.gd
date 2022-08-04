tool
extends TextureRect

signal frame_dragged(source, destination)


func can_drop_data(position, data):
	
	return data is Control and data.is_in_group("TableFrame")


func drop_data(position, data):
	var adjust := 0
	if position.x >= rect_size.x / 2.0:
		adjust = 1
	emit_signal("frame_dragged", data.get_index(), get_index() + adjust)
#	get_parent().move_child(data, get_index())


func get_drag_data(position):
	set_drag_preview(duplicate())
	return self

