tool
extends TextureRect

#func _physics_process(delta):
#	update()


func gui_input(event):
	if event is InputEventMouse:
#		var mouse_pos = get_global_mouse_position()-get_parent().rect_global_position
#		rect_position = mouse_pos
#		rect_global_position = (get_global_mouse_position() - Vector2.ONE*4).floor()
		rect_position = (get_global_mouse_position() - get_parent().rect_global_position) / get_parent().rect_scale
		rect_position = rect_position.floor()

#func _draw():
#	if texture != null:
#		return
#
#	draw_rect(Rect2(Vector2(), Vector2.ONE), Color.white, false)
