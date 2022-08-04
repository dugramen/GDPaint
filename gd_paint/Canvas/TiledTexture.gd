tool
extends TextureRect

#func _input(event):
#
	
func refresh(icon := get_parent().get_image() ):
	rect_size = icon.get_size()
	rect_position = Vector2()
	visible = false
	if get_parent().Tiled_mode_h.pressed:
		rect_position.x -= rect_size.x
		rect_size.x *= 3
		visible = true
	if get_parent().Tiled_mode_v.pressed:
		rect_position.y -= rect_size.y
		rect_size.y *= 3
		visible = true


func _on_TextureRect_draw():
	refresh()
	pass # Replace with function body.


func _on_TileH_pressed():
	refresh()
	pass # Replace with function body.


func _on_TileV_pressed():
	refresh()
	pass # Replace with function body.
