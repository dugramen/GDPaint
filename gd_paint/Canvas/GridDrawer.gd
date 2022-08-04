tool
extends Control

onready var canvas := get_parent()


func _draw():
	var rect = canvas.get_image_rect()
	var minimum_grid_visible := 4.0
	var grid_color := Color(1,1,1,.25)
	
	var xgrid = [rect.position.x, rect.end.x]
	var ygrid = [rect.position.y, rect.end.y]
	
	var grid_size = canvas.grid_size
	if canvas.Grid_enabled.pressed:
		if grid_size.x * rect_scale.x >= minimum_grid_visible:
			xgrid += range(rect.position.x, 1+rect.end.x, grid_size.x)
		if grid_size.y * rect_scale.y >= minimum_grid_visible:
			ygrid += range(rect.position.y, 1+rect.end.y, grid_size.y)
	
	for i in xgrid:
		draw_line(Vector2(i, rect.position.y), Vector2(i, rect.end.y), grid_color, 1.0)
	for i in ygrid:
		draw_line(Vector2(rect.position.x, i), Vector2(rect.end.x, i), grid_color, 1.0)
