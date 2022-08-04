tool
extends ColorRect

var start_pos := Vector2()

func _ready():
	for child in get_children():
		child.connect("gui_input", self, "anchor_input", [child])
#		child.color = color


func anchor_input(event: InputEvent, child: Control):
	if event is InputEventMouseMotion and event.button_mask == BUTTON_MASK_LEFT:
#		start_pos = event.position
		child.rect_position = get_local_mouse_position()
		
		var dir = Vector2(child.anchor_left, child.anchor_top) * 2 - Vector2.ONE
		var r := [int(dir.x < 0), int(dir.y < 0), int(dir.x > 0), int(dir.y > 0)]
		print(r)
		var relative: Vector2 = event.relative
		r[0] *= relative.x
		r[1] *= relative.y
		r[2] *= relative.x
		r[3] *= relative.y
		
		
		get_parent().rect_position += Vector2(r[0],r[1])
		get_parent().rect_size += Vector2(r[2], r[3]) - Vector2(r[0],r[1])
		
#		get_parent().margin_left += r[0]
#		get_parent().margin_top += r[1]
#		get_parent().margin_right += r[2]
#		get_parent().margin_bottom += r[3]
		
		
#		var rect := Rect2()
#		for child in get_children():
#			rect = rect.expand(child.rect_position)
#		rect_position = rect.position
#		rect_size = rect.size
#		print("expanded")
