#tool
extends Control

onready var canvas := get_parent()

#func _physics_process(delta):
#	if !canvas.selection.empty():
#		visible = true
#		update()
#	else:
#		visible = false
#



func _draw():
#	return
	
	var bar_width := 2.0
	var col = Color.white
	var offset: float =  wrapf(OS.get_ticks_msec() / 1000.0, 0.0, 1.0) * bar_width * 2.0
	var selection_rect = canvas.selection_rect
	draw_rect(selection_rect, Color.black, false)


func _on_SelectionHandler_visibility_changed():
	visible = !visible
